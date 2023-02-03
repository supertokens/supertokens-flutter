import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supertokens_flutter/http.dart' as http;
import 'package:supertokens_flutter/src/anti-csrf.dart';
import 'package:supertokens_flutter/src/front-token.dart';
import 'package:supertokens_flutter/supertokens.dart';

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
    await FrontToken.removeToken();
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

  test("Test custom headers for refreshAPI", () async {
    await SuperTokensTestUtils.startST(validity: 3);
    try {
      SuperTokens.init(
        apiDomain: apiBasePath,
        preAPIHook: ((action, req) {
          if (action == APIAction.REFRESH_TOKEN)
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
      // sleep(Duration(seconds: 5));
      await Future.delayed(Duration(seconds: 5), () {});
      Uri userInfoURL = Uri.parse("$apiBasePath/");
      // sleep(Duration(seconds: 5));
      await Future.delayed(Duration(seconds: 5), () {});
      var userInfoResp = await http.get(userInfoURL);
      if (userInfoResp.statusCode != 200) {
        fail("API responded with staus ${userInfoResp.statusCode}");
      }
    }
    Uri refreshCustomHeader = Uri.parse("$apiBasePath/refreshHeader");
    var refreshResponse = await http.get(refreshCustomHeader);
    if (refreshResponse.statusCode != 200) fail("Refresh Request failed");
    var respJson = jsonDecode(refreshResponse.body);
    if (respJson["value"] != "custom-value") fail("Header not sent");
  });

  test("Test to check if request can be made without Supertokens.init",
      () async {
    await SuperTokensTestUtils.startST(validity: 3);
    try {
      Request req = SuperTokensTestUtils.getLoginRequest();
      StreamedResponse streamedResp = await http.send(req);
      var resp = await Response.fromStream(streamedResp);
      if (resp.statusCode != 200) {
        fail("Login API failed");
      }
    } catch (e) {}
    assert(await FrontToken.getToken() == null);
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

  test("Test if refresh is called after access token expires", () async {
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
    // sleep(Duration(seconds: 5));
    await Future.delayed(Duration(seconds: 5), () {});
    Uri userInfoUrl = Uri.parse("$apiBasePath/");
    var userInfoResp = await http.get(userInfoUrl);
    if (userInfoResp.statusCode != 200) {
      failed = true;
    }

    int counter = await SuperTokensTestUtils.refreshTokenCounter();
    if (counter != 1) {
      failed = true;
    }

    assert(!failed);
  });

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
    SuperTokens.init(apiDomain: apiBasePath);
    Uri userInfoURL = Uri.parse("$apiBasePath/");
    var resp = await http.get(userInfoURL);

    if (resp.statusCode != 401) {
      fail("API should have returned session expired (401) but didnt");
    }
  });

  test("Test other other domains work without Authentication", () async {
    await SuperTokensTestUtils.startST(validity: 1);
    SuperTokens.init(apiDomain: apiBasePath);
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
