import 'package:dio/dio.dart';
import 'package:supertokens_flutter/dio.dart';

import 'constants.dart';

class NetworkManager {
  NetworkManager._();

  static NetworkManager? _instance;

  static NetworkManager get instance {
    _instance ??= NetworkManager._().._initClient();
    return _instance!;
  }

  late final Dio client;

  void _initClient() {
    client = Dio(
      BaseOptions(
        baseUrl: apiDomain,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    client.addSupertokensInterceptor();
  }
}
