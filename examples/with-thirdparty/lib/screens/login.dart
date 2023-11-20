import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart'
    hide AuthorizationRequest;
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
        serverClientId: "GOOGLE_WEB_CLIENT_ID",
        scopes: [
          'email',
        ],
      );
    } else {
      googleSignIn = GoogleSignIn(
        clientId: "GOOGLE_IOS_CLIENT_ID",
        serverClientId: "GOOGLE_WEB_CLIENT_ID",
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
    }
  }

  Future<void> loginWithGithub() async {
    FlutterAppAuth appAuth = FlutterAppAuth();

    var authResult = await appAuth.authorize(AuthorizationRequest(
      "GITHUB_CLIENT_ID",
      "com.supertokens.supertokensexample://oauthredirect",
      serviceConfiguration: const AuthorizationServiceConfiguration(
        authorizationEndpoint: "https://github.com/login/oauth/authorize",
        tokenEndpoint: "https://github.com/login/oauth/access_token",
      ),
    ));

    if (authResult == null) {
      print("Github login failed");
      return;
    }

    if (authResult.authorizationCode == null) {
      print("Github did not return an authorization code");
      return;
    }

    try {
      var result = await NetworkManager.instance.client.post(
        "/auth/signinup",
        data: {
          "thirdPartyId": "github",
          "redirectURIInfo": {
            "redirectURIOnProviderDashboard": "",
            "redirectURIQueryParams": {
              "code": authResult.authorizationCode,
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
      print("Github sign in failed");
    }
  }

  Future<void> loginWithApple() async {
    var credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email]);

    try {
      var result = await NetworkManager.instance.client.post(
        "/auth/signinup",
        data: {
          "thirdPartyId": "apple",
          "redirectURIInfo": {
            "redirectURIOnProviderDashboard": "",
            "redirectURIQueryParams": {
              "code": credential.authorizationCode,
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
      print("Apple sign in failed");
    }
  }

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
            Platform.isIOS
                ? TextButton(
                    onPressed: () {
                      loginWithApple();
                    },
                    child: const Text("Continue with Apple"),
                  )
                : const SizedBox(
                    height: 0,
                    width: 0,
                  ),
          ],
        ),
      ),
    );
  }
}
