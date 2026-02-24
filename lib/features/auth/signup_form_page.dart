//lib/features/auth/signup_form_page.dart
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

      // 이미 Auth는 생성됐는데 users 문서만 없는 케이스(=forceUid가 들어온 경우) 대응
      if (widget.forceUid != null) {
        user = FirebaseAuth.instance.currentUser!;
      } else {
        final cred = await _auth.signUpWithEmail(
          email: _email.text.trim(),
          password: _pw.text,
        );
        user = cred.user!;
      }

      if (!mounted) return;
      // ✅ 회원가입 라우트 스택 닫고 AuthGate로 돌아가기
      Navigator.of(context).popUntil((route) => route.isFirst);

      // (선택) 안내 메시지
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('가입 완료! 온보딩으로 이동합니다.')),
      );



      // ✅ 멘티/멘토 공통 기본값
      final baseData = <String, dynamic>{
        'role': widget.role,
        'name': _name.text.trim(),
        'nickname': _nickname.text.trim(),
        'email': user.email ?? _email.text.trim(),
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      };
     
      
      // ✅ 멘티: 온보딩 시작 상태를 반드시 박아준다
      if (widget.role == 'menty') {
        baseData.addAll({
          'onboardingDone': false,
          'onboardingStep': 0,
          'mentorStatus': 'none',
        });
      }

      // ✅ 멘토: 승인 대기 상태
      if (widget.role == 'mentor') {
        baseData.addAll({
          'mentorStatus': 'pending',
          // 멘토는 온보딩 플로우를 안 탄다고 가정(필드 없어도 됨)
        });
      }

      await _fs.createUser(
        uid: user.uid,
        data: baseData,
      );

      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);

      // ✅ 여기서 절대 홈/요청페이지로 Navigator 이동하지 말 것!
      // AuthGate가 authStateChanges + users/{uid} 스트림으로 분기해서
      // - menty & onboardingDone=false => 온보딩
      // - mentor & pending => pending/요청 흐름
      // 으로 알아서 보냄.

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('가입 완료! 이동 중...')),
      );
    
      // 선택 1) 그냥 두기: AuthGate가 알아서 화면 바꿈 (추천)
      // 선택 2) 현재 회원가입 화면을 닫고, 이전(SignupStart)로 돌아가기
      // Navigator.pop(context);

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
            if (_err != null) Text(_err!, style: const TextStyle(color: Colors.red)),
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