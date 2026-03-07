//lib/features/mentor/pages/mentor_profile_edit_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../services/firestore_service.dart';

class MentorProfileEditPage extends StatefulWidget {
  const MentorProfileEditPage({super.key});

  @override
  State<MentorProfileEditPage> createState() => _MentorProfileEditPageState();
}

class _MentorProfileEditPageState extends State<MentorProfileEditPage> {
  final _headline = TextEditingController();
  final _bio = TextEditingController();
  final _specialty = TextEditingController();
  final _consultingField = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  final _fs = FirestoreService.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await _fs.getMentorProfile(uid);
    final d = doc.data() ?? {};

    _headline.text = (d['headline'] ?? '') as String;
    _bio.text = (d['bio'] ?? '') as String;
    _specialty.text = (d['specialty'] ?? '') as String;
    _consultingField.text = (d['consultingField'] ?? '') as String;

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    setState(() => _saving = true);
    try {
      await _fs.createOrUpdateMentorProfile(
        uid: uid,
        data: {
          'headline': _headline.text.trim(),
          'bio': _bio.text.trim(),
          'specialty': _specialty.text.trim(),
          'consultingField': _consultingField.text.trim(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('저장했어.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _headline.dispose();
    _bio.dispose();
    _specialty.dispose();
    _consultingField.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('멘토 프로필 수정')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _headline,
              decoration: const InputDecoration(labelText: '한줄 소개'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bio,
              maxLines: 5,
              decoration: const InputDecoration(labelText: '상세 소개'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _specialty,
              decoration: const InputDecoration(labelText: '전문분야'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _consultingField,
              decoration: const InputDecoration(labelText: '상담 가능 분야'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? '저장 중...' : '저장'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}