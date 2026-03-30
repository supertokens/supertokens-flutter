import 'package:flutter/material.dart';
import 'package:supertokens_flutter/supertokens.dart';

import '../network.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userId = 'Loading...';
  String _apiResult = 'Tap "Call /sessioninfo" to verify the session.';

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    try {
      final userId = await SuperTokens.getUserId();
      if (!mounted) {
        return;
      }
      setState(() {
        _userId = userId;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _userId = 'Failed to read user id: $error';
      });
    }
  }

  Future<void> _callSessionInfo() async {
    try {
      final response = await NetworkManager.instance.client.get('/sessioninfo');
      if (!mounted) {
        return;
      }
      setState(() {
        _apiResult = response.data.toString();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _apiResult = 'Call failed: $error';
      });
    }
  }

  Future<void> _signOut() async {
    await SuperTokens.signOut();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Verified'),
        actions: [
          TextButton(
            onPressed: _signOut,
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current user id',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SelectableText(_userId),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _callSessionInfo,
                child: const Text('Call /sessioninfo'),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: SelectableText(_apiResult),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
