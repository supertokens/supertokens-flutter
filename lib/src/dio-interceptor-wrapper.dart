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
    logDebugMessage('SuperTokensInterceptorWrapper.onRequest: Intercepting request call');
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
      logDebugMessage('SuperTokensInterceptorWrapper.onRequest: Skipping dio interceptor');
      return super.onRequest(options, handler);
    }

    logDebugMessage('SuperTokensInterceptorWrapper.onRequest: Running dio interceptor');
    if (Client.cookieStore == null) {
      logDebugMessage('SuperTokensInterceptorWrapper.onRequest: Initializing cookie store');
      Client.cookieStore = SuperTokensCookieStore();
    }

    logDebugMessage('SuperTokensInterceptorWrapper.onRequest: Removing auth header if it matches local token');
    options = await _removeAuthHeaderIfMatchesLocalToken(options);

    logDebugMessage('SuperTokensInterceptorWrapper.onRequest: Getting local session state');
    _preRequestLocalSessionState =
        await SuperTokensUtils.getLocalSessionState();
    String? antiCSRFToken = await AntiCSRF.getToken(
        _preRequestLocalSessionState.lastAccessTokenUpdate);

    if (antiCSRFToken != null) {
      logDebugMessage('SuperTokensInterceptorWrapper.onRequest: antiCSRFToken is not null');
      options.headers[antiCSRFHeaderKey] = antiCSRFToken;
    }

    SuperTokensTokenTransferMethod tokenTransferMethod =
        SuperTokens.config.tokenTransferMethod;
    options.headers["st-auth-mode"] = tokenTransferMethod.getValue();

    logDebugMessage('SuperTokensInterceptorWrapper.onRequest: Setting authorization header if required');
    options = await _setAuthorizationHeaderIfRequired(options);

    userSetCookie = options.headers[HttpHeaders.cookieHeader];

    String uriForCookieString = options.uri.toString();
    if (!uriForCookieString.endsWith("/")) {
      uriForCookieString += "/";
    }
    logDebugMessage('SuperTokensInterceptorWrapper.onRequest: uriForCookieString: ${uriForCookieString}');

    String? newCookiesToAdd = await Client.cookieStore
        ?.getCookieHeaderStringForRequest(Uri.parse(uriForCookieString));
    String? existingCookieHeader = options.headers[HttpHeaders.cookieHeader];

    // If the request already has a "cookie" header, combine it with persistent cookies
    if (existingCookieHeader != null) {
      logDebugMessage('SuperTokensInterceptorWrapper.onRequest: Combining cookie header values');
      options.headers[HttpHeaders.cookieHeader] =
          "$existingCookieHeader;${newCookiesToAdd ?? ""}";
    } else {
      logDebugMessage('SuperTokensInterceptorWrapper.onRequest: Adding new cookie header');
      options.headers[HttpHeaders.cookieHeader] = newCookiesToAdd ?? "";
    }

    logDebugMessage('SuperTokensInterceptorWrapper.onRequest: Injecting status check in validateStatus');
    var oldValidate = options.validateStatus;
    options.validateStatus = (status) {
      if (status != null &&
          status == SuperTokens.config.sessionExpiredStatusCode) {
        return true;
      }
      return oldValidate(status);
    };

    logDebugMessage('SuperTokensInterceptorWrapper.onRequest: Calling next on handler');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    logDebugMessage('SuperTokensInterceptorWrapper.onResponse: Intercepting response call');
    if (!shouldRunDioInterceptor(response.requestOptions)) {
      logDebugMessage('SuperTokensInterceptorWrapper.onResponse: Skipping dio interceptor');
      return handler.next(response);
    }

    logDebugMessage('SuperTokensInterceptorWrapper.onResponse: Running dio interceptor');
    _refreshAPILock.acquireWrite();
    logDebugMessage('SuperTokensInterceptorWrapper.onResponse: write acquired');
    logDebugMessage('SuperTokensInterceptorWrapper.onResponse: saving tokens from headers');
    await saveTokensFromHeaders(response);
    String? frontTokenFromResponse =
        response.headers.map[frontTokenHeaderKey]?.first.toString();
    logDebugMessage('SuperTokensInterceptorWrapper.onResponse: frontTokenFromResponse: ${frontTokenFromResponse}');
    SuperTokensUtils.fireSessionUpdateEventsIfNecessary(
      wasLoggedIn:
          _preRequestLocalSessionState.status == LocalSessionStateStatus.EXISTS,
      status: response.statusCode!,
      frontTokenFromResponse: frontTokenFromResponse,
    );
    List<dynamic>? setCookieFromResponse =
        response.headers.map[HttpHeaders.setCookieHeader];
    logDebugMessage('SuperTokensInterceptorWrapper.onResponse: setCookieFromResponse length: ${setCookieFromResponse?.length}');
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
        logDebugMessage('SuperTokensInterceptorWrapper.onResponse: Got expiry status code');
        RequestOptions requestOptions = response.requestOptions;
        int sessionRefreshAttempts =
            requestOptions.extra["__supertokensSessionRefreshAttempts"] ?? 0;
        if (sessionRefreshAttempts >=
            SuperTokens.config.maxRetryAttemptsForSessionRefresh) {
          logDebugMessage('SuperTokensInterceptorWrapper.onResponse: Max attempts of ${SuperTokens.config.maxRetryAttemptsForSessionRefresh} reached for refreshing, cannot continue');
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

        logDebugMessage('SuperTokensInterceptorWrapper.onResponse: removing auth header if it matches token');
        requestOptions =
            await _removeAuthHeaderIfMatchesLocalToken(requestOptions);
        UnauthorisedResponse shouldRetry =
            await Client.onUnauthorisedResponse(_preRequestLocalSessionState);
        if (shouldRetry.status == UnauthorisedStatus.RETRY) {
          logDebugMessage('SuperTokensInterceptorWrapper.onResponse: Got RETRY status');
          logDebugMessage('SuperTokensInterceptorWrapper.onResponse: Refreshing attempt: ${sessionRefreshAttempts + 1}');
          requestOptions.headers[HttpHeaders.cookieHeader] = userSetCookie;

          requestOptions.extra["__supertokensSessionRefreshAttempts"] =
              sessionRefreshAttempts + 1;

          Response<dynamic> res = await client.fetch(requestOptions);
          List<dynamic>? setCookieFromResponse =
              res.headers.map[HttpHeaders.setCookieHeader];
          logDebugMessage('SuperTokensInterceptorWrapper.onResponse: setCookieFromResponse length: ${setCookieFromResponse?.length}');
          setCookieFromResponse?.forEach((element) async {
            await Client.cookieStore
                ?.saveFromSetCookieHeader(res.realUri, element);
          });
          logDebugMessage('SuperTokensInterceptorWrapper.onResponse: Saving tokens from headers');
          await saveTokensFromHeaders(res);
          logDebugMessage('SuperTokensInterceptorWrapper.onResponse: Calling next on handler');
          return handler.next(res);
        } else {
          if (shouldRetry.exception != null) {
            logDebugMessage('SuperTokensInterceptorWrapper.onResponse: Got non null exception');
            handler.reject(
              DioException(
                  requestOptions: response.requestOptions,
                  error: SuperTokensException(shouldRetry.exception!.message),
                  type: DioExceptionType.unknown),
            );
            return;
          } else {
            _refreshAPILock.release();
            logDebugMessage('SuperTokensInterceptorWrapper.onResponse: Calling next on handler');
            return handler.next(response);
          }
        }
      } else {
        _refreshAPILock.release();
        logDebugMessage('SuperTokensInterceptorWrapper.onResponse: Calling next on handler');
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
    logDebugMessage('SuperTokensInterceptorWrapper.saveTokensFromHeaders: Saving tokens from header');
    String? frontTokenFromResponse =
        response.headers.map[frontTokenHeaderKey]?.first.toString();
    logDebugMessage('SuperTokensInterceptorWrapper.saveTokensFromHeaders: frontTokenFromResponse: ${frontTokenFromResponse}');

    if (frontTokenFromResponse != null) {
      logDebugMessage('SuperTokensInterceptorWrapper.saveTokensFromHeaders: Setting token since it is not null');
      await FrontToken.setItem(frontTokenFromResponse);
    }

    String? antiCSRFFromResponse =
        response.headers.map[antiCSRFHeaderKey]?.first.toString();

    if (antiCSRFFromResponse != null) {
      LocalSessionState localSessionState =
          await SuperTokensUtils.getLocalSessionState();

      logDebugMessage('SuperTokensInterceptorWrapper.saveTokensFromHeaders: Setting token in AntiCSRF');
      await AntiCSRF.setToken(
        antiCSRFFromResponse,
        localSessionState.lastAccessTokenUpdate,
      );
    }

    String? accessHeader =
        response.headers.map[ACCESS_TOKEN_NAME]?.first.toString();

    logDebugMessage('SuperTokensInterceptorWrapper.saveTokensFromHeaders: accessHeader: ${accessHeader}');
    if (accessHeader != null) {
      logDebugMessage('SuperTokensInterceptorWrapper.saveTokensFromHeaders: Setting access header');
      await Utils.setToken(TokenType.ACCESS, accessHeader);
    }
    String? refreshHeader =
        response.headers.map[REFRESH_TOKEN_NAME]?.first.toString();

    logDebugMessage('SuperTokensInterceptorWrapper.saveTokensFromHeaders: refreshHeader: ${refreshHeader}');
    if (refreshHeader != null) {
      logDebugMessage('SuperTokensInterceptorWrapper.saveTokensFromHeaders: Setting refresh header');
      await Utils.setToken(TokenType.REFRESH, refreshHeader);
    }
  }

  Future<RequestOptions> _removeAuthHeaderIfMatchesLocalToken(
      RequestOptions req) async {
    logDebugMessage('SuperTokensInterceptorWrapper._removeAuthHeaderIfMatchesLocalToken: Removing auth header if it matches local token');
    if (req.headers.containsKey("Authorization") ||
        req.headers.containsKey("authorization")) {
      String? authValue = req.headers['Authorization'];
      logDebugMessage('SuperTokensInterceptorWrapper._removeAuthHeaderIfMatchesLocalToken: authValue: ${authValue}');
      if (authValue == null) {
        logDebugMessage('SuperTokensInterceptorWrapper._removeAuthHeaderIfMatchesLocalToken: Setting auth header');
        authValue = req.headers["authorization"];
      }
      String? accessToken = await Utils.getTokenForHeaderAuth(TokenType.ACCESS);
      String? refreshToken = await Utils.getTokenForHeaderAuth(TokenType.REFRESH);
      logDebugMessage('SuperTokensInterceptorWrapper._removeAuthHeaderIfMatchesLocalToken: accessToken: ${accessToken}');
      logDebugMessage('SuperTokensInterceptorWrapper._removeAuthHeaderIfMatchesLocalToken: refreshToken: ${refreshToken}');

      if (accessToken != null && refreshToken != null && authValue != "Bearer $accessToken") {
        logDebugMessage('SuperTokensInterceptorWrapper._removeAuthHeaderIfMatchesLocalToken: Removing authorization headers');
        req.headers.remove('Authorization');
        req.headers.remove('authorization');
      }
    }
    return req;
  }

  static Future<RequestOptions> _setAuthorizationHeaderIfRequired(
      RequestOptions options,
      {bool addRefreshToken = false}) async {
    logDebugMessage('SuperTokensInterceptorWrapper._setAuthorizationHeaderIfRequired: Setting authorization header if required');
    String? accessToken = await Utils.getTokenForHeaderAuth(TokenType.ACCESS);
    String? refreshToken = await Utils.getTokenForHeaderAuth(TokenType.REFRESH);
    logDebugMessage('SuperTokensInterceptorWrapper._setAuthorizationHeaderIfRequired: accessToken: ${accessToken}');
    logDebugMessage('SuperTokensInterceptorWrapper._setAuthorizationHeaderIfRequired: refreshToken: ${refreshToken}');

    if (accessToken != null && refreshToken != null) {
      if (options.headers["Authorization"] != null ||
          options.headers["authorization"] != null) {
        //  no-op
        logDebugMessage('SuperTokensInterceptorWrapper._setAuthorizationHeaderIfRequired: Doing nothing as headers are already set');
      } else {
        String tokenToAdd = addRefreshToken ? refreshToken : accessToken;
        logDebugMessage('SuperTokensInterceptorWrapper._setAuthorizationHeaderIfRequired: Setting header to bearer: ${tokenToAdd}');
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
