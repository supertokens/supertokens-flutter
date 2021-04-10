@Timeout(const Duration(seconds: 60))
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supertokens/src/anti-csrf.dart';
import 'package:supertokens/src/id-refresh-token.dart';
import 'package:supertokens/supertokens.dart';
import 'package:http/http.dart' as http;

import 'test-utils.dart';

void main() {
  SuperTokensHttpClient networkClient =
      SuperTokensHttpClient.getInstance(http.Client());

  String loginAPIURL = "${SuperTokensTestUtils.testAPIBase}login";
  String refreshTokenUrl = "${SuperTokensTestUtils.testAPIBase}refresh";
  String userInfoAPIURL = "${SuperTokensTestUtils.testAPIBase}userInfo";
  String logoutAPIURL = "${SuperTokensTestUtils.testAPIBase}logout";

  int sessionExpiryCode = 401;

  Future<void> startST({
    int validity = 1,
    double? refreshValidity,
    bool disableAntiCSRF = false,
  }) async {
    await SuperTokensTestUtils.startSuperTokens(
        validity: validity,
        refreshValidity: refreshValidity,
        disableAntiCSRF: disableAntiCSRF);
  }

  Future<void> _setUp() async {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    SuperTokens.isInitCalled = false;
    await AntiCSRF.removeToken();
    await IdRefreshToken.removeToken();
    await SuperTokensTestUtils.beforeEachTest();
  }

  setUp(() {
    return _setUp();
  });

  tearDown(() async {
    return SuperTokensTestUtils.afterEachTest();
  });

  test("Test that requests fail when SuperTokens.initialise is not called",
      () async {
    try {
      await networkClient.post(Uri.parse(loginAPIURL));
    } on http.ClientException catch (e) {
      if (e.message !=
          "SuperTokens.initialise must be called before using SuperTokensHttpClient") {
        throw e;
      }
    } catch (e) {
      throw e;
    }
  });

  test("Test that multiple calls to SuperTokens.initialise work as expected",
      () async {
    await startST(validity: 5);

    try {
      SuperTokens.initialise(
          refreshTokenEndpoint: refreshTokenUrl,
          sessionExpiryStatusCode: sessionExpiryCode);

      SuperTokens.initialise(
          refreshTokenEndpoint: refreshTokenUrl,
          sessionExpiryStatusCode: sessionExpiryCode);
    } catch (e) {
      fail("Calling initialise more than once failed");
    }

    http.Response response = await networkClient.post(Uri.parse(loginAPIURL));
    if (response.statusCode != 200) {
      fail("Login API failed");
    }

    try {
      SuperTokens.initialise(
          refreshTokenEndpoint: refreshTokenUrl,
          sessionExpiryStatusCode: sessionExpiryCode);
    } catch (e) {
      fail("Calling initialise more than once failed");
    }

    http.Response userInfoResponse =
        await networkClient.get(Uri.parse(userInfoAPIURL));
    if (userInfoResponse.statusCode != 200) {
      fail("UserInfo API failed");
    }
  });

  test(
      "Test that the refresh endpoint gets set correctly when using a URL with no path",
      () {
    try {
      SuperTokens.initialise(refreshTokenEndpoint: "https://api.example.com");
    } catch (e) {
      fail("SuperTokens.initialise threw an error");
    }
    expect(SuperTokens.refreshTokenEndpoint,
        "https://api.example.com/session/refresh");
  });

  test(
      "Test that the refresh endpoint gets set correctly when using a URL with empty path",
      () {
    try {
      SuperTokens.initialise(refreshTokenEndpoint: "https://api.example.com/");
    } catch (e) {
      fail("SuperTokens.initialise threw an error");
    }
    expect(SuperTokens.refreshTokenEndpoint,
        "https://api.example.com/session/refresh");
  });

  test(
      "Test that the refresh endpoint gets set correctly when using a URL with a valid path",
      () {
    try {
      SuperTokens.initialise(
          refreshTokenEndpoint: "https://api.example.com/other/url");
    } catch (e) {
      fail("SuperTokens.initialise threw an error");
    }
    expect(
        SuperTokens.refreshTokenEndpoint, "https://api.example.com/other/url");
  });

  test(
      "Test that network requests without valid credentials throw session expired and do not trigger a call to the refresh endpoint",
      () async {
    await startST(validity: 3);

    try {
      SuperTokens.initialise(
          refreshTokenEndpoint: refreshTokenUrl,
          sessionExpiryStatusCode: sessionExpiryCode);
    } catch (e) {
      throw e;
    }

    try {
      http.Response response =
          await networkClient.get(Uri.parse(userInfoAPIURL));

      if (response.statusCode == 200) {
        fail("userInfo API succeeded when it should have failed");
      }

      if (response.statusCode != sessionExpiryCode) {
        fail("UserInfo status code did not match session expired");
      }
    } catch (e) {
      throw e;
    }
  });

  test("Test that the library works as expected when anti-csrf is disabled",
      () async {
    await startST(validity: 3, refreshValidity: 2, disableAntiCSRF: true);

    try {
      SuperTokens.initialise(
          refreshTokenEndpoint: refreshTokenUrl,
          sessionExpiryStatusCode: sessionExpiryCode);
    } catch (e) {
      throw e;
    }

    http.Response response = await networkClient.post(Uri.parse(loginAPIURL));

    if (response.statusCode != 200) {
      fail("Login API failed");
    }

    await Future.delayed(Duration(seconds: 5));

    http.Response userInfoResponse =
        await networkClient.get(Uri.parse(userInfoAPIURL));

    if (userInfoResponse.statusCode != 200) {
      fail("userInfo API failed");
    }

    int refreshCounter = await SuperTokensTestUtils.getRefreshTokenCounter();
    if (refreshCounter != 1) {
      fail("Unexpected counter value: was $refreshCounter extected 1");
    }

    http.Response logoutResponse =
        await networkClient.post(Uri.parse(logoutAPIURL));
    if (logoutResponse.statusCode != 200) {
      fail("Logout API failed");
    }

    expect(await SuperTokens.doesSessionExist(), false);
  });

  test(
      "Test that custom refresh headers are sent properly when calls to the refresh endpoint are triggered",
      () {
    // TODO: Add test case
    expect(true, false);
  });

  test(
      "Test that network calls that dont require authentication work properly before, during and after login when using SuperTokensHttpClient",
      () {
    // TODO: Add test case
    expect(true, false);
  });

  test(
      "Test that network calls that dont require authentication work properly before, during and after login without using SuperTokensHttpClient",
      () {
    // TODO: Add test case
    expect(true, false);
  });

  test(
      "Test that idRefreshToken in storage changes properly when the network response sends a new header value",
      () {
    // TODO: Add test case
    expect(true, false);
  });

  test(
      "Test that the refresh endpoint is called after the access token expires",
      () {
    // TODO: Add test case
    expect(true, false);
  });

  test(
      "Test that refresh endpoint gets called only once for multiple parallel tasks",
      () {
    // TODO: Add test case
    expect(true, false);
  });

  test(
      "Test that doesSessionExist returns false after credentials are cleared by a network response",
      () {
    // TODO: Add test case
    expect(true, false);
  });

  test(
      "Test that doesSessionExist returns true when valid credentials are present",
      () {
    // TODO: Add test case
    expect(true, false);
  });

  test(
      "Test that in the case of API errors the error message is returned to the function using SuperTokensHttpClient",
      () {
    // TODO: Add test case
    expect(true, false);
  });

  test(
      "Test that network requests to domains other than SuperTokens.apiDomain work fine before, during and after logout",
      () {
    // TODO: Add test case
    expect(true, false);
  });

  test(
      "Test that custom request headers are sent correctly when using SuperTokensHttpClient",
      () {
    // TODO: Add test case
    expect(true, false);
  });

  test(
      "Test that passing an instance of a custom client works as expected when using SuperTokensHttpClient",
      () {
    // TODO: Add test case
    expect(true, false);
  });
}
