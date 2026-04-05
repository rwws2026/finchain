// lib/routing/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../features/onboarding/role_selection_page.dart';
import '../features/auth/login_page.dart';
import '../features/menty/onboarding/menty_onboarding_flow_page.dart';
import '../features/menty/menty_home_page.dart';
import '../features/mentor/mentor_home_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // 1. 로그인 체크
        if (!authSnapshot.hasData) return const LoginPage();

        // 2. ✅ Firestore 유저 문서 실시간 감시 (Future -> Stream)
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(authSnapshot.data!.uid)
              .snapshots(), // 실시간 스냅샷 사용
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const _Splash(message: '사용자 정보를 확인 중입니다...');
            }

            if (!userSnap.hasData || !userSnap.data!.exists) {
              // 문서가 없으면 로딩 처리하거나 로그아웃 처리
              return const _Splash(message: '데이터를 생성 중입니다...');
            }

            final userData = userSnap.data!.data() as Map<String, dynamic>;
            final role = userData['role'] ?? 'none';
            final bool onboardingDone = userData['onboardingDone'] ?? false;

            // [분기 1] 역할 선택 전
            if (role == 'none') {
              return const RoleSelectionPage();
            }

            // [분기 2] 멘티(Menty)
            if (role == 'menty') {
              return onboardingDone 
                  ? const MentyHomePage() 
                  : const MentyOnboardingFlowPage();
            }

            // [분기 3] 멘토(Mentor)
            if (role == 'mentor') {
              return const MentorHomePage(); 
            }

            return const LoginPage();
          },
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash({this.message, super.key});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(message ?? '로딩 중...'),
          ],
        ),
      ),
    );
  }
}