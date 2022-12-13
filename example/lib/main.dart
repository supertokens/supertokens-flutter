// Flutter sdk imports
import 'package:example/home.dart';
import 'package:flutter/material.dart';
// Local imports
import 'package:example/login.dart';
import 'package:supertokens/supertokens.dart';

import 'network-manager.dart';

void main() {
  SuperTokens.init(
    apiDomain:
        "https://41f15da1602f11edb6b30fbcd81a03c2-us-east-1.aws.supertokens.io:3573",
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SuperTokens Flutter Demo',
      debugShowCheckedModeBanner: false,
      routes: {
        "/": (context) => LoginScreen(),
        "/home": (context) => HomeScreen(),
      },
    );
  }
}
