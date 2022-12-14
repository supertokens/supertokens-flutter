import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supertokens/supertokens.dart';
import 'package:supertokens/http.dart';

class NetworkManager {
  static NetworkManager shared = NetworkManager._init();
  static final String baseURL = "http://${"192.168.1.100"}:8080";

  http.Client client;
  Client Client;
  NetworkManager._init() {
    client = http.Client();
    Client = Client.getInstance(client);
  }

  Future<void> login() async {
    try {
      await Client.post(Uri.parse("$baseURL/login"));
      return;
    } catch (e) {
      throw e;
    }
  }

  Future<void> logout() async {
    await SuperTokens.signOut((p0) => null);
    return;
  }

  Future<String> getUserInfo() async {
    try {
      http.Response response = await Client.get(Uri.parse("$baseURL/userInfo"));
      Map<String, dynamic> json = jsonDecode(response.body);
      String name = json["name"];
      return name;
    } catch (e) {
      throw e;
    }
  }
}
