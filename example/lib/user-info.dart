import 'dart:async';

import 'package:example/home.dart';
import 'package:example/network-manager.dart';
import 'package:flutter/material.dart';

class UserInfoSection extends StatefulWidget {
  final int threadNumber;
  final UserInfoCommunicator communicator;

  UserInfoSection(this.threadNumber, this.communicator);

  @override
  State<StatefulWidget> createState() {
    return _UserInfoSectionState();
  }
}

class _UserInfoSectionState extends State<UserInfoSection> {
  int numberOfAPICallsMade;

  @override
  void initState() {
    numberOfAPICallsMade = 0;
    super.initState();
    startFetch();
  }

  Future<void> startFetch() async {
    String name = await NetworkManager.shared.getUserInfo();
    setState(() {
      numberOfAPICallsMade++;
    });
    widget.communicator.updateUserName(name);
    Future.delayed(Duration(seconds: 1), () {
      startFetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.width;
    return Container(
      margin: EdgeInsets.all(20),
      height: screenHeight * 0.4,
      decoration: BoxDecoration(
        border: Border.all(
          width: 1,
          color: Colors.white,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                "Thread ${widget.threadNumber}",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              "Number of API calls made\n$numberOfAPICallsMade",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
