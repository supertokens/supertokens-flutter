import 'package:flutter/material.dart';
import 'package:supertokens_flutter/supertokens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final hasSession = await SuperTokens.doesSessionExist();
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacementNamed(hasSession ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Checking SuperTokens session...'),
          ],
        ),
      ),
    );
  }
}
