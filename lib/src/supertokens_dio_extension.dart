import 'package:dio/dio.dart';
import 'package:supertokens_flutter/src/dio-interceptor-wrapper.dart';

extension SuperTokensDioExtension on Dio {
    void addSupertokensInterceptor() {
      this.interceptors.add(SuperTokensInterceptorWrapper(client: this));
    }
}