//lib/features/menty/pages/menty_profile_edit_page.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/firestore_service.dart';

class MentyProfileEditPage extends StatefulWidget {
  const MentyProfileEditPage({super.key});

  @override
  State<MentyProfileEditPage> createState() => _MentyProfileEditPageState();
}

class _MentyProfileEditPageState extends State<MentyProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _fs = FirestoreService.instance;

  final _nicknameCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();
  final _jobCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  final _mainCtrl = TextEditingController();
  final _subCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();
  final _savingCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _fundCtrl = TextEditingController();
  final _otherCtrl = TextEditingController();
  final _fixedCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();

  bool riskHighReturn = false;
  bool wantLeverage = false;

  bool _loading = true;
  bool _saving = false;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  int _parseMoney(String text) {
    return int.tryParse(text.replaceAll(',', '').trim()) ?? 0;
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

  Future<void> _load() async {
    final doc = await _fs.getUserDoc(_uid);
    final d = doc.data() ?? {};

    _nicknameCtrl.text = (d['nickname'] ?? '') as String;
    _nameCtrl.text = (d['name'] ?? '') as String;
    _birthDateCtrl.text = (d['birthDate'] ?? '') as String;
    _jobCtrl.text = (d['job'] ?? '') as String;
    _addressCtrl.text = (d['address'] ?? '') as String;
    _phoneCtrl.text = (d['phone'] ?? '') as String;

    _mainCtrl.text = (d['mainProfit']?.toString() ?? '');
    _subCtrl.text = (d['subProfit']?.toString() ?? '');
    _depositCtrl.text = (d['deposit']?.toString() ?? '');
    _savingCtrl.text = (d['saving']?.toString() ?? '');
    _stockCtrl.text = (d['stock']?.toString() ?? '');
    _fundCtrl.text = (d['fund']?.toString() ?? '');
    _otherCtrl.text = (d['otherPortfolio']?.toString() ?? '');
    _fixedCtrl.text = (d['fixedSpending']?.toString() ?? '');
    _goalCtrl.text = (d['savingGoal'] ?? d['goal'] ?? '') as String;

    riskHighReturn = d['riskHighReturn'] == true;
    wantLeverage = d['wantLeverage'] == true;

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final nickTaken = await _fs.isNicknameTaken(
        nickname: _nicknameCtrl.text.trim(),
        myUid: _uid,
      );
      if (nickTaken) {
        _toast('이미 사용 중인 닉네임이야.');
        return;
      }

      final goal = _goalCtrl.text.trim();

      await _fs.updateUserMerge(_uid, {
        'nickname': _nicknameCtrl.text.trim(),
        'name': _nameCtrl.text.trim(),
        'birthDate': _birthDateCtrl.text.trim(),
        'job': _jobCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'mainProfit': _parseMoney(_mainCtrl.text),
        'subProfit': _parseMoney(_subCtrl.text),
        'deposit': _parseMoney(_depositCtrl.text),
        'saving': _parseMoney(_savingCtrl.text),
        'stock': _parseMoney(_stockCtrl.text),
        'fund': _parseMoney(_fundCtrl.text),
        'otherPortfolio': _parseMoney(_otherCtrl.text),
        'fixedSpending': _parseMoney(_fixedCtrl.text),
        'savingGoal': goal,
        'goal': goal,
        'riskHighReturn': riskHighReturn,
        'wantLeverage': wantLeverage,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      _toast('프로필을 저장했어.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _nameCtrl.dispose();
    _birthDateCtrl.dispose();
    _jobCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _mainCtrl.dispose();
    _subCtrl.dispose();
    _depositCtrl.dispose();
    _savingCtrl.dispose();
    _stockCtrl.dispose();
    _fundCtrl.dispose();
    _otherCtrl.dispose();
    _fixedCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(labelText: label);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('멘티 프로필')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final disabled = _saving;

    return Scaffold(
      appBar: AppBar(title: const Text('멘티 프로필 수정')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _sectionTitle('기본정보'),

              TextFormField(
                controller: _nicknameCtrl,
                enabled: !disabled,
                decoration: _dec('닉네임'),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return '닉네임을 입력해줘';
                  return null;
                },
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _nameCtrl,
                enabled: false,
                readOnly: true,
                decoration: _dec('이름'),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _birthDateCtrl,
                readOnly: true,
                enabled: !disabled,
                decoration: _dec('생년월일'),
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
                enabled: !disabled,
                decoration: _dec('직업'),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _addressCtrl,
                enabled: !disabled,
                decoration: _dec('주소'),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _phoneCtrl,
                enabled: !disabled,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _PhoneNumberFormatter(),
                ],
                decoration: _dec('전화번호'),
                validator: (v) {
                  final t = (v ?? '').trim();
                  if (t.isEmpty) return '전화번호를 입력해줘';
                  if (!RegExp(r'^\d{2,3}-\d{3,4}-\d{4}$').hasMatch(t)) {
                    return '전화번호 형식이 올바르지 않아';
                  }
                  return null;
                },
              ),

              _sectionTitle('수익 및 포트폴리오'),

              TextFormField(
                controller: _mainCtrl,
                enabled: !disabled,
                keyboardType: TextInputType.number,
                decoration: _dec('주 수익(mainProfit)'),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _subCtrl,
                enabled: !disabled,
                keyboardType: TextInputType.number,
                decoration: _dec('부 수익(subProfit)'),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _depositCtrl,
                enabled: !disabled,
                keyboardType: TextInputType.number,
                decoration: _dec('예금(deposit)'),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _savingCtrl,
                enabled: !disabled,
                keyboardType: TextInputType.number,
                decoration: _dec('적금(saving)'),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _stockCtrl,
                enabled: !disabled,
                keyboardType: TextInputType.number,
                decoration: _dec('주식(stock)'),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _fundCtrl,
                enabled: !disabled,
                keyboardType: TextInputType.number,
                decoration: _dec('펀드(fund)'),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _otherCtrl,
                enabled: !disabled,
                keyboardType: TextInputType.number,
                decoration: _dec('기타 포트폴리오(otherPortfolio)'),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _fixedCtrl,
                enabled: !disabled,
                keyboardType: TextInputType.number,
                decoration: _dec('고정지출(fixedSpending)'),
              ),

              _sectionTitle('목표 및 성향'),

              TextFormField(
                controller: _goalCtrl,
                enabled: !disabled,
                maxLines: 3,
                decoration: _dec('저축 목표(savingGoal)'),
              ),
              const SizedBox(height: 10),

              SwitchListTile(
                title: const Text('높은 수익/높은 리스크를 선호해요'),
                value: riskHighReturn,
                onChanged: disabled ? null : (v) => setState(() => riskHighReturn = v),
              ),
              SwitchListTile(
                title: const Text('레버리지를 활용해도 괜찮아요'),
                value: wantLeverage,
                onChanged: disabled ? null : (v) => setState(() => wantLeverage = v),
              ),

              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: disabled ? null : _save,
                  child: Text(disabled ? '저장 중...' : '저장'),
                ),
              ),
            ],
          ),
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