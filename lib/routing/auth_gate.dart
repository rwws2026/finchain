//lib/routing/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firestore_service.dart';

import '../features/auth/login_page.dart';
import '../features/auth/signup_start_page.dart';

import '../features/menty/onboarding/menty_onboarding_flow_page.dart';
import '../features/menty/menty_home_page.dart';

import '../features/mentor/mentor_home_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _fs = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }

        final user = authSnap.data;

        if (user == null) {
          return LoginPage(
            onGoSignup: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SignupStartPage()),
              );
            },
          );
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _fs.userStream(user.uid),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const _Splash();
            }
            if (!userSnap.hasData || !userSnap.data!.exists) {
              return const _Splash(message: '프로필 생성 중...');
            }

            final data = userSnap.data!.data() ?? {};
            final role = (data['role'] ?? '') as String;

            if (role == 'menty') {
              final done = (data['onboardingDone'] == true);
              if (!done) return const MentyOnboardingFlowPage();
              return const MentyHomePage();
            }

            if (role == 'mentor') {
              return const MentorHomePage();
            }

            return const SignupStartPage();
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