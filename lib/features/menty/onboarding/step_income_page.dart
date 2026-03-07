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

  final _depositCtrl = TextEditingController();
  final _savingCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _fundCtrl = TextEditingController();
  final _otherCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    _mainCtrl.text = (d['mainProfit']?.toString() ?? '');
    _subCtrl.text = (d['subProfit']?.toString() ?? '');
    _depositCtrl.text = (d['deposit']?.toString() ?? '');
    _savingCtrl.text = (d['saving']?.toString() ?? '');
    _stockCtrl.text = (d['stock']?.toString() ?? '');
    _fundCtrl.text = (d['fund']?.toString() ?? '');
    _otherCtrl.text = (d['otherPortfolio']?.toString() ?? '');
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _subCtrl.dispose();
    _depositCtrl.dispose();
    _savingCtrl.dispose();
    _stockCtrl.dispose();
    _fundCtrl.dispose();
    _otherCtrl.dispose();
    super.dispose();
  }

  int _parseMoney(String text) {
    return int.tryParse(text.replaceAll(',', '').trim()) ?? 0;
  }

  Future<void> _next() async {
    if (!_formKey.currentState!.validate()) return;

    await widget.onNext({
      'mainProfit': _parseMoney(_mainCtrl.text),
      'subProfit': _parseMoney(_subCtrl.text),
      'deposit': _parseMoney(_depositCtrl.text),
      'saving': _parseMoney(_savingCtrl.text),
      'stock': _parseMoney(_stockCtrl.text),
      'fund': _parseMoney(_fundCtrl.text),
      'otherPortfolio': _parseMoney(_otherCtrl.text),
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
              '수익 및 포트폴리오',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
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

            const Text(
              '현재 재테크 포트폴리오',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            TextFormField(
              controller: _depositCtrl,
              decoration: const InputDecoration(labelText: '예금(deposit) (원)'),
              keyboardType: TextInputType.number,
              enabled: !disabled,
            ),
            const SizedBox(height: 10),

            TextFormField(
              controller: _savingCtrl,
              decoration: const InputDecoration(labelText: '적금(saving) (원)'),
              keyboardType: TextInputType.number,
              enabled: !disabled,
            ),
            const SizedBox(height: 10),

            TextFormField(
              controller: _stockCtrl,
              decoration: const InputDecoration(labelText: '주식(stock) (원)'),
              keyboardType: TextInputType.number,
              enabled: !disabled,
            ),
            const SizedBox(height: 10),

            TextFormField(
              controller: _fundCtrl,
              decoration: const InputDecoration(labelText: '펀드(fund) (원)'),
              keyboardType: TextInputType.number,
              enabled: !disabled,
            ),
            const SizedBox(height: 10),

            TextFormField(
              controller: _otherCtrl,
              decoration: const InputDecoration(labelText: '기타 포트폴리오(otherPortfolio) (원)'),
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