import 'dart:collection';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mutex/mutex.dart';
import 'package:supertokens/src/anti-csrf.dart';
import 'package:supertokens/src/cookie-store.dart';
import 'package:supertokens/src/errors.dart';
import 'package:supertokens/src/front-token.dart';
import 'package:supertokens/src/id-refresh-token.dart';
import 'package:supertokens/src/utilities.dart';
import 'package:supertokens/src/version.dart';
import 'package:supertokens/supertokens.dart';

import 'constants.dart';

/// An [http.BaseClient] implementation for using SuperTokens for your network requests.
/// To make use of supertokens, use this as the client for making network calls instead of [http.Client] or your own custom clients.
/// If you use a custom client for your network calls pass an instance of it as a paramter when initialising [SuperTokensHttpClient], pass [http.Client()] to use the default.
class SuperTokensHttpClient extends http.BaseClient {
  static SuperTokensHttpClient? _instance;
  static SuperTokensHttpClient getInstance(http.Client innerClient) {
    if (_instance == null) {
      _instance = SuperTokensHttpClient._init(innerClient);
    }

    return _instance!;
  }

  http.Client _innerClient;
  final ReadWriteMutex _refreshAPILock = ReadWriteMutex();
  SuperTokensCookieStore? _cookieStore;

  SuperTokensHttpClient._init(this._innerClient);

  // This annotation will result in a warning to anyone using this method outside of this package
  @visibleForTesting
  void setInnerClient(http.Client client) {
    this._innerClient = client;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (_cookieStore == null) {
      _cookieStore = SuperTokensCookieStore();
    }

    if (!SuperTokens.isInitCalled) {
      throw http.ClientException(
          "SuperTokens.initialise must be called before using SuperTokensHttpClient");
    }

    if (SuperTokensUtils.getApiDomain(request.url.toString()) !=
        SuperTokens.config.apiDomain) {
      return _innerClient.send(request);
    }

    if (SuperTokensUtils.getApiDomain(request.url.toString()) ==
        SuperTokens.refreshTokenUrl) {
      return _innerClient.send(request);
    }

    try {
      while (true) {
        await _refreshAPILock.acquireRead();
        String? preRequestIdRefreshToken;
        http.StreamedResponse response;
        try {
          preRequestIdRefreshToken = await IdRefreshToken.getToken();
          String? antiCSRFToken =
              await AntiCSRF.getToken(preRequestIdRefreshToken);

          if (antiCSRFToken != null) {
            request.headers[antiCSRFHeaderKey] = antiCSRFToken;
          }

          // Add cookies to request headers
          String? newCookiesToAdd =
              await _cookieStore?.getCookieHeaderStringForRequest(request.url);
          String? existingCookieHeader =
              request.headers[HttpHeaders.cookieHeader];

          // If the request already has a "cookie" header, combine it with persistent cookies
          if (existingCookieHeader != null) {
            request.headers[HttpHeaders.cookieHeader] =
                "$existingCookieHeader;${newCookiesToAdd ?? ""}";
          } else {
            request.headers[HttpHeaders.cookieHeader] = newCookiesToAdd ?? "";
          }

          // http package does not allow retries with the same request object, so we clone the request when making the network call
          response =
              await _innerClient.send(SuperTokensUtils.copyRequest(request));

          // Save cookies from the response
          String? setCookieFromResponse =
              response.headers[HttpHeaders.setCookieHeader];
          await _cookieStore?.saveFromSetCookieHeader(
              request.url, setCookieFromResponse);

          String? idRefreshTokenFromResponse =
              response.headers[idRefreshHeaderKey];
          if (idRefreshTokenFromResponse != null) {
            await IdRefreshToken.setToken(idRefreshTokenFromResponse);
          }
        } finally {
          _refreshAPILock.release();
        }

        if (response.statusCode == SuperTokens.sessionExpiryStatusCode) {
          UnauthorisedResponse shouldRetry =
              await onUnauthorisedResponse(preRequestIdRefreshToken);
          if (shouldRetry.status == UnauthorisedStatus.RETRY) {
            send(request);
          } else {
            if (IdRefreshToken.getToken() == null) {
              AntiCSRF.removeToken();
              FrontToken.removeToken();
            }
            if (shouldRetry.exception != null) {
              var respObject = await http.Response.fromStream(response);
              var data = respObject.body;
            }
          }
        } else {
          String? antiCSRFFromResponse = response.headers[antiCSRFHeaderKey];
          if (antiCSRFFromResponse != null) {
            String? postRequestIdRefresh = await IdRefreshToken.getToken();
            await AntiCSRF.setToken(
              antiCSRFFromResponse,
              postRequestIdRefresh,
            );
          }
          return response;
        }
      }
    } finally {
      String? idRefreshToken = await IdRefreshToken.getToken();
      if (idRefreshToken == null) {
        await AntiCSRF.removeToken();
        await FrontToken.removeToken();
      }
    }
  }

  // static resolveToUser(String data)

  static Future onUnauthorisedResponse(String? preRequestIdRefresh) async {
    String? postLockIdRefresh = await IdRefreshToken.getToken();
    if (postLockIdRefresh == null) {
      SuperTokens.config.eventHandler(Eventype.UNAUTHORISED);
      return UnauthorisedResponse(status: UnauthorisedStatus.SESSION_EXPIRED);
    }
    if (postLockIdRefresh != preRequestIdRefresh) {
      return UnauthorisedResponse(status: UnauthorisedStatus.RETRY);
    }
    Uri refreshUrl = Uri.parse(SuperTokens.refreshTokenUrl);
    http.Request refreshReq = http.Request('POST', refreshUrl);

    String? antiCSRFToken = await AntiCSRF.getToken(preRequestIdRefresh);
    if (antiCSRFToken != null) {
      refreshReq.headers[antiCSRFHeaderKey] = antiCSRFToken;
    }
    refreshReq.headers['rid'] = SuperTokens.rid;
    refreshReq.headers['fdi-version'] = Version.supported_fdi.join(',');
    refreshReq =
        SuperTokens.config.preAPIHook(APIAction.REFRESH_TOKEN, refreshReq);
    try {
      var resp = await refreshReq.send();
      http.Response response = await http.Response.fromStream(resp);
      Map<String, String> headerFeilds = response.headers;
      bool removeIdRefreshToken = true;
      if (headerFeilds.containsKey(idRefreshHeaderKey)) {
        IdRefreshToken.setToken(headerFeilds[idRefreshHeaderKey] as String);
        removeIdRefreshToken = false;
      }
      if (response.statusCode == SuperTokens.config.sessionExpiredStatusCode &&
          removeIdRefreshToken) {
        IdRefreshToken.setToken('remove');
      }

      if (response.statusCode >= 300) {
        return UnauthorisedResponse(
            status: UnauthorisedStatus.API_ERROR,
            error: SuperTokensException(
                "Refresh API returned with status code: ${response.statusCode}"));
      }

      SuperTokens.config
          .postAPIHook(APIAction.REFRESH_TOKEN, refreshReq, response);

      String? idRefreshToken = await IdRefreshToken.getToken();
      String? antiCSRFFromResponse = response.headers[antiCSRFHeaderKey];
      if (antiCSRFFromResponse != null) {
        AntiCSRF.setToken(antiCSRFFromResponse, idRefreshToken);
      }
      String? frontTokenFromResponse = response.headers[frontTokenHeaderKey];
      if (frontTokenFromResponse != null) {
        FrontToken.setToken(frontTokenFromResponse);
      }

      if (idRefreshToken == null) {
        AntiCSRF.removeToken();
        FrontToken.removeToken();
        return UnauthorisedResponse(status: UnauthorisedStatus.SESSION_EXPIRED);
      }

      SuperTokens.config.eventHandler(Eventype.REFRESH_SESSION);
      return UnauthorisedResponse(status: UnauthorisedStatus.RETRY);
    } catch (e) {
      return UnauthorisedResponse(status: UnauthorisedStatus.API_ERROR);
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
