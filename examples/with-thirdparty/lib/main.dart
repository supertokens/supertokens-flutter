import 'package:flutter/material.dart';
import 'package:supertokens_flutter/supertokens.dart';
import 'package:with_thirdparty/constants.dart';
import 'package:with_thirdparty/screens/home.dart';
import 'package:with_thirdparty/screens/login.dart';
import 'package:with_thirdparty/screens/splash.dart';

void main() {
  SuperTokens.init(apiDomain: apiDomain);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      initialRoute: "/",
      routes: {
        "/": (context) => const SplashScreen(),
        "/home": (context) => const HomeScreen(),
        "/login": (context) => const LoginScreen(),
      },
    );
  }
}
