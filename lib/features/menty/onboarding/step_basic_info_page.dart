//lib/features/menty/onboarding/step_basic_info_page.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  final _studentIdCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _jobCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _checking = false;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  final _svc = FirestoreService.instance;

  @override
  void initState() {
    super.initState();
    final d = widget.initial;

    _studentIdCtrl.text = (d['studentId'] ?? '') as String;
    _nicknameCtrl.text = (d['nickname'] ?? '') as String;
    _nameCtrl.text = (d['name'] ?? '') as String;
    _ageCtrl.text = (d['age']?.toString() ?? '');
    _jobCtrl.text = (d['job'] ?? '') as String;
    _addressCtrl.text = (d['address'] ?? '') as String;
    _phoneCtrl.text = (d['phone'] ?? '') as String;
  }

  @override
  void dispose() {
    _studentIdCtrl.dispose();
    _nicknameCtrl.dispose();
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _jobCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _checking = true);
    try {
      final studentId = _studentIdCtrl.text.trim();
      final nickname = _nicknameCtrl.text.trim();

      final studentTaken = await _svc.isStudentIdTaken(
        studentId: studentId,
        myUid: _uid,
      );
      if (studentTaken) {
        _toast('이미 사용 중인 학번(studentId)이야.');
        return;
      }

      final nickTaken = await _svc.isNicknameTaken(
        nickname: nickname,
        myUid: _uid,
      );
      if (nickTaken) {
        _toast('이미 사용 중인 닉네임이야.');
        return;
      }

      final ageInt = int.tryParse(_ageCtrl.text.trim());

      await widget.onNext({
        'studentId': studentId,
        'nickname': nickname,
        'name': _nameCtrl.text.trim(),
        'age': ageInt,
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
            const Text('기본정보', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            TextFormField(
              controller: _studentIdCtrl,
              decoration: const InputDecoration(labelText: '학번(studentId)'),
              enabled: !disabled,
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return '학번을 입력해줘';
                if (t.length < 4) return '학번이 너무 짧아';
                return null;
              },
            ),
            const SizedBox(height: 10),

            TextFormField(
              controller: _nicknameCtrl,
              decoration: const InputDecoration(labelText: '닉네임(nickname)'),
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
              enabled: !disabled,
            ),
            const SizedBox(height: 10),

            TextFormField(
              controller: _ageCtrl,
              decoration: const InputDecoration(labelText: '나이'),
              keyboardType: TextInputType.number,
              enabled: !disabled,
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