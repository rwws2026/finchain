//lib/features/menty/pages/consultation_request_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../services/firestore_service.dart';

class ConsultationRequestPage extends StatefulWidget {
  const ConsultationRequestPage({super.key, required this.mentorUid});

  final String mentorUid;

  @override
  State<ConsultationRequestPage> createState() => _ConsultationRequestPageState();
}

class _ConsultationRequestPageState extends State<ConsultationRequestPage> {
  final _ctrl = TextEditingController();
  final _fs = FirestoreService.instance;

  bool _loading = false;
  String? _err;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();

    if (text.isEmpty) {
      setState(() => _err = '질문 내용을 입력해줘.');
      return;
    }

    if (text.length > 300) {
      setState(() => _err = '질문은 300자 이하로 작성해줘.');
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() {
      _loading = true;
      _err = null;
    });

    try {
      await _fs.createConsultation(
        mentorUid: widget.mentorUid,
        mentyUid: uid,
        questionText: text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('상담 요청을 보냈어.')));
      Navigator.pop(context);
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = _ctrl.text.length;

    return Scaffold(
      appBar: AppBar(title: const Text('상담 요청')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _ctrl,
              maxLines: 8,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: '질문 내용',
                hintText: '질문 내용을 300자 이하로 작성해줘.',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text('$count / 300'),
            ),
            const SizedBox(height: 12),
            if (_err != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(_err!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: Text(_loading ? '전송 중...' : '보내기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}