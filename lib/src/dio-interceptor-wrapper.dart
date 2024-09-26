import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mutex/mutex.dart';
import 'package:supertokens_flutter/src/anti-csrf.dart';
import 'package:supertokens_flutter/src/constants.dart';
import 'package:supertokens_flutter/src/cookie-store.dart';
import 'package:supertokens_flutter/src/errors.dart';
import 'package:supertokens_flutter/src/front-token.dart';
import 'package:supertokens_flutter/src/supertokens-http-client.dart';
import 'package:supertokens_flutter/src/supertokens.dart';
import 'package:supertokens_flutter/src/utilities.dart';
import 'package:supertokens_flutter/src/logger.dart';

class SuperTokensInterceptorWrapper extends Interceptor {
  ReadWriteMutex _refreshAPILock = ReadWriteMutex();
  final Dio client;
  late dynamic userSetCookie;
  late LocalSessionState _preRequestLocalSessionState;

  SuperTokensInterceptorWrapper({required this.client});

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    logDebugMessage('Intercepting request call')
    if (!SuperTokens.isInitCalled) {
      handler.reject(DioException(
        requestOptions: options,
        type: DioExceptionType.unknown,
        error: SuperTokensException(
            "SuperTokens.init must be called before using Client"),
      ));
      return;
    }

    if (!shouldRunDioInterceptor(options)) {
      logDebugMessage('Skipping dio interceptor')
      return super.onRequest(options, handler);
    }

    logDebugMessage('Running dio interceptor')
    if (Client.cookieStore == null) {
      logDebugMessage('Initializing cookie store')
      Client.cookieStore = SuperTokensCookieStore();
    }

    options = await _removeAuthHeaderIfMatchesLocalToken(options);

    _preRequestLocalSessionState =
        await SuperTokensUtils.getLocalSessionState();
    String? antiCSRFToken = await AntiCSRF.getToken(
        _preRequestLocalSessionState.lastAccessTokenUpdate);

    if (antiCSRFToken != null) {
      options.headers[antiCSRFHeaderKey] = antiCSRFToken;
    }

    SuperTokensTokenTransferMethod tokenTransferMethod =
        SuperTokens.config.tokenTransferMethod;
    options.headers["st-auth-mode"] = tokenTransferMethod.getValue();

    options = await _setAuthorizationHeaderIfRequired(options);

    userSetCookie = options.headers[HttpHeaders.cookieHeader];

    String uriForCookieString = options.uri.toString();
    if (!uriForCookieString.endsWith("/")) {
      uriForCookieString += "/";
    }

    String? newCookiesToAdd = await Client.cookieStore
        ?.getCookieHeaderStringForRequest(Uri.parse(uriForCookieString));
    String? existingCookieHeader = options.headers[HttpHeaders.cookieHeader];

    // If the request already has a "cookie" header, combine it with persistent cookies
    if (existingCookieHeader != null) {
      logDebugMessage('Combining cookie header values')
      options.headers[HttpHeaders.cookieHeader] =
          "$existingCookieHeader;${newCookiesToAdd ?? ""}";
    } else {
      options.headers[HttpHeaders.cookieHeader] = newCookiesToAdd ?? "";
    }

    var oldValidate = options.validateStatus;
    options.validateStatus = (status) {
      if (status != null &&
          status == SuperTokens.config.sessionExpiredStatusCode) {
        return true;
      }
      return oldValidate(status);
    };

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    logDebugMessage('Intercepting response call')
    if (!shouldRunDioInterceptor(response.requestOptions)) {
      logDebugMessage('Skipping dio interceptor')
      return handler.next(response);
    }

    logDebugMessage('Running dio interceptor')
    _refreshAPILock.acquireWrite();
    await saveTokensFromHeaders(response);
    String? frontTokenFromResponse =
        response.headers.map[frontTokenHeaderKey]?.first.toString();
    SuperTokensUtils.fireSessionUpdateEventsIfNecessary(
      wasLoggedIn:
          _preRequestLocalSessionState.status == LocalSessionStateStatus.EXISTS,
      status: response.statusCode!,
      frontTokenFromResponse: frontTokenFromResponse,
    );
    List<dynamic>? setCookieFromResponse =
        response.headers.map[HttpHeaders.setCookieHeader];
    setCookieFromResponse?.forEach((element) async {
      await Client.cookieStore
          ?.saveFromSetCookieHeader(response.realUri, element);
    });

    try {
      if (response.statusCode == SuperTokens.sessionExpiryStatusCode) {
        /**
         * An API may return a 401 error response even with a valid session, causing a session refresh loop in the interceptor.
         * To prevent this infinite loop, we break out of the loop after retrying the original request a specified number of times.
         * The maximum number of retry attempts is defined by maxRetryAttemptsForSessionRefresh config variable.
         */
        RequestOptions requestOptions = response.requestOptions;
        int sessionRefreshAttempts =
            requestOptions.extra["__supertokensSessionRefreshAttempts"] ?? 0;
        if (sessionRefreshAttempts >=
            SuperTokens.config.maxRetryAttemptsForSessionRefresh) {
          logDebugMessage('Max attempts of ${SuperTokens.config.maxRetryAttemptsForSessionRefresh} reached for refreshing, cannot continue')
          handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              type: DioExceptionType.unknown,
              error: SuperTokensException(
                  "Received a 401 response from ${response.requestOptions.uri}. Attempted to refresh the session and retry the request with the updated session tokens ${SuperTokens.config.maxRetryAttemptsForSessionRefresh} times, but each attempt resulted in a 401 error. The maximum session refresh limit has been reached. Please investigate your API. To increase the session refresh attempts, update maxRetryAttemptsForSessionRefresh in the config."),
            ),
          );
          _refreshAPILock.release();
          return;
        }

        requestOptions =
            await _removeAuthHeaderIfMatchesLocalToken(requestOptions);
        UnauthorisedResponse shouldRetry =
            await Client.onUnauthorisedResponse(_preRequestLocalSessionState);
        if (shouldRetry.status == UnauthorisedStatus.RETRY) {
          logDebugMessage('Refreshing attempt: ${sessionRefreshAttempts + 1}')
          requestOptions.headers[HttpHeaders.cookieHeader] = userSetCookie;

          requestOptions.extra["__supertokensSessionRefreshAttempts"] =
              sessionRefreshAttempts + 1;

          Response<dynamic> res = await client.fetch(requestOptions);
          List<dynamic>? setCookieFromResponse =
              res.headers.map[HttpHeaders.setCookieHeader];
          setCookieFromResponse?.forEach((element) async {
            await Client.cookieStore
                ?.saveFromSetCookieHeader(res.realUri, element);
          });
          await saveTokensFromHeaders(res);
          return handler.next(res);
        } else {
          if (shouldRetry.exception != null) {
            handler.reject(
              DioException(
                  requestOptions: response.requestOptions,
                  error: SuperTokensException(shouldRetry.exception!.message),
                  type: DioExceptionType.unknown),
            );
            return;
          } else {
            _refreshAPILock.release();
            return handler.next(response);
          }
        }
      } else {
        _refreshAPILock.release();
        return handler.next(response);
      }
    } on DioException catch (e) {
      handler.reject(e);
    } catch (e) {
      handler.reject(
        DioException(
            requestOptions: response.requestOptions,
            type: DioExceptionType.unknown,
            error: e),
      );
    }
  }

  Future<void> saveTokensFromHeaders(Response response) async {
    String? frontTokenFromResponse =
        response.headers.map[frontTokenHeaderKey]?.first.toString();

    if (frontTokenFromResponse != null) {
      await FrontToken.setItem(frontTokenFromResponse);
    }

    String? antiCSRFFromResponse =
        response.headers.map[antiCSRFHeaderKey]?.first.toString();

    if (antiCSRFFromResponse != null) {
      LocalSessionState localSessionState =
          await SuperTokensUtils.getLocalSessionState();

      await AntiCSRF.setToken(
        antiCSRFFromResponse,
        localSessionState.lastAccessTokenUpdate,
      );
    }

    String? accessHeader =
        response.headers.map[ACCESS_TOKEN_NAME]?.first.toString();

    if (accessHeader != null) {
      await Utils.setToken(TokenType.ACCESS, accessHeader);
    }
    String? refreshHeader =
        response.headers.map[REFRESH_TOKEN_NAME]?.first.toString();

    if (refreshHeader != null) {
      await Utils.setToken(TokenType.REFRESH, refreshHeader);
    }
  }

  Future<RequestOptions> _removeAuthHeaderIfMatchesLocalToken(
      RequestOptions req) async {
    if (req.headers.containsKey("Authorization") ||
        req.headers.containsKey("authorization")) {
      String? authValue = req.headers['Authorization'];
      if (authValue == null) {
        authValue = req.headers["authorization"];
      }
      String? accessToken = await Utils.getTokenForHeaderAuth(TokenType.ACCESS);
      String? refreshToken = await Utils.getTokenForHeaderAuth(TokenType.REFRESH);

      if (accessToken != null && refreshToken != null && authValue != "Bearer $accessToken") {
        req.headers.remove('Authorization');
        req.headers.remove('authorization');
      }
    }
    return req;
  }

  static Future<RequestOptions> _setAuthorizationHeaderIfRequired(
      RequestOptions options,
      {bool addRefreshToken = false}) async {
    String? accessToken = await Utils.getTokenForHeaderAuth(TokenType.ACCESS);
    String? refreshToken = await Utils.getTokenForHeaderAuth(TokenType.REFRESH);

    if (accessToken != null && refreshToken != null) {
      if (options.headers["Authorization"] != null ||
          options.headers["authorization"] != null) {
        //  no-op
      } else {
        String tokenToAdd = addRefreshToken ? refreshToken : accessToken;
        options.headers["Authorization"] = "Bearer $tokenToAdd";
      }
    }
    return options;
  }

  bool shouldRunDioInterceptor(RequestOptions options) {
    if (SuperTokensUtils.getApiDomain(options.uri.toString()) !=
        SuperTokens.config.apiDomain) {
      return false;
    }

    if (SuperTokensUtils.getApiDomain(options.uri.toString()) ==
        SuperTokens.refreshTokenUrl) {
      return false;
    }

    if (!Utils.shouldDoInterceptions(
        options.uri.toString(),
        SuperTokens.config.apiDomain,
        SuperTokens.config.sessionTokenBackendDomain)) {
      return false;
    }

    return true;
  }
}
