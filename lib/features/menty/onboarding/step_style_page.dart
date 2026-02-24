//lib/features/menty/onboarding/step_style_page.dart

import 'package:flutter/material.dart';

class StepStylePage extends StatefulWidget {
  const StepStylePage({
    super.key,
    required this.initial,
    required this.saving,
    required this.onBack,
    required this.onFinish,
  });

  final Map<String, dynamic> initial;
  final bool saving;
  final VoidCallback onBack;
  final Future<void> Function(Map<String, dynamic> patch) onFinish;

  @override
  State<StepStylePage> createState() => _StepStylePageState();
}

class _StepStylePageState extends State<StepStylePage> {
  bool riskHighReturn = false;
  bool wantLeverage = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    riskHighReturn = (d['riskHighReturn'] == true);
    wantLeverage = (d['wantLeverage'] == true);
  }

  Future<void> _finish() async {
    await widget.onFinish({
      'riskHighReturn': riskHighReturn,
      'wantLeverage': wantLeverage,
    });
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.saving;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Text('관리 성향', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          SwitchListTile(
            title: const Text('높은 수익/높은 리스크를 선호해요'),
            subtitle: const Text('riskHighReturn'),
            value: riskHighReturn,
            onChanged: disabled ? null : (v) => setState(() => riskHighReturn = v),
          ),
          const SizedBox(height: 8),

          SwitchListTile(
            title: const Text('레버리지를 활용해도 괜찮아요'),
            subtitle: const Text('wantLeverage'),
            value: wantLeverage,
            onChanged: disabled ? null : (v) => setState(() => wantLeverage = v),
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
                    onPressed: disabled ? null : _finish,
                    child: Text(disabled ? '저장 중...' : '완료'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}