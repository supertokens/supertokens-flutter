import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supertokens/supertokens.dart';

class NetworkManager {
  static NetworkManager shared = NetworkManager._init();
  static final String baseURL = "http://${"192.168.1.100"}:8080";

  http.Client client;
  SuperTokensHttpClient superTokensHttpClient;
  NetworkManager._init() {
    client = http.Client();
    superTokensHttpClient = SuperTokensHttpClient.getInstance(client);
  }

  Future<void> login() async {
    try {
      await superTokensHttpClient.post(Uri.parse("$baseURL/login"));
      return;
    } catch (e) {
      throw e;
    }
  }

  Future<void> logout() async {
    await superTokensHttpClient.post(Uri.parse("$baseURL/logout"));
    return;
  }

  Future<String> getUserInfo() async {
    try {
      http.Response response =
          await superTokensHttpClient.get(Uri.parse("$baseURL/userInfo"));
      Map<String, dynamic> json = jsonDecode(response.body);
      String name = json["name"];
      return name;
    } catch (e) {
      throw e;
    }
  }
}
