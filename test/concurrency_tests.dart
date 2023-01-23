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

  test('Refresh only get called once after multiple request (Concurrency)',
      () async {
    bool failed = false;
    await SuperTokensTestUtils.startST(validity: 10);
    List<bool> results = [];
    SuperTokens.init(apiDomain: apiBasePath);
    Request req = SuperTokensTestUtils.getLoginRequest();
    StreamedResponse streamedResp;
    streamedResp = await http.send(req);
    var resp = await Response.fromStream(streamedResp);
    if (resp.statusCode != 200) {
      failed = true;
    }
    List<Future> reqs = [];
    Uri userInfoUrl = Uri.parse("$apiBasePath/");
    for (int i = 0; i < 300; i++) {
      http.get(userInfoUrl).then((resp) {
        if (resp.statusCode == 200)
          results.add(true);
        else
          results.add(false);
      });
    }
    await Future.wait(reqs);
    int refreshCount = await SuperTokensTestUtils.refreshTokenCounter();
    if (refreshCount != 1 && !results.contains(false) && results.length == 300)
      fail("Refresh counter was incorrect");
  });
}
