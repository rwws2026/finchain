//lib/features/menty/onboarding/menty_onboarding_flow_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../services/firestore_service.dart';
import 'step_basic_info_page.dart';
import 'step_income_page.dart';
import 'step_fixed_spending_page.dart';
import 'step_goal_page.dart';
import 'step_style_page.dart';

class MentyOnboardingFlowPage extends StatefulWidget {
  const MentyOnboardingFlowPage({super.key});

  @override
  State<MentyOnboardingFlowPage> createState() => _MentyOnboardingFlowPageState();
}

class _MentyOnboardingFlowPageState extends State<MentyOnboardingFlowPage> {
  final _svc = FirestoreService.instance;

  bool _loading = true;
  bool _saving = false;

  int _step = 0; // 0~4
  Map<String, dynamic> _userData = {};

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
  final doc = await _svc.getUserDoc(_uid);
  final data = doc.data() ?? {};

  final done = (data['onboardingDone'] == true);
  if (done) {
    if (mounted) {
      setState(() => _loading = false);
    }
    return; // AuthGate가 홈으로 보낼 것
  }

  final step = (data['onboardingStep'] is int) ? data['onboardingStep'] as int : 0;
  if (!mounted) return;

  setState(() {
    _userData = data;
    _step = step.clamp(0, 4);
    _loading = false;
  });
}

  Future<void> _saveStep({
  required int nextStep,
  required Map<String, dynamic> patch,
}) async {
  setState(() => _saving = true);

  try {
    await _svc.updateUserMerge(_uid, {
      ...patch,
      'onboardingStep': nextStep,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    if (!mounted) return;
    setState(() {
      _userData = {..._userData, ...patch, 'onboardingStep': nextStep};
      _step = nextStep.clamp(0, 4);
    });
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('저장 실패: $e')),
    );
  } finally {
    if (mounted) setState(() => _saving = false);
  }
}

  Future<void> _finish(Map<String, dynamic> patch) async {
    setState(() => _saving = true);
    try {
      await _svc.updateUserMerge(_uid, {
        ...patch,
        'onboardingDone': true,
        'onboardingStep': 5,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      // ✅ AuthGate가 stream으로 onboardingDone을 감지하고 홈으로 보내줌
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _back() {
    if (_step <= 0) return;
    setState(() => _step -= 1);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pages = <Widget>[
      StepBasicInfoPage(
        initial: _userData,
        saving: _saving,
        onNext: (patch) => _saveStep(nextStep: 1, patch: patch),
      ),
      StepIncomePage(
        initial: _userData,
        saving: _saving,
        onBack: _back,
        onNext: (patch) => _saveStep(nextStep: 2, patch: patch),
      ),
      StepFixedSpendingPage(
        initial: _userData,
        saving: _saving,
        onBack: _back,
        onNext: (patch) => _saveStep(nextStep: 3, patch: patch),
      ),
      StepGoalPage(
        initial: _userData,
        saving: _saving,
        onBack: _back,
        onNext: (patch) => _saveStep(nextStep: 4, patch: patch),
      ),
      StepStylePage(
        initial: _userData,
        saving: _saving,
        onBack: _back,
        onFinish: (patch) => _finish(patch),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('멘티 온보딩'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          _TopProgress(step: _step, total: 5),
          Expanded(child: pages[_step]),
        ],
      ),
    );
  }
}

class _TopProgress extends StatelessWidget {
  const _TopProgress({required this.step, required this.total});
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final value = (step + 1) / total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('단계 ${step + 1} / $total'),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: value),
        ],
      ),
    );
  }
}