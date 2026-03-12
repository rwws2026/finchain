//lib/features/menty/onboarding/step_goal_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class StepGoalPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onNext;

  const StepGoalPage({super.key, required this.data, required this.onNext});

  @override
  State<StepGoalPage> createState() => _StepGoalPageState();
}

class _StepGoalPageState extends State<StepGoalPage> {
  final _formKey = GlobalKey<FormState>();
  
  // 초기값 설정 (데이터가 없으면 기본값 12개월)
  double _currentMonths = 12;

  @override
  void initState() {
    super.initState();
    // 기존 데이터가 있다면 해당 값으로 슬라이더 초기화
    if (widget.data['goalMonths'] != null) {
      _currentMonths = (widget.data['goalMonths'] as int).toDouble();
    } else {
      widget.data['goalMonths'] = 12; // 기본값 저장
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '목표를 세워볼까요?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '얼마를 언제까지 모으고 싶으신가요?',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            // 1. 기간 설정 (Slider)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('목표 기간', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text(
                  '${_currentMonths.round()}개월 (${(_currentMonths / 12).toStringAsFixed(1)}년)',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00B4DB)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF00B4DB),
                thumbColor: const Color(0xFF00B4DB),
                overlayColor: const Color(0xFF00B4DB).withOpacity(0.2),
                valueIndicatorTextStyle: const TextStyle(color: Colors.white),
              ),
              child: Slider(
                value: _currentMonths,
                min: 1,
                max: 60,
                divisions: 59, // 1개월 단위로 딱딱 끊기게 설정
                label: '${_currentMonths.round()}개월',
                onChanged: (value) {
                  setState(() {
                    _currentMonths = value;
                    widget.data['goalMonths'] = value.round();
                  });
                },
              ),
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1개월', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text('60개월', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            
            const SizedBox(height: 48),

            // 2. 금액 입력 (3자리 콤마)
            const Text('목표 금액', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: widget.data['goalAmount'],
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _CurrencyInputFormatter(),
              ],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: '예: 100,000,000',
                suffixText: '원',
                border: UnderlineInputBorder(),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF00B4DB), width: 2),
                ),
              ),
              onChanged: (v) => widget.data['goalAmount'] = v,
              validator: (v) => (v == null || v.isEmpty) ? '목표 금액을 입력해주세요.' : null,
            ),

            const SizedBox(height: 60),

            // 다음 버튼
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) widget.onNext();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B4DB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('다음', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔥 3자리 콤마 포맷터 (동일하게 유지)
class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final int value = int.parse(newValue.text.replaceAll(',', ''));
    final String formatted = NumberFormat('#,###').format(value);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}