import 'package:dio/dio.dart';
import 'package:supertokens_flutter/src/dio-interceptor-wrapper.dart';

/// Mixin for easy Dio instance setup.
///
/// Usage:
/// ```dart
///
/// final dio = Dio()
///   ..addSupertokensInterceptor()
///   ..addSentry()
///   // ...
/// ```
extension SuperTokensDioExtension on Dio {
  /// Adds the SuperTokens interceptor to the Dio instance.
  void addSupertokensInterceptor() {
    this.interceptors.add(SuperTokensInterceptorWrapper(client: this));
  }
}
