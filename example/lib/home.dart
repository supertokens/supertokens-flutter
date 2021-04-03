import 'dart:async';

import 'package:example/network-manager.dart';
import 'package:flutter/material.dart';
import 'package:example/user-info.dart';

class UserInfoCommunicator {
  void updateUserName(String name) {}
}

class HomeScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _HomeScreenState();
  }
}

class _HomeScreenState extends State<HomeScreen>
    implements UserInfoCommunicator {
  final List<int> list = List<int>.generate(10, (index) => index + 1);
  bool isLoggingOut = false;
  String userName = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Color(0xFF141414),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 20,
                top: 40,
                bottom: 20,
              ),
              child: Align(
                alignment: Alignment.topLeft,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.45,
                  child: Text(
                    "Logged in as: $userName",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                right: 20,
                top: 40,
                bottom: 20,
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () {
                    logout(context);
                  },
                  child: Container(
                    child: Text("Logout",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        )),
                    color: Color(0xFFff9933),
                    padding: EdgeInsets.only(
                      top: 6,
                      bottom: 6,
                      left: 12,
                      right: 12,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                child: SingleChildScrollView(
                  child: Column(
                    children:
                        list.map((e) => UserInfoSection(e, this)).toList(),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> logout(BuildContext context) async {
    if (isLoggingOut) {
      return;
    }

    isLoggingOut = true;

    try {
      await NetworkManager.shared.logout();
    } catch (e) {
      // ignoring
    } finally {
      isLoggingOut = false;
    }

    Navigator.of(context).pushNamed("/");
  }

  @override
  void updateUserName(String name) {
    if (userName != "" && name != userName) {
      // TODO: show toast for user name changed
    }

    setState(() {
      userName = name;
    });
  }
}
