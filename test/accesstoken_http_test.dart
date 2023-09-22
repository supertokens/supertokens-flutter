import 'dart:convert';
import 'dart:ffi';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supertokens_flutter/http.dart' as http;
import 'package:supertokens_flutter/src/anti-csrf.dart';
import 'package:supertokens_flutter/src/front-token.dart';
import 'package:supertokens_flutter/src/utilities.dart';
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

  test("should return the appropriate access token payload", () async {
    await SuperTokensTestUtils.startST(validity: 3);
    SuperTokens.init(apiDomain: apiBasePath);
    Request req = SuperTokensTestUtils.getLoginRequest();
    StreamedResponse streamedResp;
    streamedResp = await http.send(req);
    var resp = await Response.fromStream(streamedResp);
    if (resp.statusCode != 200) {
      fail("login failed");
    }

    var payload = await SuperTokens.getAccessTokenPayloadSecurely();
    

    if (await SuperTokensTestUtils.checkIfV3AccessTokenIsSupported()) {
      var expectedKeys = [
        "sub",
        "exp",
        "iat",
        "sessionHandle",
        "refreshTokenHash1",
        "parentRefreshTokenHash1",
        "antiCsrfToken",
        "iss"
      ];

      if (payload["tId"] != null) {
        expectedKeys.add("tId");
      }

      if (payload["rsub"] != null) {
        expectedKeys.add("rsub");
      }

      assert(payload.length == expectedKeys.length);
      for (var key in payload.keys) {
        assert(expectedKeys.contains(key));
      }
    } else {
      assert(payload.length == 0);
    }
  });

  test("should be able to refresh a session started w/ CDI 2.18", () async {
    await SuperTokensTestUtils.startST(validity: 3);
    SuperTokens.init(apiDomain: apiBasePath);
    Request req = SuperTokensTestUtils.getLogin218Request();
    StreamedResponse streamedResp;
    streamedResp = await http.send(req);
    var resp = await Response.fromStream(streamedResp);
    if (resp.statusCode != 200) {
      fail("login failed");
    }

    var payload = await SuperTokens.getAccessTokenPayloadSecurely();
    assert(payload.length == 1);
    assert(payload["asdf"] == 1);

    await SuperTokens.attemptRefreshingSession();

    if (await SuperTokensTestUtils.checkIfV3AccessTokenIsSupported()) {
      var v3Payload = await SuperTokens.getAccessTokenPayloadSecurely();
      var expectedKeys = [
        "sub",
        "exp",
        "iat",
        "sessionHandle",
        "refreshTokenHash1",
        "parentRefreshTokenHash1",
        "antiCsrfToken",
        "asdf"
      ];

      if (v3Payload["tId"] != null) {
        expectedKeys.add("tId");
      }

      if (v3Payload["rsub"] != null) {
        expectedKeys.add("rsub");
      }

      assert(v3Payload.length == expectedKeys.length);
      for (var key in v3Payload.keys) {
        assert(expectedKeys.contains(key));
      }
    } else {
      var v2Payload = await SuperTokens.getAccessTokenPayloadSecurely();
      assert(v2Payload.length == 1);
      assert(v2Payload["asdf"] == 1);
    }
  });
}