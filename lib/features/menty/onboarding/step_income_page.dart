//lib/features/menty/onboarding/step_income_page.dart

import 'package:flutter/material.dart';

class StepIncomePage extends StatefulWidget {
  const StepIncomePage({
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
  State<StepIncomePage> createState() => _StepIncomePageState();
}

class _StepIncomePageState extends State<StepIncomePage> {
  final _formKey = GlobalKey<FormState>();
  final _mainCtrl = TextEditingController();
  final _subCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    _mainCtrl.text = (d['mainProfit']?.toString() ?? '');
    _subCtrl.text = (d['subProfit']?.toString() ?? '');
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _subCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (!_formKey.currentState!.validate()) return;

    final main = int.tryParse(_mainCtrl.text.replaceAll(',', '').trim()) ?? 0;
    final sub = int.tryParse(_subCtrl.text.replaceAll(',', '').trim()) ?? 0;

    await widget.onNext({
      'mainProfit': main,
      'subProfit': sub,
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
            const Text('수익정보', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            TextFormField(
              controller: _mainCtrl,
              decoration: const InputDecoration(labelText: '주 수익(mainProfit) (원)'),
              keyboardType: TextInputType.number,
              enabled: !disabled,
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return '주 수익을 입력해줘';
                return null;
              },
            ),
            const SizedBox(height: 10),

            TextFormField(
              controller: _subCtrl,
              decoration: const InputDecoration(labelText: '부 수익(subProfit) (원)'),
              keyboardType: TextInputType.number,
              enabled: !disabled,
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