import 'dart:io';

import 'package:dio/dio.dart';
import 'package:mutex/mutex.dart';
import 'package:supertokens/src/anti-csrf.dart';
import 'package:supertokens/src/constants.dart';
import 'package:supertokens/src/cookie-store.dart';
import 'package:supertokens/src/errors.dart';
import 'package:supertokens/src/front-token.dart';
import 'package:supertokens/src/id-refresh-token.dart';
import 'package:supertokens/src/supertokens-http-client.dart';
import 'package:supertokens/src/supertokens.dart';
import 'package:supertokens/src/utilities.dart';

class SuperTokensInterceptorWrapper extends Interceptor {
  ReadWriteMutex _refreshAPILock = ReadWriteMutex();
  final Dio client;
  late dynamic userSetCookie;

  SuperTokensInterceptorWrapper({required this.client});

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (!SuperTokens.isInitCalled) {
      throw SuperTokensException(
          "SuperTokens.initialise must be called before using Client");
    }

    if (!Utils.shouldDoInterceptions(options.uri.toString(),
        SuperTokens.config.apiDomain, SuperTokens.config.cookieDomain)) {
      super.onRequest(options, handler);
    }

    if (Client.cookieStore == null) {
      Client.cookieStore = SuperTokensCookieStore();
    }

    if (SuperTokensUtils.getApiDomain(options.uri.toString()) !=
        SuperTokens.config.apiDomain) {
      super.onRequest(options, handler);
    }

    if (SuperTokensUtils.getApiDomain(options.uri.toString()) ==
        SuperTokens.refreshTokenUrl) {
      super.onRequest(options, handler);
    }

    String? preRequestIdRefreshToken = await IdRefreshToken.getToken();
    String? antiCSRFToken = await AntiCSRF.getToken(preRequestIdRefreshToken);

    if (antiCSRFToken != null) {
      options.headers[antiCSRFHeaderKey] = antiCSRFToken;
    }

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
      options.headers[HttpHeaders.cookieHeader] =
          "$existingCookieHeader;${newCookiesToAdd ?? ""}";
    } else {
      options.headers[HttpHeaders.cookieHeader] = newCookiesToAdd ?? "";
    }

    options.headers.addAll({'st-auth-mode': 'cookie'});

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
    _refreshAPILock.acquireWrite();
    List<dynamic>? setCookieFromResponse =
        response.headers.map[HttpHeaders.setCookieHeader];
    setCookieFromResponse?.forEach((element) async {
      await Client.cookieStore
          ?.saveFromSetCookieHeader(response.realUri, element);
    });
    String? idRefreshTokenFromResponse =
        response.headers.map[idRefreshHeaderKey]?.first.toString();
    if (idRefreshTokenFromResponse != null) {
      await IdRefreshToken.setToken(idRefreshTokenFromResponse);
    }
    String? frontTokenFromResponse =
        response.headers.map[frontTokenHeaderKey]?.first.toString();
    if (frontTokenFromResponse != null) {
      await FrontToken.setToken(frontTokenFromResponse);
    }
    String? preRequestIdRefreshToken = await IdRefreshToken.getToken();
    try {
      if (response.statusCode == SuperTokens.sessionExpiryStatusCode) {
        UnauthorisedResponse shouldRetry =
            await Client.onUnauthorisedResponse(preRequestIdRefreshToken);
        if (shouldRetry.status == UnauthorisedStatus.RETRY) {
          RequestOptions requestOptions = response.requestOptions;
          requestOptions.headers[HttpHeaders.cookieHeader] = userSetCookie;
          Response<dynamic> req = await client.fetch(requestOptions);
          List<dynamic>? setCookieFromResponse =
              req.headers.map[HttpHeaders.setCookieHeader];
          setCookieFromResponse?.forEach((element) async {
            await Client.cookieStore
                ?.saveFromSetCookieHeader(req.realUri, element);
          });
          String? idRefreshTokenFromResponse =
              req.headers.map[idRefreshHeaderKey]?.first.toString();
          if (idRefreshTokenFromResponse != null) {
            await IdRefreshToken.setToken(idRefreshTokenFromResponse);
          }
          String? frontTokenFromResponse =
              req.headers.map[frontTokenHeaderKey]?.first.toString();
          if (frontTokenFromResponse != null) {
            await FrontToken.setToken(frontTokenFromResponse);
          }
          handler.next(req);
        } else {
          if (await IdRefreshToken.getToken() == null) {
            AntiCSRF.removeToken();
            FrontToken.removeToken();
          }
          if (shouldRetry.exception != null) {
            var data = response.data;
            throw SuperTokensException(shouldRetry.exception!.message);
          } else {
            _refreshAPILock.release();
            return handler.next(response);
          }
        }
      } else {
        String? antiCSRFFromResponse =
            response.headers.map[antiCSRFHeaderKey]?.first.toString();
        if (antiCSRFFromResponse != null) {
          String? postRequestIdRefresh = await IdRefreshToken.getToken();
          await AntiCSRF.setToken(
            antiCSRFFromResponse,
            postRequestIdRefresh,
          );
        }
        _refreshAPILock.release();
        return handler.next(response);
      }
    } finally {
      String? idRefreshToken = await IdRefreshToken.getToken();
      if (idRefreshToken == null) {
        await AntiCSRF.removeToken();
        await FrontToken.removeToken();
      }
    }
  }
}
