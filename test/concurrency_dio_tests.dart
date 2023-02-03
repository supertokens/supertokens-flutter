import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supertokens_flutter/src/anti-csrf.dart';
import 'package:supertokens_flutter/src/dio-interceptor-wrapper.dart';
import 'package:supertokens_flutter/src/front-token.dart';
import 'package:supertokens_flutter/src/supertokens.dart';
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

  Dio setUpDio({String? url}) {
    Dio dio = Dio(
      BaseOptions(
        baseUrl: apiBasePath,
        connectTimeout: 5000,
        receiveTimeout: 500,
      ),
    );
    dio.interceptors.add(SuperTokensInterceptorWrapper(client: dio));
    return dio;
  }

  test('Refresh only get called once after multiple request (Concurrency)',
      () async {
    await SuperTokensTestUtils.startST(validity: 10);
    List<bool> results = [];
    SuperTokens.init(apiDomain: apiBasePath);
    RequestOptions req = SuperTokensTestUtils.getLoginRequestDio();
    Dio dio = setUpDio();
    var resp = await dio.fetch(req);
    if (resp.statusCode != 200) fail("Login req failed");
    List<Future> reqs = [];
    for (int i = 0; i < 300; i++) {
      dio.get("").then((resp) {
        if (resp.statusCode == 200)
          results.add(true);
        else
          results.add(false);
      });
    }
    await Future.wait(reqs);
    int refreshCount = await SuperTokensTestUtils.refreshTokenCounter();
    if (refreshCount != 1 && !results.contains(false) && results.length == 300)
      fail("");
  });
}
