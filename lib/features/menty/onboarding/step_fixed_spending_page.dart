//lib/features/menty/onboarding/step_fixed_spending_page.dart

import 'package:flutter/material.dart';

class StepFixedSpendingPage extends StatefulWidget {
  const StepFixedSpendingPage({
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
  State<StepFixedSpendingPage> createState() => _StepFixedSpendingPageState();
}

class _StepFixedSpendingPageState extends State<StepFixedSpendingPage> {
  final _formKey = GlobalKey<FormState>();
  final _fixedCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fixedCtrl.text = (widget.initial['fixedSpending']?.toString() ?? '');
  }

  @override
  void dispose() {
    _fixedCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (!_formKey.currentState!.validate()) return;

    final fixed = int.tryParse(_fixedCtrl.text.replaceAll(',', '').trim()) ?? 0;
    await widget.onNext({'fixedSpending': fixed});
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
            const Text('고정지출', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            TextFormField(
              controller: _fixedCtrl,
              decoration: const InputDecoration(labelText: '월 고정지출(fixedSpending) (원)'),
              keyboardType: TextInputType.number,
              enabled: !disabled,
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return '고정지출을 입력해줘 (없으면 0)';
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