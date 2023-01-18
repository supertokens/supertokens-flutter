import 'dart:convert';

import "package:http/http.dart" as http;
import 'package:supertokens/src/anti-csrf.dart';
import 'package:supertokens/src/front-token.dart';
import 'package:supertokens/src/id-refresh-token.dart';
import 'package:supertokens/supertokens.dart';

class SuperTokensTestUtils {
  static String baseUrl = "http://localhost:8080";
  static http.Client _internalClient = http.Client();

  static beforeAllTest() async {
    String beforeAllTestAPIURL = "$baseUrl/test/tartServer";
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
    String afterAllTestAPIURL = "$baseUrl/after";
    String afterAllStopTestAPIURL = "$baseUrl/stop";
    await _internalClient.post(Uri.parse(afterAllTestAPIURL));
    await _internalClient.get(Uri.parse(afterAllStopTestAPIURL));
  }

  static void startST(
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
}
