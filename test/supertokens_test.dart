import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supertokens/http.dart' as http;
import 'package:supertokens/src/anti-csrf.dart';
import 'package:supertokens/src/id-refresh-token.dart';
import 'package:supertokens/supertokens.dart';

import 'test-utils.dart';

void main() {
  String apiBasePath = SuperTokensTestUtils.baseUrl;
  setUp(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await SuperTokensTestUtils.beforeAllTest();
    SharedPreferences.setMockInitialValues({});
    SuperTokens.isInitCalled = false;
    await AntiCSRF.removeToken();
    await IdRefreshToken.removeToken();
    await Future.delayed(Duration(seconds: 1));
  });
  setUpAll(() => SuperTokensTestUtils.beforeEachTest());
  tearDownAll(() => SuperTokensTestUtils.afterAllTest());

  test('Test Session Expired without a refresh call', () async {
    SuperTokensTestUtils.startST(validity: 3);
    SuperTokens.init(apiDomain: apiBasePath);
    Uri userInfoURL = Uri.parse("$apiBasePath/");
    var resp = await http.get(userInfoURL);

    if (resp.statusCode != 401) {
      fail("API should have returned unauthorised but didnt");
    }

    int counter = await SuperTokensTestUtils.refreshTokenCounter();
    if (counter != 0) fail("Refresh counter returned non zero value");
  });

  test("Test things work if AntiCSRF is disabled", () async {
    SuperTokensTestUtils.startST(validity: 3, disableAntiCSRF: true);
    SuperTokens.init(apiDomain: apiBasePath);
    Request req = SuperTokensTestUtils.getLoginRequest();
    StreamedResponse streamedResp;
    try {
      streamedResp = await http.send(req);
    } catch (e) {
      fail("Login request failed");
    }
    var resp = await Response.fromStream(streamedResp);
    if (resp.statusCode != 200) {
      fail("Login request gave ${resp.statusCode}");
    } else {
      Uri userInfoURL = Uri.parse("$apiBasePath/");
      sleep(Duration(seconds: 5));
      var userInfoResp = await http.get(userInfoURL);
      if (userInfoResp.statusCode != 200)
        fail("API responded with staus ${userInfoResp.statusCode}");
    }

    int counter = await SuperTokensTestUtils.refreshTokenCounter();
    if (counter != 1) fail("Refresh counter returned wrong value: $counter");

    // logout
    Uri logoutReq = Uri.parse("$apiBasePath/logout");
    var logoutResp = await http.post(logoutReq);
    if (logoutResp.statusCode != 200) fail("Logout req failed");
  });

  test("Test custom headers for refreshAPI", () async {
    SuperTokensTestUtils.startST(validity: 3);
    try {
      SuperTokens.init(
        apiDomain: apiBasePath,
        preAPIHook: ((action, req) {
          req.headers.addAll({"custom-header": "custom-value"});
          return req;
        }),
      );
    } catch (e) {
      fail("SuperTokens init failed");
    }

    Request req = SuperTokensTestUtils.getLoginRequest();
    StreamedResponse streamedResp;
    try {
      streamedResp = await http.send(req);
    } catch (e) {
      fail("Login request failed");
    }
    var resp = await Response.fromStream(streamedResp);
    if (resp.statusCode != 200) {
      fail("Login request gave ${resp.statusCode}");
    } else {
      String? idRefreshToken = await IdRefreshToken.getToken();
      if (idRefreshToken == null) fail("id-refresh-token was null");
      sleep(Duration(seconds: 5));
      Uri userInfoURL = Uri.parse("$apiBasePath/");
      sleep(Duration(seconds: 5));
      var userInfoResp = await http.get(userInfoURL);
      if (userInfoResp.statusCode != 200)
        fail("API responded with staus ${userInfoResp.statusCode}");
      else {
        String? idRefreshAfter = await IdRefreshToken.getToken();
        if (idRefreshAfter == null)
          fail("id-refresh-token after userInfo was null");
        // ! following seeems breaking
        else if (idRefreshAfter == idRefreshToken)
          fail("id before and after are not the same!");
      }
    }
    Uri refreshCustomHeader = Uri.parse("$apiBasePath/refreshHeader");
    var redfreshResponse = await http.get(refreshCustomHeader);
  });
}
