import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supertokens_flutter/http.dart' as http;
import 'package:supertokens_flutter/supertokens.dart';

import 'test-utils.dart';

void main() {
  String apiBasePath = SuperTokensTestUtils.baseUrl;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await SuperTokensTestUtils.beforeAllTest();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SuperTokensTestUtils.beforeEachTest();
    SuperTokens.isInitCalled = false;
    await Future.delayed(Duration(seconds: 1), () {});
  });

  tearDownAll(() async => await SuperTokensTestUtils.afterAllTest());

  test(
      "should break out of session refresh loop after default maxRetryAttemptsForSessionRefresh value",
      () async {
    await SuperTokensTestUtils.startST();
    SuperTokens.init(apiDomain: apiBasePath);

    Uri uri = Uri.parse("$apiBasePath/login");
    var loginRes =
        await http.post(uri, body: {"userId": "supertokens-ios-tests"});

    assert(loginRes.statusCode == 200, "Login req failed");

    assert(await SuperTokensTestUtils.refreshTokenCounter() == 0,
        "refresh token count should have been 0");

    try {
      await http.get(Uri.parse("$apiBasePath/throw-401"));
      fail("Expected the request to throw an error");
    } on SuperTokensException catch (err) {
      assert(err.toString() ==
          "Received a 401 response from http://localhost:8080/throw-401. Attempted to refresh the session and retry the request with the updated session tokens 10 times, but each attempt resulted in a 401 error. The maximum session refresh limit has been reached. Please investigate your API. To increase the session refresh attempts, update maxRetryAttemptsForSessionRefresh in the config.");
    }

    assert(await SuperTokensTestUtils.refreshTokenCounter() == 10,
        "session refresh endpoint should have been called 10 times");
  });
  test(
      "should break out of session refresh loop after configured maxRetryAttemptsForSessionRefresh value",
      () async {
    await SuperTokensTestUtils.startST();
    SuperTokens.init(
        apiDomain: apiBasePath, maxRetryAttemptsForSessionRefresh: 5);

    Uri uri = Uri.parse("$apiBasePath/login");
    var loginRes =
        await http.post(uri, body: {"userId": "supertokens-ios-tests"});

    assert(loginRes.statusCode == 200, "Login req failed");

    assert(await SuperTokensTestUtils.refreshTokenCounter() == 0,
        "refresh token count should have been 0");

    try {
      await http.get(Uri.parse("$apiBasePath/throw-401"));
      fail("Expected the request to throw an error");
    } on SuperTokensException catch (err) {
      assert(err.toString() ==
          "Received a 401 response from http://localhost:8080/throw-401. Attempted to refresh the session and retry the request with the updated session tokens 5 times, but each attempt resulted in a 401 error. The maximum session refresh limit has been reached. Please investigate your API. To increase the session refresh attempts, update maxRetryAttemptsForSessionRefresh in the config.");
    }

    assert(await SuperTokensTestUtils.refreshTokenCounter() == 5,
        "session refresh endpoint should have been called 5 times");
  });

  test(
      "should not do session refresh if maxRetryAttemptsForSessionRefresh is 0",
      () async {
    await SuperTokensTestUtils.startST();
    SuperTokens.init(
        apiDomain: apiBasePath, maxRetryAttemptsForSessionRefresh: 0);

    Uri uri = Uri.parse("$apiBasePath/login");
    var loginRes =
        await http.post(uri, body: {"userId": "supertokens-ios-tests"});

    assert(loginRes.statusCode == 200, "Login req failed");

    assert(await SuperTokensTestUtils.refreshTokenCounter() == 0,
        "refresh token count should have been 0");

    try {
      await http.get(Uri.parse("$apiBasePath/throw-401"));
      fail("Expected the request to throw an error");
    } on SuperTokensException catch (err) {
      assert(err.toString() ==
          "Received a 401 response from http://localhost:8080/throw-401. Attempted to refresh the session and retry the request with the updated session tokens 0 times, but each attempt resulted in a 401 error. The maximum session refresh limit has been reached. Please investigate your API. To increase the session refresh attempts, update maxRetryAttemptsForSessionRefresh in the config.");
    }

    assert(await SuperTokensTestUtils.refreshTokenCounter() == 0,
        "session refresh endpoint should have been called 0 times");
  });
}
