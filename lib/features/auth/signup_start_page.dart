//lib/features/auth/signup_start_page.dart

import 'package:flutter/material.dart';
import 'signup_form_page.dart';

class SignupStartPage extends StatelessWidget {
  final String? forceUid;
  final String? forceEmail;

  const SignupStartPage({super.key, this.forceUid, this.forceEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입 유형 선택')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('어떤 역할로 시작할까요?', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SignupFormPage(
                      role: 'menty',
                      forceUid: forceUid,
                      forceEmail: forceEmail,
                    ),
                  ),
                ),
                child: const Text('멘티로 시작'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SignupFormPage(
                      role: 'mentor',
                      forceUid: forceUid,
                      forceEmail: forceEmail,
                    ),
                  ),
                ),
                child: const Text('멘토로 시작 (심사 필요)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
