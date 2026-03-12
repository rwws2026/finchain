// lib/features/menty/onboarding/menty_onboarding_flow_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 각 단계 페이지 import
import 'step_basic_info_page.dart';
import 'step_income_page.dart';
import 'step_fixed_spending_page.dart';
import 'step_goal_page.dart';
import 'step_style_page.dart';
import '../menty_home_page.dart'; // 홈 화면 경로 확인 필요

class MentyOnboardingFlowPage extends StatefulWidget {
  const MentyOnboardingFlowPage({super.key});

  @override
  State<MentyOnboardingFlowPage> createState() => _MentyOnboardingFlowPageState();
}

class _MentyOnboardingFlowPageState extends State<MentyOnboardingFlowPage> {
  // 1. 모든 단계의 데이터를 통합 관리할 바구니
  final Map<String, dynamic> _allData = {};
  
  // 2. 현재 진행 단계 (0부터 시작)
  int _currentStep = 0;

  // 3. 최종 데이터 저장 및 종료 함수
  Future<void> _saveAllData() async {
    // 로딩 표시 시작
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Firestore에 모든 온보딩 데이터 업데이트
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          ..._allData,
          'onboardingDone': true,          // 온보딩 완료 여부
          'updatedAt': FieldValue.serverTimestamp(), // 업데이트 시간
        });

        // 로딩 다이얼로그 닫기
        if (mounted) Navigator.of(context).pop();

        // 멘티 홈 화면으로 이동 (뒤로가기 불가하도록 처리)
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MentyHomePage()),
          );
        }
      }
    } catch (e) {
      // 에러 발생 시 로딩 다이얼로그 닫고 알림
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 저장 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 단계별 위젯 할당 (총 5단계: 0~4)
    Widget currentWidget;

    switch (_currentStep) {
      case 0:
        currentWidget = StepBasicInfoPage(
          data: _allData, 
          onNext: () => setState(() => _currentStep++),
        );
        break;
      case 1:
        currentWidget = StepIncomePage(
          data: _allData, 
          onNext: () => setState(() => _currentStep++),
        );
        break;
      case 2:
        currentWidget = StepFixedSpendingPage(
          data: _allData, 
          onNext: () => setState(() => _currentStep++),
        );
        break;
      case 3:
        currentWidget = StepGoalPage(
          data: _allData, 
          onNext: () => setState(() => _currentStep++),
        );
        break;
      case 4:
        currentWidget = StepStylePage(
          data: _allData, 
          onFinish: _saveAllData, // 마지막 단계에서 저장 함수 호출
        );
        break;
      default:
        currentWidget = const Center(child: Text('알 수 없는 단계입니다.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('멘티 온보딩 (${_currentStep + 1}/5)'),
        centerTitle: true,
        // 첫 단계가 아닐 때만 뒤로가기 버튼 표시
        leading: _currentStep > 0 
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20), 
              onPressed: () => setState(() => _currentStep--),
            )
          : null,
      ),
      body: SafeArea(
        child: currentWidget,
      ),
    );
  }
}