import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supertokens/src/anti-csrf.dart';
import 'package:supertokens/src/id-refresh-token.dart';
import 'package:supertokens/supertokens.dart';

void main() {
  setUp(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    SuperTokens.isInitCalled = false;
    await AntiCSRF.removeToken();
    await IdRefreshToken.removeToken();
  });

  test("Test that requests fail when SuperTokens.initialise is not called", () {
    // TODO: Add test case
    expect(true, false);
  });

  test("Test that mutiple calls to SuperTokens.initialise work as expected",
      () {
    // TODO: Add test case
    expect(true, false);
  });

  test(
      "Test that the refresh endpoint gets set correctly when using a URL with no path",
      () {
    // TODO: Add test case
    expect(true, false);
  });

  test(
      "Test that the refresh endpoint gets set correctly when using a URL with empty path",
      () {
    // TODO: Add test case
    expect(true, false);
  });

  test(
      "Test that the refresh endpoint gets set correctly when using a URL with a valid path",
      () {
    // TODO: Add test case
    expect(true, false);
  });

  test(
      "Test that network requests without valid credentials throw session expired and do not trigger a call to the refresh endpoint",
      () {
    // TODO: Add test case
    expect(true, false);
  });

  test("Test that the library works as expected when anti-csrf is disabled",
      () {
    // TODO: Add test case
    expect(true, false);
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
}
