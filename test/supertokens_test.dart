import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supertokens/http.dart' as http;
import 'package:supertokens/src/anti-csrf.dart';
import 'package:supertokens/src/id-refresh-token.dart';
import 'package:supertokens/src/utilities.dart';
import 'package:supertokens/supertokens.dart';

import 'test-utils.dart';

void main() {
  String apiBasePath = SuperTokensTestUtils.baseUrl;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    return SuperTokensTestUtils.beforeAllTest();
  });
  setUp(() async {
    // TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    SuperTokensTestUtils.beforeEachTest();
    SuperTokens.isInitCalled = false;
    await AntiCSRF.removeToken();
    await IdRefreshToken.removeToken();
    return Future.delayed(Duration(seconds: 1));
  });
  tearDownAll(() => SuperTokensTestUtils.afterAllTest());

  test('Test Session Expired without a refresh call', () async {
    // WidgetsFlutterBinding.ensureInitialized();
    await SuperTokensTestUtils.startST(validity: 3);
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
    await SuperTokensTestUtils.startST(validity: 3, disableAntiCSRF: true);
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
    await SuperTokensTestUtils.startST(validity: 3);
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
        // ! following message seems incorrect
        else if (idRefreshAfter == idRefreshToken)
          fail("id before and after are not the same!");
      }
    }
    Uri refreshCustomHeader = Uri.parse("$apiBasePath/refreshHeader");
    var refreshResponse = await http.get(refreshCustomHeader);
    if (refreshResponse.statusCode != 200) fail("Refresh Request failed");
    var jsonResp = jsonDecode(refreshResponse.body);
    if (jsonResp["custom-header"] != "custom-value") fail("Header not sent");
  });

// while logged in, test that APIs that there is proper change in id refresh stored in storage
  test("Test id-refresh-token change", () async {
    String failureMessage = "";
    await SuperTokensTestUtils.startST(validity: 3);

    try {
      SuperTokens.init(apiDomain: apiBasePath);
    } catch (e) {
      failureMessage = "init failed";
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
      fail("Login API failed");
    }
    String? idBefore = await IdRefreshToken.getToken();
    if (idBefore == null) fail("id-refresh-token is null");
    sleep(Duration(seconds: 5));
    Uri userInfoUrl = Uri.parse("$apiBasePath/");
    var userInfoResp = await http.get(userInfoUrl);
    if (userInfoResp.statusCode != 200)
      fail("UserInfo API returned ${userInfoResp.statusCode} ");
    String? idAfter = await IdRefreshToken.getToken();
    if (idAfter == null) fail("id-refresh-token is null after response");
    if (idAfter != idBefore) fail("id before and id after are not same!");
  });

  test("Test to check if request can be made without Supertokens.init",
      () async {
    await SuperTokensTestUtils.startST(validity: 3);
    Request req = SuperTokensTestUtils.getLoginRequest();
    StreamedResponse streamedResp;
    try {
      streamedResp = await http.send(req);
    } catch (e) {
      fail("Login request failed");
    }
    var resp = await Response.fromStream(streamedResp);
    if (resp.statusCode != 200) {
      fail("Login API failed");
    }
  });

  test('More than one calls to init works', () async {
    await SuperTokensTestUtils.startST(validity: 5);
    try {
      SuperTokens.init(apiDomain: apiBasePath);
      SuperTokens.init(apiDomain: apiBasePath);
    } catch (e) {
      fail("Calling init more than once fails the test");
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
      fail("Login API failed");
    }
    try {
      SuperTokens.init(apiDomain: apiBasePath);
    } catch (e) {
      fail("Calling init more than once fails the test");
    }
    Uri userInfoUrl = Uri.parse("$apiBasePath/");
    var userInfoResp = await http.get(userInfoUrl);
    if (userInfoResp.statusCode != 200)
      fail("Calling init more than once fails the test");
  });

  test("Test if erfresh is called after access token expires", () async {
    await SuperTokensTestUtils.startST(validity: 3);
    bool failed = false;
    SuperTokens.init(apiDomain: apiBasePath);
    Request req = SuperTokensTestUtils.getLoginRequest();
    StreamedResponse streamedResp;
    streamedResp = await http.send(req);
    var resp = await Response.fromStream(streamedResp);
    if (resp.statusCode != 200) {
      failed = true;
    }
    Uri userInfoUrl = Uri.parse("$apiBasePath/");
    var userInfoResp = await http.get(userInfoUrl);
    if (userInfoResp.statusCode != 200) failed = true;

    int counter = await SuperTokensTestUtils.refreshTokenCounter();
    if (counter != 1) failed = true;

    assert(!failed);
  });

  // TODO: check out multi threading and figure out this test
  // test(
  //     'Refresh only get called once after multiple request (Concurrency)',
  //     () async {
  //   bool failed = false;
  //   await SuperTokensTestUtils.startST(validity: 10);
  //   List<bool> results = [];
  //   SuperTokens.init(apiDomain: apiBasePath);
  //   Request req = SuperTokensTestUtils.getLoginRequest();
  //   StreamedResponse streamedResp;
  //   streamedResp = await http.send(req);
  //   var resp = await Response.fromStream(streamedResp);
  //   if (resp.statusCode != 200) {
  //     failed = true;
  //   }
  //   // Future.wait(futures)
  // });

  //! This test seems incorrect on iOS
  // test('Test that session does not exist after after calling signOut',
  //     () async {
  //   SuperTokens.init(apiDomain: apiBasePath);
  //   Request req = SuperTokensTestUtils.getLoginRequest();
  //   StreamedResponse streamedResp;
  //   streamedResp = await http.send(req);
  //   var resp = await Response.fromStream(streamedResp);
  //   if (resp.statusCode != 200) {
  //     fail("Login failed");
  //   }
  //   if (!await SuperTokens.doesSessionExist()) {
  //     fail("Session may not exist accoring to library.. but it does!");
  //   } else {
  //     // String idRefresh = await IdRefreshToken.getToken();

  //   }
  // });

  test("Test does session exist after user is loggedIn", () async {
    await SuperTokensTestUtils.startST(validity: 1);
    bool sessionExist = false;
    SuperTokens.init(apiDomain: apiBasePath);
    Request req = SuperTokensTestUtils.getLoginRequest();
    StreamedResponse streamedResp;
    streamedResp = await http.send(req);
    var resp = await Response.fromStream(streamedResp);
    if (resp.statusCode != 200) {
      fail("Login failed");
    }
    sessionExist = await SuperTokens.doesSessionExist();
    // logout
    Uri logoutReq = Uri.parse("$apiBasePath/logout");
    var logoutResp = await http.post(logoutReq);
    if (logoutResp.statusCode != 200) fail("Logout req failed");
    sessionExist = await SuperTokens.doesSessionExist();
    assert(!sessionExist);
  });

  test("Test if not logged in  the  Auth API throws session expired", () async {
    await SuperTokensTestUtils.startST(validity: 1);
    Uri userInfoURL = Uri.parse("$apiBasePath/");
    var resp = await http.get(userInfoURL);

    if (resp.statusCode != 401) {
      fail("API should have returned session expired (401) but didnt");
    }
  });

  test("Test other other domains work without Authentication", () async {
    await SuperTokensTestUtils.startST(validity: 1);
    Uri fakeGetApi = Uri.parse("https://www.google.com");
    var resp = await http.get(fakeGetApi);
    if (resp.statusCode != 200)
      fail("Unable to make Get API Request to external URL");
    Request req = SuperTokensTestUtils.getLoginRequest();
    StreamedResponse streamedResp;
    streamedResp = await http.send(req);
    var loginResp = await Response.fromStream(streamedResp);
    if (loginResp.statusCode != 200) {
      fail("Login failed");
    }
    resp = await http.get(fakeGetApi);
    if (resp.statusCode != 200)
      fail("Unable to make Get API Request to external URL");
    // logout
    Uri logoutReq = Uri.parse("$apiBasePath/logout");
    var logoutResp = await http.post(logoutReq);
    if (logoutResp.statusCode != 200) fail("Logout req failed");
    resp = await http.get(fakeGetApi);
    if (resp.statusCode != 200)
      fail("Unable to make Get API Request to external URL");
  });
}
