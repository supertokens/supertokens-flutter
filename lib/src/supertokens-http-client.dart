import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mutex/mutex.dart';
import 'package:supertokens_flutter/src/anti-csrf.dart';
import 'package:supertokens_flutter/src/cookie-store.dart';
import 'package:supertokens_flutter/src/front-token.dart';
import 'package:supertokens_flutter/src/utilities.dart';
import 'package:supertokens_flutter/src/version.dart';
import 'package:supertokens_flutter/supertokens.dart';
import 'package:supertokens_flutter/src/logger.dart';

import 'constants.dart';

/// An [http.BaseClient] implementation for using SuperTokens for your network requests.
/// To make use of supertokens, use this as the client for making network calls instead of [http.Client] or your own custom clients.
/// If you use a custom client for your network calls pass an instance of it as a parameter when initialising [Client], pass [http.Client()] to use the default.
ReadWriteMutex _refreshAPILock = ReadWriteMutex();

class CustomRequest {
  http.BaseRequest request;
  int sessionRefreshAttempts;

  CustomRequest(this.request, this.sessionRefreshAttempts);
}

class Client extends http.BaseClient {
  Client({http.Client? client}) {
    if (client != null) {
      _innerClient = client;
    }
  }

  http.Client _innerClient = http.Client();
  http.BaseRequest? _requestForRetry;
  static SuperTokensCookieStore? cookieStore;

  // This annotation will result in a warning to anyone using this method outside of this package
  @visibleForTesting
  void setInnerClient(http.Client client) {
    this._innerClient = client;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return await _sendWithRetry(CustomRequest(request, 0));
  }

  Future<http.StreamedResponse> _sendWithRetry(
      CustomRequest customRequest) async {
    logDebugMessage('Sending request');
    if (Client.cookieStore == null) {
      Client.cookieStore = SuperTokensCookieStore();
    }

    if (!SuperTokens.isInitCalled) {
      throw http.ClientException(
          "SuperTokens.initialise must be called before using Client");
    }

    if (SuperTokensUtils.getApiDomain(customRequest.request.url.toString()) !=
        SuperTokens.config.apiDomain) {
      logDebugMessage('Not matching api domain, using inner client');
      return _innerClient.send(customRequest.request);
    }

    if (SuperTokensUtils.getApiDomain(customRequest.request.url.toString()) ==
        SuperTokens.refreshTokenUrl) {
      logDebugMessage('Refresh token URL matched');
      return _innerClient.send(customRequest.request);
    }

    if (!Utils.shouldDoInterceptions(
        customRequest.request.url.toString(),
        SuperTokens.config.apiDomain,
        SuperTokens.config.sessionTokenBackendDomain)) {
      logDebugMessage('Skipping interceptions');
      return _innerClient.send(customRequest.request);
    }

    while (true) {
      await _refreshAPILock.acquireRead();
      // http package does not allow retries with the same request object, so we clone the request when making the network call
      http.BaseRequest copiedRequest;
      LocalSessionState preRequestLocalSessionState;
      http.StreamedResponse response;
      try {
        copiedRequest = SuperTokensUtils.copyRequest(customRequest.request);
        copiedRequest =
            await _removeAuthHeaderIfMatchesLocalToken(copiedRequest);
        preRequestLocalSessionState =
            await SuperTokensUtils.getLocalSessionState();
        String? antiCSRFToken = await AntiCSRF.getToken(
            preRequestLocalSessionState.lastAccessTokenUpdate);

        if (antiCSRFToken != null) {
          copiedRequest.headers[antiCSRFHeaderKey] = antiCSRFToken;
        }

        SuperTokensTokenTransferMethod tokenTransferMethod =
            SuperTokens.config.tokenTransferMethod;
        copiedRequest.headers["st-auth-mode"] =
            tokenTransferMethod.getValue();

        // Adding Authorization headers
        copiedRequest =
            await Utils.setAuthorizationHeaderIfRequired(copiedRequest);

        // Add cookies to request headers
        String? newCookiesToAdd = await Client.cookieStore
            ?.getCookieHeaderStringForRequest(copiedRequest.url);
        String? existingCookieHeader =
            copiedRequest.headers[HttpHeaders.cookieHeader];

        // If the request already has a "cookie" header, combine it with persistent cookies
        if (existingCookieHeader != null && existingCookieHeader != "") {
          copiedRequest.headers[HttpHeaders.cookieHeader] =
              _generateCookieHeader(existingCookieHeader, newCookiesToAdd);
        } else {
          copiedRequest.headers[HttpHeaders.cookieHeader] =
              newCookiesToAdd ?? "";
        }

        // http package does not allow retries with the same request object, so we clone the request when making the network call
        response = await _innerClient.send(copiedRequest);
        await Utils.saveTokenFromHeaders(response);
        String? frontTokenInHeaders = response.headers[frontTokenHeaderKey];
        SuperTokensUtils.fireSessionUpdateEventsIfNecessary(
          wasLoggedIn: preRequestLocalSessionState.status ==
              LocalSessionStateStatus.EXISTS,
          status: response.statusCode,
          frontTokenFromResponse: frontTokenInHeaders,
        );

        // Save cookies from the response
        String? setCookieFromResponse =
            response.headers[HttpHeaders.setCookieHeader];
        await Client.cookieStore?.saveFromSetCookieHeader(
            copiedRequest.url, setCookieFromResponse);
      } finally {
        _refreshAPILock.release();
      }

      if (response.statusCode == SuperTokens.sessionExpiryStatusCode) {
        /**
          * An API may return a 401 error response even with a valid session, causing a session refresh loop in the interceptor.
          * To prevent this infinite loop, we break out of the loop after retrying the original request a specified number of times.
          * The maximum number of retry attempts is defined by maxRetryAttemptsForSessionRefresh config variable.
          */
        if (customRequest.sessionRefreshAttempts >=
            SuperTokens.config.maxRetryAttemptsForSessionRefresh) {
          logDebugMessage('Max attempts of ${SuperTokens.config.maxRetryAttemptsForSessionRefresh} reached for refreshing, cannot continue');
          throw SuperTokensException(
              "Received a 401 response from ${customRequest.request.url}. Attempted to refresh the session and retry the request with the updated session tokens ${SuperTokens.config.maxRetryAttemptsForSessionRefresh} times, but each attempt resulted in a 401 error. The maximum session refresh limit has been reached. Please investigate your API. To increase the session refresh attempts, update maxRetryAttemptsForSessionRefresh in the config.");
        }
        customRequest.sessionRefreshAttempts++;
        logDebugMessage('Refreshing attempt: ${customRequest.sessionRefreshAttempts}');

        customRequest.request =
            await _removeAuthHeaderIfMatchesLocalToken(copiedRequest);

        UnauthorisedResponse shouldRetry =
            await onUnauthorisedResponse(preRequestLocalSessionState);
        if (shouldRetry.status == UnauthorisedStatus.RETRY) {
          // Here we use the original request because it wont contain any of the modifications we make
          return await _sendWithRetry(customRequest);
        } else {
          if (shouldRetry.exception != null) {
            throw SuperTokensException(shouldRetry.exception!.message);
          } else
            return response;
        }
      } else {
        return response;
      }
    }
  }

  Future<http.BaseRequest> _removeAuthHeaderIfMatchesLocalToken(
      http.BaseRequest mutableRequest) async {
    if (mutableRequest.headers.containsKey("Authorization") ||
        mutableRequest.headers.containsKey("authorization")) {
      String? authValue = mutableRequest.headers["Authorization"];
      if (authValue == null) {
        authValue = mutableRequest.headers["authorization"];
      }
      String? accessToken = await Utils.getTokenForHeaderAuth(TokenType.ACCESS);
      String? refreshToken =
          await Utils.getTokenForHeaderAuth(TokenType.REFRESH);

      if (accessToken != null &&
          refreshToken != null &&
          authValue == "Bearer $accessToken") {
        mutableRequest.headers.remove("Authorization");
        mutableRequest.headers.remove("authorization");
      }
    }
    return mutableRequest;
  }

  static Future<UnauthorisedResponse> onUnauthorisedResponse(
      LocalSessionState preRequestLocalSessionState) async {
    try {
      await _refreshAPILock.acquireWrite();

      LocalSessionState postLockLocalSessionState =
          await SuperTokensUtils.getLocalSessionState();
      if (postLockLocalSessionState.status ==
          LocalSessionStateStatus.NOT_EXISTS) {
        SuperTokens.config.eventHandler(Eventype.UNAUTHORISED);
        return UnauthorisedResponse(status: UnauthorisedStatus.SESSION_EXPIRED);
      }
      if (postLockLocalSessionState.status !=
              preRequestLocalSessionState.status ||
          (postLockLocalSessionState.status == LocalSessionStateStatus.EXISTS &&
              preRequestLocalSessionState.status ==
                  LocalSessionStateStatus.EXISTS &&
              postLockLocalSessionState.lastAccessTokenUpdate !=
                  preRequestLocalSessionState.lastAccessTokenUpdate)) {
        return UnauthorisedResponse(status: UnauthorisedStatus.RETRY);
      }
      Uri refreshUrl = Uri.parse(SuperTokens.refreshTokenUrl);
      http.Request refreshReq = http.Request('POST', refreshUrl);
      refreshReq = await Utils.setAuthorizationHeaderIfRequiredForRequestObject(
          refreshReq,
          addRefreshToken: true);

      if (preRequestLocalSessionState.status ==
          LocalSessionStateStatus.EXISTS) {
        String? antiCSRFToken = await AntiCSRF.getToken(
            preRequestLocalSessionState.lastAccessTokenUpdate);
        if (antiCSRFToken != null) {
          refreshReq.headers[antiCSRFHeaderKey] = antiCSRFToken;
        }
      }

      refreshReq.headers['rid'] = SuperTokens.rid;
      refreshReq.headers['fdi-version'] = Version.supported_fdi.join(',');
      // Add cookies to request headers
      String? newCookiesToAdd =
          await Client.cookieStore?.getCookieHeaderStringForRequest(refreshUrl);
      refreshReq.headers[HttpHeaders.cookieHeader] = newCookiesToAdd ?? "";
      SuperTokensTokenTransferMethod tokenTransferMethod =
          SuperTokens.config.tokenTransferMethod;
      refreshReq.headers
          .addAll({'st-auth-mode': tokenTransferMethod.getValue()});
      refreshReq =
          SuperTokens.config.preAPIHook(APIAction.REFRESH_TOKEN, refreshReq);
      var resp = await refreshReq.send();
      await Utils.saveTokenFromHeaders(resp);
      http.Response response = await http.Response.fromStream(resp);

      // Save cookies from the response
      String? setCookieFromResponse =
          response.headers[HttpHeaders.setCookieHeader];
      await Client.cookieStore
          ?.saveFromSetCookieHeader(refreshReq.url, setCookieFromResponse);

      bool isUnauthorised =
          response.statusCode == SuperTokens.config.sessionExpiredStatusCode;

      String? frontTokenInHeaders = response.headers[frontTokenHeaderKey];
      if (isUnauthorised && frontTokenInHeaders == null) {
        await FrontToken.setItem("remove");
      }

      SuperTokensUtils.fireSessionUpdateEventsIfNecessary(
        wasLoggedIn: preRequestLocalSessionState.status ==
            LocalSessionStateStatus.EXISTS,
        status: response.statusCode,
        frontTokenFromResponse: frontTokenInHeaders,
      );

      if (response.statusCode >= 300) {
        return UnauthorisedResponse(
            status: UnauthorisedStatus.API_ERROR,
            error: SuperTokensException(
                "Refresh API returned with status code: ${response.statusCode}"));
      }

      SuperTokens.config
          .postAPIHook(APIAction.REFRESH_TOKEN, refreshReq, response);

      if ((await SuperTokensUtils.getLocalSessionState()).status ==
          LocalSessionStateStatus.NOT_EXISTS) {
        // The execution should never come here.. but just in case.
        // removed by server. So we logout
        // we do not send "UNAUTHORISED" event here because
        // this is a result of the refresh API returning a session expiry, which
        // means that the frontend did not know for sure that the session existed
        // in the first place.
        return UnauthorisedResponse(status: UnauthorisedStatus.SESSION_EXPIRED);
      }

      SuperTokens.config.eventHandler(Eventype.REFRESH_SESSION);
      return UnauthorisedResponse(status: UnauthorisedStatus.RETRY);
    } catch (e) {
      return UnauthorisedResponse(
          status: UnauthorisedStatus.API_ERROR,
          error: SuperTokensException("Some unknown error occured"));
    } finally {
      _refreshAPILock.release();
    }
  }

  static String _cookieMapToHeaderString(Map<String, dynamic> cookieMap) {
    return cookieMap.keys.map((e) => "$e=${cookieMap[e]}").join(";");
  }

  static String _generateCookieHeader(String oldCookie, String? newCookie) {
    if (newCookie == null) {
      return oldCookie;
    }
    List<Cookie> oldCookies =
        SuperTokensCookieStore.getCookieListFromHeader(oldCookie);
    List<Cookie> newCookies =
        SuperTokensCookieStore.getCookieListFromHeader(newCookie);
    Iterable newCookiesNames = newCookies.map((e) => e.name);
    oldCookies.removeWhere((element) => newCookiesNames.contains(element.name));
    newCookies.addAll(oldCookies);
    return newCookies.map((e) => e.toString()).join(';');
  }
}

enum UnauthorisedStatus {
  SESSION_EXPIRED,
  API_ERROR,
  RETRY,
}

class UnauthorisedResponse {
  final UnauthorisedStatus status;
  final Exception? error;
  final http.ClientException? exception;

  UnauthorisedResponse({
    required this.status,
    this.error,
    this.exception,
  });
}

Client _innerSTClient = Client();

Future<http.Response> get(Uri url, {Map<String, String>? headers}) =>
    _innerSTClient.get(url, headers: headers);

Future<http.Response> post(Uri url,
        {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    _innerSTClient.post(url, headers: headers, body: body, encoding: encoding);

Future<http.Response> put(Uri url,
        {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    _innerSTClient.put(url, headers: headers, body: body, encoding: encoding);

Future<http.Response> patch(Uri url,
        {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    _innerSTClient.patch(url, headers: headers, body: body, encoding: encoding);

Future<http.Response> delete(Uri url,
        {Map<String, String>? headers, Object? body, Encoding? encoding}) =>
    _innerSTClient.delete(url,
        headers: headers, body: body, encoding: encoding);

Future<http.StreamedResponse> send(http.BaseRequest req) =>
    _innerSTClient.send(req);
