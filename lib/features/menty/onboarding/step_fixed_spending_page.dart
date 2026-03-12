//lib/features/menty/onboarding/step_fixed_spending_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class StepFixedSpendingPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onNext;

  const StepFixedSpendingPage({super.key, required this.data, required this.onNext});

  @override
  State<StepFixedSpendingPage> createState() => _StepFixedSpendingPageState();
}

class _StepFixedSpendingPageState extends State<StepFixedSpendingPage> {
  final _formKey = GlobalKey<FormState>();

  // 고정 지출 선택 옵션 리스트
  final List<String> _spendingOptions = [
    '월세', '교통비', '경조사비', '비상금', '자기계발비', '보험', '기타'
  ];

  @override
  void initState() {
    super.initState();
    // 데이터 구조 초기화
    widget.data['fixedSpending'] ??= <Map<String, dynamic>>[];
  }

  // 지출 항목 추가
  void _addSpendingItem(String category) {
    setState(() {
      (widget.data['fixedSpending'] as List).add({
        'category': category,
        'amount': '',
      });
    });
  }

  // 지출 항목 삭제
  void _removeItem(int index) {
    setState(() {
      (widget.data['fixedSpending'] as List).removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    List spendingList = widget.data['fixedSpending'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '매달 나가는 고정 지출',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '정기적으로 지출되는 항목을 추가해 주세요.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // 항목 추가 드롭다운 영역
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '지출 항목 리스트',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                DropdownButton<String>(
                  hint: const Text('항목 추가'),
                  underline: const SizedBox(),
                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00B4DB)),
                  items: _spendingOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) _addSpendingItem(v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 추가된 지출 항목 카드 리스트
            if (spendingList.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('추가된 항목이 없습니다.', style: TextStyle(color: Colors.grey)),
                ),
              ),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: spendingList.length,
              itemBuilder: (context, index) {
                final item = spendingList[index];
                return _buildSpendingCard(index, item);
              },
            ),

            const SizedBox(height: 40),

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

  // 지출 항목 개별 카드 위젯
  Widget _buildSpendingCard(int index, Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                item['category'],
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Expanded(
              flex: 3,
              child: TextFormField(
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _CurrencyInputFormatter(), // 3자리 콤마 포맷터
                ],
                decoration: const InputDecoration(
                  hintText: '금액 입력',
                  suffixText: '원',
                  border: InputBorder.none,
                ),
                onChanged: (v) => item['amount'] = v,
                validator: (v) => (v == null || v.isEmpty) ? '금액을 입력하세요' : null,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey, size: 20),
              onPressed: () => _removeItem(index),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔥 3자리 콤마 포맷터 (공통 사용)
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