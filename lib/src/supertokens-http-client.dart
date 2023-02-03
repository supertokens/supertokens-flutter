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

    if (!Utils.shouldDoInterceptions(request.url.toString(),
        SuperTokens.config.apiDomain, SuperTokens.config.cookieDomain)) {
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
          preRequestLocalSessionState =
              await SuperTokensUtils.getLocalSessionState();
          String? antiCSRFToken = await AntiCSRF.getToken(
              preRequestLocalSessionState.lastAccessTokenUpdate);

          if (antiCSRFToken != null) {
            copiedRequest.headers[antiCSRFHeaderKey] = antiCSRFToken;
          }

          // Add cookies to request headers
          String? newCookiesToAdd = await Client.cookieStore
              ?.getCookieHeaderStringForRequest(copiedRequest.url);
          String? existingCookieHeader =
              copiedRequest.headers[HttpHeaders.cookieHeader];

          // If the request already has a "cookie" header, combine it with persistent cookies
          if (existingCookieHeader != null) {
            copiedRequest.headers[HttpHeaders.cookieHeader] =
                "$existingCookieHeader;${newCookiesToAdd ?? ""}";
          } else {
            copiedRequest.headers[HttpHeaders.cookieHeader] = newCookiesToAdd ?? "";
          }

          copiedRequest.headers.addAll({'st-auth-mode': 'cookie'});

          // http package does not allow retries with the same request object, so we clone the request when making the network call
          response =
              await _innerClient.send(copiedRequest);
          await saveTokensFromHeaders(response);
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
          await Client.cookieStore
              ?.saveFromSetCookieHeader(copiedRequest.url, setCookieFromResponse);
        } finally {
          _refreshAPILock.release();
        }

        if (response.statusCode == SuperTokens.sessionExpiryStatusCode) {
          UnauthorisedResponse shouldRetry =
              await onUnauthorisedResponse(preRequestLocalSessionState);
          if (shouldRetry.status == UnauthorisedStatus.RETRY) {
            
            // Here we use the original request because it wont contain any of the modifications we make
            send(request);
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
      await saveTokensFromHeaders(resp);
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

  static Future<void> saveTokensFromHeaders(
      http.StreamedResponse response) async {
    String? frontTokenFromResponse = response.headers[frontTokenHeaderKey];
    if (frontTokenFromResponse != null) {
      await FrontToken.setItem(frontTokenFromResponse);
    }

    String? antiCSRFFromResponse = response.headers[antiCSRFHeaderKey];
    if (antiCSRFFromResponse != null) {
      LocalSessionState localSessionState =
          await SuperTokensUtils.getLocalSessionState();
      await AntiCSRF.setToken(
        antiCSRFFromResponse,
        localSessionState.lastAccessTokenUpdate,
      );
    }
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
