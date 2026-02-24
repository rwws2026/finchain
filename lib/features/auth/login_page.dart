//lib/features/auth/login_page.dart

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onGoSignup;
  const LoginPage({super.key, required this.onGoSignup});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = AuthService();
  final _email = TextEditingController();
  final _pw = TextEditingController();
  bool _loading = false;
  String? _err;

  @override
  void dispose() {
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      await _auth.signInWithEmail(email: _email.text.trim(), password: _pw.text);
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PinChain 로그인')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _email, decoration: const InputDecoration(labelText: '이메일')),
            TextField(
              controller: _pw,
              decoration: const InputDecoration(labelText: '비밀번호'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            if (_err != null) Text(_err!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('로그인'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: widget.onGoSignup,
              child: const Text('회원가입 (멘티/멘토 선택)'),
            ),
            const SizedBox(height: 8),
            const Text('멘토이신가요? 가입 후 심사(서류 제출)가 필요합니다.'),
          ],
        ),
      ),
    );
  }
}
