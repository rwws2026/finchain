//lib/features/menty/onboarding/step_basic_info_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StepBasicInfoPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onNext;

  const StepBasicInfoPage({super.key, required this.data, required this.onNext});

  @override
  State<StepBasicInfoPage> createState() => _StepBasicInfoPageState();
}

class _StepBasicInfoPageState extends State<StepBasicInfoPage> {
  final _formKey = GlobalKey<FormState>();

  // 직업 리스트 10개
  final List<String> _jobList = [
    'IT/소프트웨어', '경영/관리', '금융/보험', '영업/마케팅', 
    '서비스/외식', '의료/보건', '교육/연구', '제조/생산', 
    '디자인/예술', '학생/취준생'
  ];

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
              '기본 정보를 입력해주세요',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),

            // 1. 닉네임 (2글자 이상, 특수문자 금지)
            _buildLabel('닉네임'),
            TextFormField(
              initialValue: widget.data['nickname'],
              decoration: const InputDecoration(
                hintText: '닉네임을 입력해주세요 (2자 이상)',
                border: OutlineInputBorder(),
              ),
              
              onChanged: (v) => widget.data['nickname'] = v,
              validator: (v) {
                if (v == null || v.length < 2) return '2글자 이상 입력해주세요.';
                // 특수문자 체크를 여기서 수행
                final regExp = RegExp(r'^[a-zA-Z0-9가-힣]+$');
                if (!regExp.hasMatch(v)) return '특수문자는 사용할 수 없습니다.';
                return null;
              },
            ),
            const SizedBox(height: 24),

            // 2. 생년월일 (박스 구분)
            _buildLabel('생년월일'),
            Row(
              children: [
                _buildBoxedField(4, '년', (v) => widget.data['birthYear'] = v),
                const SizedBox(width: 8),
                _buildBoxedField(2, '월', (v) => widget.data['birthMonth'] = v),
                const SizedBox(width: 8),
                _buildBoxedField(2, '일', (v) => widget.data['birthDay'] = v),
              ],
            ),
            const SizedBox(height: 24),

            // 3. 직업 (드롭다운)
            _buildLabel('직업'),
            DropdownButtonFormField<String>(
              value: widget.data['job'],
              decoration: const InputDecoration(border: OutlineInputBorder()),
              hint: const Text('직업을 선택해주세요'),
              items: _jobList.map((job) {
                return DropdownMenuItem(value: job, child: Text(job));
              }).toList(),
              onChanged: (v) => setState(() => widget.data['job'] = v),
              validator: (v) => v == null ? '직업을 선택해주세요' : null,
            ),
            const SizedBox(height: 24),

            // 4. 전화번호 (박스 구분 3/4/4)
            _buildLabel('전화번호'),
            Row(
              children: [
                _buildBoxedField(3, '010', (v) => widget.data['phone1'] = v),
                const SizedBox(width: 8),
                _buildBoxedField(4, '0000', (v) => widget.data['phone2'] = v),
                const SizedBox(width: 8),
                _buildBoxedField(4, '0000', (v) => widget.data['phone3'] = v),
              ],
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

  // 공통 라벨 위젯
  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    );
  }

  // 박스 형태의 입력창 위젯 (생년월일, 전화번호용)
  Widget _buildBoxedField(int maxLength, String hint, Function(String) onChanged) {
    return Expanded(
      child: TextFormField(
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(maxLength),
        ],
        decoration: InputDecoration(
          hintText: hint,
          counterText: '',
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        onChanged: onChanged,
        validator: (v) => (v == null || v.isEmpty) ? '' : null,
      ),
    );
  }
}