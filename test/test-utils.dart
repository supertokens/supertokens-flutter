import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import "package:http/http.dart" as http;
import 'package:supertokens_flutter/src/anti-csrf.dart';
import 'package:supertokens_flutter/src/front-token.dart';
import 'package:supertokens_flutter/supertokens.dart';

class _MyHttpOverrides extends HttpOverrides {}

class SuperTokensTestUtils {
  static String baseUrl = "http://localhost:8080";
  static http.Client _internalClient = http.Client();

  static beforeAllTest() async {
    HttpOverrides.global = _MyHttpOverrides();
    String beforeAllTestAPIURL = "$baseUrl/test/startServer";
    await _internalClient.post(Uri.parse(beforeAllTestAPIURL));
  }

  static beforeEachTest() async {
    String beforeEachAPIURL = "$baseUrl/beforeeach";
    await FrontToken.removeToken();
    await AntiCSRF.removeToken();
    SuperTokens.isInitCalled = false;
    await _internalClient.post(Uri.parse(beforeEachAPIURL));
  }

  static afterAllTest() async {
    String afterAllStopTestAPIURL = "$baseUrl/stopst";
    await _internalClient.get(Uri.parse(afterAllStopTestAPIURL));
  }

  static Future startST(
      {int validity = 3, bool disableAntiCSRF = false}) async {
    String startSTAPIURL = "$baseUrl/startst";
    var body = jsonEncode(
        {"accessTokenValidity": validity, "enableAntiCsrf": !disableAntiCSRF});
    http.Response resp = await _internalClient.post(
      Uri.parse(startSTAPIURL),
      headers: {"Content-Type": "application/json; charset=utf-8"},
      body: body,
    );
    if (resp.statusCode != 200) {
      throw Exception("Error starting supertokens");
    }
  }

  static Future<int> refreshTokenCounter() async {
    String refreshTokenCountAPIURL = "$baseUrl/refreshAttemptedTime";
    http.Response resp =
        await _internalClient.get(Uri.parse(refreshTokenCountAPIURL));
    if (resp.statusCode != 200) {
      throw Exception("Getting count failed");
    }
    var respBody = jsonDecode(resp.body);
    return respBody['counter'] as int;
  }

  static http.Request getLoginRequest() {
    var loginAPIURL = "$baseUrl/login";
    var request = http.Request('POST', Uri.parse(loginAPIURL));
    request.headers['Content-Type'] = "application/json; charset=utf-8";
    var body = {"userId": "supertokens-flutter-tests"};
    var jsonBody = jsonEncode(body);
    request.body = jsonBody;
    return request;
  }

  static http.Request getLoginRequestUtf8Encoded() {
    var loginAPIURL = "$baseUrl/login";
    var request = http.Request('POST', Uri.parse(loginAPIURL));
    request.headers['Content-Type'] = "application/json; charset=utf-8";
    var body = {"userId": "supertokens-flutter-tests", "payload": {
      "name": "\xc3\xb6\xc3\xa4\xc3\xbc\x2d\xc3\xa1\xc3\xa0\xc3\xa2" // UTF-8 encoded öäü-áàâ
    }};
    var jsonBody = jsonEncode(body);
    request.body = jsonBody;
    return request;
  }

  static http.Request getLogin218Request() {
    var loginAPIURL = "$baseUrl/login-2.18";
    var request = http.Request('POST', Uri.parse(loginAPIURL));
    request.headers['Content-Type'] = "application/json; charset=utf-8";
    var body = {"userId": "supertokens-flutter-tests", "payload": {"asdf": 1}};
    var jsonBody = jsonEncode(body);
    request.body = jsonBody;
    return request;
  }

  static http.Request getLogoutAltRequest() {
    var loginAPIURL = "$baseUrl/logout-alt";
    var request = http.Request('POST', Uri.parse(loginAPIURL));
    request.headers['Content-Type'] = "application/json; charset=utf-8";
    return request;
  }

  static RequestOptions getLoginRequestDio() {
    var loginAPIURL = "/login";
    var reqOptions = RequestOptions(
      baseUrl: baseUrl,
      path: loginAPIURL,
      method: 'POST',
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      data: {"userId": "supertokens-ios-tests"},
    );
    return reqOptions;
  }

  static RequestOptions getLogin218RequestDio() {
    var loginAPIURL = "/login-2.18";
    var reqOptions = RequestOptions(
      baseUrl: baseUrl,
      path: loginAPIURL,
      method: 'POST',
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      data: {"userId": "supertokens-ios-tests", "payload": {"asdf": 1}},
    );
    return reqOptions;
  }

  static RequestOptions getLogoutAltRequestDio() {
    var loginAPIURL = "/logout-alt";
    var reqOptions = RequestOptions(
      baseUrl: baseUrl,
      path: loginAPIURL,
      method: 'POST',
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      data: {},
    );
    return reqOptions;
  }

  static Future<Map<String, bool>> getFeatureFlags() async {
    var featureFlagsAPIURL = "$baseUrl/featureFlags";
    http.Response resp =
        await _internalClient.get(Uri.parse(featureFlagsAPIURL));
    if (resp.statusCode != 200) {
      throw Exception("Getting count failed");
    }
    Map<String, bool> respBody = Map.castFrom(jsonDecode(resp.body));
    return respBody;
  }

  static Future<bool> checkIfV3AccessTokenIsSupported() async {
    var featureFlags = await getFeatureFlags();
    return featureFlags['v3AccessToken'] == true;
  }
}
