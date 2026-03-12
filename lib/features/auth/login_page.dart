// lib/features/auth/login_page.dart

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  // 💡 이메일 가입 페이지로 넘어가던 onGoSignup 변수를 완전히 삭제했습니다.
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

              // 구글 로그인 버튼만 단독으로 남김
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _handleGoogleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 1,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.g_mobiledata, size: 32, color: Colors.redAccent),
                          SizedBox(width: 8),
                          Text(
                            'Google로 시작하기',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
              
              // 이메일 로그인 버튼 삭제 후 여백 조정
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}