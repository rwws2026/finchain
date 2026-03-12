// lib/routing/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ 새로 만든 역할 선택 페이지 import (경로 확인 필요!)
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
      builder: (context, snapshot) {
        // 1. 로그인 안 된 상태면 로그인 페이지로
        if (!snapshot.hasData) return const LoginPage();

        // 2. 로그인된 유저라면 Firestore의 유저 정보 확인
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(snapshot.data!.uid)
              .get(),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const _Splash(message: '사용자 정보를 확인 중입니다...');
            }

            final userData = userSnap.data?.data() as Map<String, dynamic>?;
            final role = userData?['role'] ?? 'none';
            final bool onboardingDone = userData?['onboardingDone'] ?? false;

            // 💡 [분기 1] 역할이 정해지지 않은 경우 (최초 가입자)
            if (role == 'none') {
              return const RoleSelectionPage();
            }

            // 💡 [분기 2] 멘티(Menty)인 경우
            if (role == 'menty') {
              // 온보딩을 안 끝냈다면 온보딩으로, 끝냈다면 멘티 홈으로
              return onboardingDone 
                  ? const MentyHomePage() 
                  : const MentyOnboardingFlowPage();
            }

            // 💡 [분기 3] 멘토(Mentor)인 경우
            if (role == 'mentor') {
              // 멘토 전용 온보딩이 있다면 여기에 비슷하게 추가
              return const MentorHomePage(); 
            }

            // 예외 상황 발생 시 (기본값)
            return const LoginPage();
          },
        );
      },
    );
  }
}

// 로딩 화면 (기존에 작성하신 클래스 활용)
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