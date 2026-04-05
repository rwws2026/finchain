// lib/features/auth/login_page.dart

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
// ✅ 온보딩 페이지로 바로 이동하기 위해 import 추가
import '../menty/onboarding/menty_onboarding_flow_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final authService = AuthService();
    final user = await authService.signInWithGoogle();
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 취소되었거나 실패했습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.account_balance_wallet, size: 80, color: Color(0xFF00B4DB)),
              const SizedBox(height: 24),
              const Text(
                '나만의 재무 멘토를\n만나보세요',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.3),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                '더 나은 자산 관리를 위한 첫 걸음',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const Spacer(),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _handleGoogleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 1,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.g_mobiledata, size: 32, color: Colors.redAccent),
                          SizedBox(width: 8),
                          Text('Google로 시작하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
              
              const SizedBox(height: 16),

              // 🔥 관리자용 테스트 버튼 (개발 단계에서만 사용)
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MentyOnboardingFlowPage()),
                  );
                },
                child: const Text(
                  '관리자 모드로 온보딩 테스트',
                  style: TextStyle(color: Colors.grey, decoration: TextDecoration.underline),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}