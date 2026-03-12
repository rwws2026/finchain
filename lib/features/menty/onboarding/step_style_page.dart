//lib/features/menty/onboarding/step_style_page.dart
import 'package:flutter/material.dart';

class StepStylePage extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onFinish; // 마지막 단계이므로 onFinish로 명칭 변경

  const StepStylePage({super.key, required this.data, required this.onFinish});

  @override
  State<StepStylePage> createState() => _StepStylePageState();
}

class _StepStylePageState extends State<StepStylePage> {
  // 투자 성향 질문 리스트
  final List<Map<String, String>> _questions = [
    {'key': 'risk_return', 'label': '하이 리스크, 하이 리턴(High risk, High return)'},
    {'key': 'long_term', 'label': '하락장에서 장기 투자'},
    {'key': 'stock_preference', 'label': '예금, 적금보다 주식, ETF를'},
    {'key': 'growth_opp', 'label': '원금보호보다는 성장 기회'},
    {'key': 'expected_profit', 'label': '단기 확실성보다는 장기 기대수익'},
    {'key': 'volatility', 'label': '예측 가능함보다는 변동성 감수'},
    {'key': 'active_analysis', 'label': '간편한 관리보다는 직접 분석'},
  ];

  @override
  void initState() {
    super.initState();
    // 데이터 초기화: 모든 질문에 대해 기본값 3(보통) 설정
    widget.data['styles'] ??= {};
    for (var q in _questions) {
      widget.data['styles'][q['key']] ??= 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '투자 성향 파악',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '본인의 투자 스타일에 가까운 점수를 선택해 주세요.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 32),

          // 질문 리스트 생성
          ..._questions.map((q) => _buildScaleQuestion(q['key']!, q['label']!)),

          const SizedBox(height: 40),

          // 완료 버튼
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: widget.onFinish,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B4DB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('온보딩 완료', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // 선형 척도 질문 위젯
  Widget _buildScaleQuestion(String key, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('비선호', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Row(
                children: List.generate(5, (index) {
                  int score = index + 1;
                  bool isSelected = widget.data['styles'][key] == score;
                  return GestureDetector(
                    onTap: () => setState(() => widget.data['styles'][key] = score),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? const Color(0xFF00B4DB) : Colors.grey[200],
                        border: Border.all(
                          color: isSelected ? const Color(0xFF00B4DB) : Colors.transparent,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$score',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const Text('선호', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}