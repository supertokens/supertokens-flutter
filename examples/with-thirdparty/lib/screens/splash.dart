import 'package:flutter/material.dart';
import 'package:supertokens_flutter/supertokens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  void checkForAuthAndNavigate() {
    SuperTokens.doesSessionExist().then((value) {
      if (value) {
        Navigator.pushReplacementNamed(
          context,
          "/home",
        );
      } else {
        Navigator.pushReplacementNamed(
          context,
          "/login",
        );
      }
    });
  }

  @override
  void initState() {
    checkForAuthAndNavigate();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "SuperTokens Example",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
