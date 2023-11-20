import 'package:flutter/material.dart';
import 'package:supertokens_flutter/supertokens.dart';
import 'package:with_thirdparty/network.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userId = "";
  String data = "";

  @override
  void initState() {
    super.initState();
    SuperTokens.getUserId().then((value) {
      setState(() {
        userId = value;
      });
    });
  }

  Future<void> signOut() async {
    await SuperTokens.signOut();
    Future.delayed(Duration.zero, () {
      Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
    });
  }

  Future<void> callAPI() async {
    try {
      var response = await NetworkManager.instance.client.get(
        "/sessioninfo",
      );
      setState(() {
        data = response.data.toString();
      });
    } catch (e) {
      print(e);
    }
  }

  Widget renderContent() {
    return Padding(
      padding: const EdgeInsets.only(
        top: 16.0,
      ),
      child: Container(
        padding: const EdgeInsets.only(
          bottom: 16,
        ),
        width: double.infinity,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFe7ffed),
              ),
              child: const Center(
                child: Text(
                  "Login successful",
                  style: TextStyle(
                    color: Color(0xFF3eb655),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(
                top: 24.0,
              ),
              child: Center(
                child: Text("Your userID is:"),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 6.0,
              ),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    width: 1,
                    color: Color(0xFFff3f33),
                  ),
                ),
                child: Text(userId),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 16,
              ),
              child: FilledButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Color(0xFFff9933)),
                ),
                onPressed: () {
                  callAPI();
                },
                child: const Text("Call API"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget renderData() {
    if (data.isEmpty) {
      return const SizedBox(
        width: 0,
        height: 0,
      );
    }

    return Expanded(
      flex: 1,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: FilledButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(Color(0xFFff9933)),
                  ),
                  onPressed: () {
                    signOut();
                  },
                  child: const Text("Sign out"),
                ),
              ),
              renderContent(),
              const SizedBox(height: 16),
              renderData(),
            ],
          ),
        ),
      ),
    );
  }
}
