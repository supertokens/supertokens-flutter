import 'dart:async';

import 'package:example/network-manager.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class LoginScreen extends StatelessWidget {
  bool isLoggingIn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: Color(0xFF141414)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Image.asset(
              "images/supertokens.png",
              height: 100,
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 40,
                right: 40,
              ),
              child: Text(
                "Session Management made secure, open source and easy to use.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: GestureDetector(
                onTap: () {
                  login(context);
                },
                child: Container(
                  padding: EdgeInsets.only(
                    top: 6,
                    bottom: 6,
                    left: 12,
                    right: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xFFff9933),
                  ),
                  child: Text(
                    "Login",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> login(BuildContext context) async {
    if (isLoggingIn) {
      return;
    }

    isLoggingIn = true;

    try {
      await NetworkManager.shared.login();
      Navigator.of(context).pushNamed("/home");
      return;
    } catch (e) {
      // TODO: show toast
    } finally {
      isLoggingIn = false;
    }
  }
}
