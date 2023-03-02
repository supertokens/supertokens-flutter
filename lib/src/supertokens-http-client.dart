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

import 'constants.dart';

/// An [http.BaseClient] implementation for using SuperTokens for your network requests.
/// To make use of supertokens, use this as the client for making network calls instead of [http.Client] or your own custom clients.
/// If you use a custom client for your network calls pass an instance of it as a paramter when initialising [Client], pass [http.Client()] to use the default.
ReadWriteMutex _refreshAPILock = ReadWriteMutex();

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
    if (Client.cookieStore == null) {
      Client.cookieStore = SuperTokensCookieStore();
    }

    if (!SuperTokens.isInitCalled) {
      throw http.ClientException(
          "SuperTokens.initialise must be called before using Client");
    }

    if (SuperTokensUtils.getApiDomain(request.url.toString()) !=
        SuperTokens.config.apiDomain) {
      return _innerClient.send(request);
    }

    if (SuperTokensUtils.getApiDomain(request.url.toString()) ==
        SuperTokens.refreshTokenUrl) {
      return _innerClient.send(request);
    }

    if (!Utils.shouldDoInterceptions(
        request.url.toString(),
        SuperTokens.config.apiDomain,
        SuperTokens.config.sessionTokenBackendDomain)) {
      return _innerClient.send(request);
    }

    try {
      while (true) {
        await _refreshAPILock.acquireRead();
        // http package does not allow retries with the same request object, so we clone the request when making the network call
        http.BaseRequest copiedRequest;
        LocalSessionState preRequestLocalSessionState;
        http.StreamedResponse response;
        try {
          copiedRequest = SuperTokensUtils.copyRequest(request);
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
              SuperTokens.config.tokenTransferMethod!;
          copiedRequest.headers["st-auth-mode"] =
              tokenTransferMethod == SuperTokensTokenTransferMethod.COOKIE
                  ? "cookie"
                  : "header";

          // Adding Authorization headers
          copiedRequest =
              await Utils.setAuthorizationHeaderIfRequired(copiedRequest);

          // Add cookies to request headers
          String? newCookiesToAdd = await Client.cookieStore
              ?.getCookieHeaderStringForRequest(copiedRequest.url);
          String? existingCookieHeader =
              copiedRequest.headers[HttpHeaders.cookieHeader];

          // If the request already has a "cookie" header, combine it with persistent cookies
          if (existingCookieHeader != null) {
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
          request = await _removeAuthHeaderIfMatchesLocalToken(copiedRequest);
          UnauthorisedResponse shouldRetry =
              await onUnauthorisedResponse(preRequestLocalSessionState);
          if (shouldRetry.status == UnauthorisedStatus.RETRY) {
            // Here we use the original request because it wont contain any of the modifications we make
            return await send(request);
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
    } finally {
      LocalSessionState localSessionState =
          await SuperTokensUtils.getLocalSessionState();
      if (localSessionState.status == LocalSessionStateStatus.NOT_EXISTS) {
        await AntiCSRF.removeToken();
        await FrontToken.removeToken();
      }
    }
  }

  Future<http.BaseRequest> _removeAuthHeaderIfMatchesLocalToken(
      http.BaseRequest mutableRequest) async {
    if (mutableRequest.headers.containsKey("Authorization")) {
      String authValue = mutableRequest.headers["Authorization"]!;
      String? accessToken = await Utils.getTokenForHeaderAuth(TokenType.ACCESS);

      if (accessToken != null && authValue == "Bearer $accessToken") {
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
      refreshReq.headers.addAll({'st-auth-mode': 'cookie'});
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
      LocalSessionState localSessionState =
          await SuperTokensUtils.getLocalSessionState();

      if (localSessionState.status == LocalSessionStateStatus.NOT_EXISTS) {
        await FrontToken.removeToken();
        await AntiCSRF.removeToken();
      }

      _refreshAPILock.release();
    }
  }

  static Future clearTokensIfRequired() async {
    LocalSessionState preRequestLocalSessionState =
        await SuperTokensUtils.getLocalSessionState();
    if (preRequestLocalSessionState.status ==
        LocalSessionStateStatus.NOT_EXISTS) {
      await AntiCSRF.removeToken();
      await FrontToken.removeToken();
    }
  }

  static Map<String, dynamic> _generateMapFromCookie(String cookie) {
    if (cookie.isEmpty) return {};
    List<String> entries = cookie.split(";");
    Map<String, dynamic> map = {};
    entries.forEach((element) {
      List<String> keyValuePair = element.split("=");
      if (keyValuePair.length == 2) {
        map[keyValuePair[0]] = keyValuePair[1];
      }
    });
    return map;
  }

  static String _generateCookieHeader(String? oldCookie, String? newCookie) {
    Map<String, dynamic> existingCookieHeaderMap =
        _generateMapFromCookie(oldCookie ?? "");
    Map<String, dynamic> newCookiesToAddMap =
        _generateMapFromCookie(newCookie ?? "");
    String finalCookieHeader = "";
    existingCookieHeaderMap.keys.forEach((element) {
      if (newCookiesToAddMap.containsKey(element)) {
        finalCookieHeader += "$element=${newCookiesToAddMap[element]};";
      } else {
        finalCookieHeader += "$element=${existingCookieHeaderMap[element]};";
      }
    });
    return "${finalCookieHeader}HttpOnly;";
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
