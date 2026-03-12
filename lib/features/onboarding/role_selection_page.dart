//lib/features/onboarding/role_selection_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  bool _isLoading = false;

  // Firestore에 선택한 역할을 저장하는 함수
  Future<void> _updateRole(String role) async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 1. Firestore의 해당 유저 문서 업데이트
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'role': role,
        });

        // 2. 성공 시 다음 온보딩 단계로 이동 (기존 코드가 있다면 그곳으로)
        if (mounted) {
          // TODO: 정보 입력 페이지(2단계)로 이동하는 로직을 여기에 넣으세요.
          // Navigator.push(context, MaterialPageRoute(builder: (_) => const InfoInputPage()));
          print('선택된 역할: $role');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('역할 저장 중 오류가 발생했습니다: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            children: [
              const Text(
                '반갑습니다!\n어떤 목적으로 이용하시나요?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // 멘티 선택 카드
              _buildRoleCard(
                title: '멘티로 시작하기',
                subtitle: '전문가에게 자산 관리 조언을 받고 싶어요',
                icon: Icons.person_search,
                color: const Color(0xFF00B4DB),
                onTap: () => _updateRole('menty'),
              ),
              
              const SizedBox(height: 20),
              
              // 멘토 선택 카드
              _buildRoleCard(
                title: '멘토로 참여하기',
                subtitle: '나의 금융 지식을 나누고 수익을 창출해요',
                icon: Icons.psychology,
                color: const Color(0xFF0083B0),
                onTap: () => _updateRole('mentor'),
              ),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: CircularProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 역할 선택용 카드 위젯 빌더
  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.5), width: 2),
          borderRadius: BorderRadius.circular(16),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}