import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:supertokens/supertokens.dart';

class NetworkManager {
  static NetworkManager shared = NetworkManager._init();
  static final String baseURL = "http://${"192.168.0.1"}:8080/api";

  http.Client client;
  SuperTokensHttpClient superTokensHttpClient;
  NetworkManager._init() {
    client = http.Client();
    superTokensHttpClient = SuperTokensHttpClient(client);
  }

  Future<void> login() async {
    await superTokensHttpClient.post(Uri.parse("$baseURL/login"));
    return;
  }

  Future<void> logout() async {
    await superTokensHttpClient.post(Uri.parse("$baseURL/logout"));
    return;
  }

  Future<String> getUserInfo() async {
    await superTokensHttpClient.get(Uri.parse("$baseURL/userInfo"));
    // TODO: return name
    return "";
  }
}
