import 'package:dio/dio.dart';
import 'package:supertokens_flutter/src/dio-interceptor-wrapper.dart';

/// Dio extension for flexible Dio instance setup.
///
/// Usage:
/// ```dart
/// import "package:supertokens_flutter/dio.dart";
///
/// final dio = Dio()
///   ..addSupertokensInterceptor()
///   ..addSentry()
///   // ...
/// ```
extension SuperTokensDioExtension on Dio {
  /// Adds the SuperTokens interceptor to the Dio instance.
  void addSupertokensInterceptor() {
    interceptors.add(SuperTokensInterceptorWrapper(client: this));
  }
}
