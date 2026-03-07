//lib/features/menty/onboarding/step_basic_info_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/firestore_service.dart';

class StepBasicInfoPage extends StatefulWidget {
  const StepBasicInfoPage({
    super.key,
    required this.initial,
    required this.saving,
    required this.onNext,
  });

  final Map<String, dynamic> initial;
  final bool saving;
  final Future<void> Function(Map<String, dynamic> patch) onNext;

  @override
  State<StepBasicInfoPage> createState() => _StepBasicInfoPageState();
}

class _StepBasicInfoPageState extends State<StepBasicInfoPage> {
  final _formKey = GlobalKey<FormState>();

  final _nicknameCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();
  final _jobCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _checking = false;
  final _svc = FirestoreService.instance;

  @override
  void initState() {
    super.initState();
    final d = widget.initial;

    _nicknameCtrl.text = (d['nickname'] ?? '') as String;
    _nameCtrl.text = (d['name'] ?? '') as String;
    _birthDateCtrl.text = (d['birthDate'] ?? '') as String;
    _jobCtrl.text = (d['job'] ?? '') as String;
    _addressCtrl.text = (d['address'] ?? '') as String;
    _phoneCtrl.text = (d['phone'] ?? '') as String;
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _nameCtrl.dispose();
    _birthDateCtrl.dispose();
    _jobCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    DateTime initialDate = DateTime(2000, 1, 1);

    if (_birthDateCtrl.text.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(_birthDateCtrl.text.trim());
      if (parsed != null) initialDate = parsed;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime.now(),
    );

    if (picked == null) return;

    final yyyy = picked.year.toString().padLeft(4, '0');
    final mm = picked.month.toString().padLeft(2, '0');
    final dd = picked.day.toString().padLeft(2, '0');

    setState(() {
      _birthDateCtrl.text = '$yyyy-$mm-$dd';
    });
  }

  Future<void> _next() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _checking = true);
    try {
      final myUid = FirebaseAuth.instance.currentUser!.uid;
      final nickname = _nicknameCtrl.text.trim();

      final nickTaken = await _svc.isNicknameTaken(
        nickname: nickname,
        myUid: myUid,
      );

      if (nickTaken) {
        _toast('이미 사용 중인 닉네임이야.');
        return;
      }

     await widget.onNext({
        'nickname': nickname,
        'name': _nameCtrl.text.trim(),
        'birthDate': _birthDateCtrl.text.trim(),
        'job': _jobCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      });
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.saving || _checking;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            const Text(
              '기본정보',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _nicknameCtrl,
              decoration: const InputDecoration(labelText: '닉네임'),
              enabled: !disabled,
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return '닉네임을 입력해줘';
                if (t.length < 2) return '닉네임이 너무 짧아';
                return null;
              },
            ),
            const SizedBox(height: 10),

            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: '이름'),
              enabled: false,
              readOnly: true,
            ),
            const SizedBox(height: 10),

            TextFormField(
              controller: _birthDateCtrl,
              readOnly: true,
              enabled: !disabled,
              decoration: const InputDecoration(
                labelText: '생년월일',
                hintText: 'YYYY-MM-DD',
              ),
              onTap: disabled ? null : _pickBirthDate,
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return '생년월일을 입력해줘';
                return null;
              },
            ),
            const SizedBox(height: 10),

            TextFormField(
              controller: _jobCtrl,
              decoration: const InputDecoration(labelText: '직업'),
              enabled: !disabled,
            ),
            const SizedBox(height: 10),

            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: '주소'),
              enabled: !disabled,
            ),
            const SizedBox(height: 10),

            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: '전화번호'),
              keyboardType: TextInputType.phone,
              enabled: !disabled,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _PhoneNumberFormatter(),
              ],
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return '전화번호를 입력해줘';
                if (!RegExp(r'^\d{2,3}-\d{3,4}-\d{4}$').hasMatch(t)) {
                  return '전화번호 형식이 올바르지 않아';
                }
                return null;
              },
            ),

            const SizedBox(height: 18),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: disabled ? null : _next,
                child: Text(_checking ? '중복 확인 중...' : '다음'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    String formatted = '';

    if (digits.length <= 3) {
      formatted = digits;
    } else if (digits.length <= 7) {
      formatted = '${digits.substring(0, 3)}-${digits.substring(3)}';
    } else if (digits.length <= 11) {
      formatted =
          '${digits.substring(0, 3)}-${digits.substring(3, digits.length - 4)}-${digits.substring(digits.length - 4)}';
    } else {
      formatted =
          '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7, 11)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}