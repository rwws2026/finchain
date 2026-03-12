//lib/features/menty/onboarding/step_income_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class StepIncomePage extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onNext;

  const StepIncomePage({super.key, required this.data, required this.onNext});

  @override
  State<StepIncomePage> createState() => _StepIncomePageState();
}

class _StepIncomePageState extends State<StepIncomePage> {
  final _formKey = GlobalKey<FormState>();
  final _currencyFormat = NumberFormat('#,###');

  // 포트폴리오 선택 옵션
  final List<String> _portfolioOptions = [
    '예금/적금/연금', 'CMA/MMF', '채권/펀드/ETF', '주식/가상화폐', '기타'
  ];

  @override
  void initState() {
    super.initState();
    // 데이터 초기화 (리스트 구조)
    widget.data['portfolio'] ??= <Map<String, dynamic>>[];
  }

  // 항목 추가 함수
  void _addPortfolioItem(String category) {
    setState(() {
      (widget.data['portfolio'] as List).add({
        'category': category,
        'amount': '',
        'yield': category == '주식/가상화폐' ? '' : null, // 주식일 때만 수익률 필드 생성
      });
    });
  }

  // 항목 삭제 함수
  void _removeItem(int index) {
    setState(() {
      (widget.data['portfolio'] as List).removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    List portfolio = widget.data['portfolio'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '수익 및 자산 구성',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            // 1. 주수익 & 부수익
            _buildLabel('월 주수익 (원)'),
            _buildCurrencyField(
              hint: '예: 3,000,000',
              onChanged: (v) => widget.data['mainIncome'] = v,
            ),
            const SizedBox(height: 16),
            _buildLabel('월 부수익 (원)'),
            _buildCurrencyField(
              hint: '예: 500,000',
              onChanged: (v) => widget.data['subIncome'] = v,
            ),
            
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // 2. 재테크 포트폴리오 (동적 추가)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLabel('재테크 포트폴리오'),
                DropdownButton<String>(
                  hint: const Text('항목 추가'),
                  underline: const SizedBox(),
                  icon: const Icon(Icons.add_circle, color: Color(0xFF00B4DB)),
                  items: _portfolioOptions.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) _addPortfolioItem(v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 추가된 포트폴리오 리스트
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: portfolio.length,
              itemBuilder: (context, index) {
                final item = portfolio[index];
                return _buildPortfolioCard(index, item);
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

  // 금액 입력용 필드 (콤마 포맷터 적용)
  Widget _buildCurrencyField({required String hint, required Function(String) onChanged, String? initialValue}) {
    return TextFormField(
      initialValue: initialValue,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _CurrencyInputFormatter(),
      ],
      decoration: InputDecoration(
        hintText: hint,
        border: const OutlineInputBorder(),
        suffixText: '원',
      ),
      onChanged: onChanged,
    );
  }

  // 포트폴리오 개별 카드
  Widget _buildPortfolioCard(int index, Map<String, dynamic> item) {
    bool isStock = item['category'] == '주식/가상화폐';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item['category'], style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () => _removeItem(index),
                )
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (isStock) ...[
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '수익률', suffixText: '%', border: OutlineInputBorder()),
                      onChanged: (v) => item['yield'] = v,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  flex: 2,
                  child: _buildCurrencyField(
                    hint: isStock ? '투자금액' : '금액 입력',
                    onChanged: (v) => item['amount'] = v,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600));
  }
}

// 🔥 3자리 콤마 포맷터 클래스
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