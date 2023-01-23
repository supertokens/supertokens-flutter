import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import "package:http/http.dart" as http;
import 'package:supertokens_flutter/src/anti-csrf.dart';
import 'package:supertokens_flutter/src/front-token.dart';
import 'package:supertokens_flutter/src/id-refresh-token.dart';
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

  static void beforeEachTest() async {
    String beforeEachAPIURL = "$baseUrl/beforeeach";
    FrontToken.removeToken();
    AntiCSRF.removeToken();
    IdRefreshToken.removeToken();
    SuperTokens.isInitCalled = false;
    await _internalClient.post(Uri.parse(beforeEachAPIURL));
  }

  static afterAllTest() async {
    String afterAllStopTestAPIURL = "$baseUrl/stopst";
    await _internalClient.get(Uri.parse(afterAllStopTestAPIURL));
  }

  static Future startST(
      {required int validity, bool disableAntiCSRF = false}) async {
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
    var body = {"userId": "supertokens-ios-tests"};
    var jsonBody = jsonEncode(body);
    request.body = jsonBody;
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
}
