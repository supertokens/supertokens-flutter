import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../network.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'demo@example.com');
  final _passwordController = TextEditingController(text: 'Password123!');
  bool _isSubmitting = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(String path) async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
      _message = null;
    });

    try {
      final response = await NetworkManager.instance.client.post(
        path,
        data: {
          'formFields': [
            {'id': 'email', 'value': _emailController.text.trim()},
            {'id': 'password', 'value': _passwordController.text},
          ],
        },
      );

      final data = response.data;
      if (response.statusCode == 200 &&
          data is Map<String, dynamic> &&
          data['status'] == 'OK') {
        if (!mounted) {
          return;
        }
        Navigator.of(context).pushReplacementNamed('/home');
        return;
      }

      setState(() {
        _message = _extractMessage(data);
      });
    } on DioException catch (error) {
      setState(() {
        _message = error.message ?? 'Request failed';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _extractMessage(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return 'Unexpected response: $data';
    }

    if (data['status'] == 'FIELD_ERROR' && data['formFields'] is List) {
      final fields = (data['formFields'] as List)
          .whereType<Map<String, dynamic>>()
          .map((entry) => '${entry['id']}: ${entry['error']}')
          .join('\n');
      if (fields.isNotEmpty) {
        return fields;
      }
    }

    if (data['status'] == 'WRONG_CREDENTIALS_ERROR') {
      return 'Incorrect email or password';
    }

    if (data['status'] == 'SIGN_UP_NOT_ALLOWED' ||
        data['status'] == 'SIGN_IN_NOT_ALLOWED') {
      return data['reason']?.toString() ?? data['status'].toString();
    }

    return data['message']?.toString() ??
        data['status']?.toString() ??
        'Request failed';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dart 3 Repro Login')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'EmailPassword demo',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This app signs users up and in with the EmailPassword recipe. The backend uses try.supertokens.com.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recipe: EmailPassword'),
                        SizedBox(height: 4),
                        Text('SuperTokens core: https://try.supertokens.com'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _message!,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed:
                        _isSubmitting ? null : () => _submit('/auth/signup'),
                    child: const Text('Sign up'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed:
                        _isSubmitting ? null : () => _submit('/auth/signin'),
                    child: const Text('Sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
