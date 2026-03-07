import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class SignupFormPage extends StatefulWidget {
  final String role; // 'menty' | 'mentor'
  final String? forceUid;
  final String? forceEmail;

  const SignupFormPage({
    super.key,
    required this.role,
    this.forceUid,
    this.forceEmail,
  });

  @override
  State<SignupFormPage> createState() => _SignupFormPageState();
}

class _SignupFormPageState extends State<SignupFormPage> {
  final _auth = AuthService();
  final _fs = FirestoreService();

  final _email = TextEditingController();
  final _pw = TextEditingController();
  final _name = TextEditingController();
  final _nickname = TextEditingController();

  bool _loading = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    if (widget.forceEmail != null && widget.forceEmail!.isNotEmpty) {
      _email.text = widget.forceEmail!;
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _pw.dispose();
    _name.dispose();
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _err = null;
    });

    try {
      User user;

      if (widget.forceUid != null) {
        user = FirebaseAuth.instance.currentUser!;
      } else {
        final cred = await _auth.signUpWithEmail(
          email: _email.text.trim(),
          password: _pw.text,
        );
        user = cred.user!;
      }

      final baseData = <String, dynamic>{
        'role': widget.role,
        'name': _name.text.trim(),
        'nickname': _nickname.text.trim(),
        'email': user.email ?? _email.text.trim(),
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      };

      if (widget.role == 'menty') {
        baseData.addAll({
          'onboardingDone': false,
          'onboardingStep': 0,
          'mentorStatus': 'none',
          'mainProfit': 0,
          'subProfit': 0,
          'deposit': 0,
          'saving': 0,
          'stock': 0,
          'fund': 0,
          'otherPortfolio': 0,
          'fixedSpending': 0,
          'savingGoal': '',
          'birthDate': '',
          'phone': '',
        });
      }

      if (widget.role == 'mentor') {
        baseData.addAll({
          'mentorStatus': 'approved',
        });
      }

      await _fs.createUser(
        uid: user.uid,
        data: baseData,
      );

      if (widget.role == 'mentor') {
        await _fs.createOrUpdateMentorProfile(
          uid: user.uid,
          data: {
            'name': _name.text.trim(),
            'nickname': _nickname.text.trim(),
            'headline': '',
            'bio': '',
            'specialty': '',
            'consultingField': '',
            'averageRating': 0.0,
            'recommendCount': 0,
            'consultCount': 0,
            'score': 0.0,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          },
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('가입 완료! 이동 중...')),
      );

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMentor = widget.role == 'mentor';

    return Scaffold(
      appBar: AppBar(title: Text('회원가입 (${isMentor ? '멘토' : '멘티'})')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: '이메일'),
            ),
            if (widget.forceUid == null)
              TextField(
                controller: _pw,
                decoration: const InputDecoration(labelText: '비밀번호'),
                obscureText: true,
              ),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: '이름'),
            ),
            TextField(
              controller: _nickname,
              decoration: const InputDecoration(labelText: '닉네임'),
            ),
            const SizedBox(height: 12),
            if (_err != null)
              Text(_err!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('가입 완료'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}