import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:with_thirdparty/network.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Future<void> loginWithGoogle() async {
    GoogleSignIn googleSignIn;

    if (Platform.isAndroid) {
      googleSignIn = GoogleSignIn(
        serverClientId:
            "580674050145-shkfcshav895dsoj61vuf6s5iml27glr.apps.googleusercontent.com",
        scopes: [
          'email',
        ],
      );
    } else {
      googleSignIn = GoogleSignIn(
        clientId:
            "580674050145-9sik7jl4hh9rtrng6rjpgkgqk6m8kv77.apps.googleusercontent.com",
        serverClientId:
            "580674050145-shkfcshav895dsoj61vuf6s5iml27glr.apps.googleusercontent.com",
        scopes: [
          'email',
        ],
      );
    }

    if (googleSignIn.currentUser != null) {
      // This cleans up the current user from the google sign in package if there is any active user
      await googleSignIn.signOut();
    }

    try {
      GoogleSignInAccount? account = await googleSignIn.signIn();

      if (account == null) {
        print("Google sign in was aborted");
        return;
      }

      String? authCode = account.serverAuthCode;

      if (authCode == null) {
        print("Google sign in did not return a server auth code");
        return;
      }

      var result = await NetworkManager.instance.client.post(
        "/auth/signinup",
        data: {
          "thirdPartyId": "google",
          "redirectURIInfo": {
            "redirectURIOnProviderDashboard": "",
            "redirectURIQueryParams": {
              "code": authCode,
            },
          },
        },
      );

      if (result.statusCode == 200) {
        Future.delayed(Duration.zero, () {
          Navigator.of(context).pushReplacementNamed("/home");
        });
      }
    } on DioException {
      print("Google sign in failed");
    } on Exception catch (e) {
      print(e);
    }
  }

  Future<void> loginWithGithub() async {}

  Future<void> loginWithApple() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () {
                loginWithGoogle();
              },
              child: const Text("Continue with Google"),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                loginWithGithub();
              },
              child: const Text("Continue with Github"),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                loginWithApple();
              },
              child: const Text("Continue with Apple"),
            ),
          ],
        ),
      ),
    );
  }
}
