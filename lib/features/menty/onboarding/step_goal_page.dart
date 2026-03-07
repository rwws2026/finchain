//lib/features/menty/onboarding/step_goal_page.dart
import 'package:flutter/material.dart';

class StepGoalPage extends StatefulWidget {
  const StepGoalPage({
    super.key,
    required this.initial,
    required this.saving,
    required this.onBack,
    required this.onNext,
  });

  final Map<String, dynamic> initial;
  final bool saving;
  final VoidCallback onBack;
  final Future<void> Function(Map<String, dynamic> patch) onNext;

  @override
  State<StepGoalPage> createState() => _StepGoalPageState();
}

class _StepGoalPageState extends State<StepGoalPage> {
  final _formKey = GlobalKey<FormState>();
  final _goalCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _goalCtrl.text =
        (widget.initial['savingGoal'] ?? widget.initial['goal'] ?? '') as String;
  }

  @override
  void dispose() {
    _goalCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (!_formKey.currentState!.validate()) return;

    final goal = _goalCtrl.text.trim();
    await widget.onNext({
      'savingGoal': goal,
      'goal': goal,
    });
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.saving;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            const Text(
              '저축 목표',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _goalCtrl,
              decoration: const InputDecoration(
                labelText: '저축 목표(savingGoal)',
                hintText: '예: 1년 안에 500만원 모으기',
              ),
              maxLines: 3,
              enabled: !disabled,
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return '저축 목표를 입력해줘';
                return null;
              },
            ),

            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: disabled ? null : widget.onBack,
                      child: const Text('이전'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: disabled ? null : _next,
                      child: const Text('다음'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}