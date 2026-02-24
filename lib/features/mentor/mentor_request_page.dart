//lib/features/mentor/mentor_request_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';

class MentorRequestPage extends StatefulWidget {
  const MentorRequestPage({super.key});

  @override
  State<MentorRequestPage> createState() => _MentorRequestPageState();
}

class _MentorRequestPageState extends State<MentorRequestPage> {
  final _fs = FirestoreService();

  final _license = TextEditingController();
  final _career = TextEditingController();
  final _intro = TextEditingController();
  final _years = TextEditingController();

  bool _loading = false;
  String? _err;

  @override
  void dispose() {
    _license.dispose();
    _career.dispose();
    _intro.dispose();
    _years.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _err = null;
    });

    try {
      final u = FirebaseAuth.instance.currentUser!;
      final now = DateTime.now();

      await _fs.createMentorRequest(
        uid: u.uid,
        data: {
          'uid': u.uid,
          'name': '', // 나중에 users에서 가져오거나 가입 폼에서 넘겨도 됨
          'email': u.email ?? '',
          'phone': '',
          'license': _license.text.trim(),
          'licenseImage': '', // 다음 단계에서 Storage 업로드 경로 저장
          'career': _career.text.trim(),
          'intro': _intro.text.trim(),
          'experienceYears': int.tryParse(_years.text.trim()) ?? 0,
          'status': 'pending',
          'reviewedBy': '',
          'reviewedAt': null,
          'createdAt': now,
        },
      );

      // users의 mentorStatus는 이미 pending으로 생성했지만 안전하게 merge 업데이트
      await _fs.updateUser(u.uid, {'mentorStatus': 'pending'});

      if (!mounted) return;
      Navigator.pop(context); // AuthGate가 다시 pending 화면으로 보내줌
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('멘토 신청 (서류 제출)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: _license, decoration: const InputDecoration(labelText: '자격/라이선스')),
            TextField(controller: _career, decoration: const InputDecoration(labelText: '경력 요약')),
            TextField(controller: _intro, decoration: const InputDecoration(labelText: '소개')),
            TextField(controller: _years, decoration: const InputDecoration(labelText: '경력 년수(숫자)'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            if (_err != null) Text(_err!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('신청 제출'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
