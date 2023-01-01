import 'dart:convert';

import 'package:http/http.dart' as http;

class SuperTokensTestUtils {
  static String testAPIBase = "http://127.0.0.1:3001/";
  static http.Client nonInterceptedClient = http.Client();

  static Future<void> beforeEachTest() async {
    String beforeEachAPIURL = "${testAPIBase}beforeeach";
    await nonInterceptedClient.post(Uri.parse(beforeEachAPIURL));
  }

  static Future<void> afterEachTest() async {
    String afterAPIURL = "${testAPIBase}after";
    await nonInterceptedClient.post(Uri.parse(afterAPIURL));
  }

  static Future<void> startSuperTokens({
    int validity = 1,
    double? refreshValidity,
    bool disableAntiCSRF = false,
  }) async {
    String startSTAPIURL = "${testAPIBase}startst";
    String body = jsonEncode({
      "accessTokenValidity": validity,
    });

    if (refreshValidity != null) {
      body = jsonEncode({
        "accessTokenValidity": validity,
        "refreshTokenValidity": refreshValidity,
        "disableAntiCSRF": disableAntiCSRF,
      });
    }

    http.Response response = await nonInterceptedClient.post(
      Uri.parse(startSTAPIURL),
      headers: {"Content-Type": "application/json; charset=utf-8"},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception("Error starting supertokens");
    }
  }

  static Future<int> getRefreshTokenCounter() async {
    String refreshCounterAPIURL = "${testAPIBase}refreshCounter";
    http.Response response =
        await nonInterceptedClient.get(Uri.parse(refreshCounterAPIURL));

    if (response.statusCode != 200) {
      throw Exception("Error getting refresh token counter");
    }

    Map<String, dynamic> responseBody = jsonDecode(response.body);
    return responseBody["counter"];
  }
}
