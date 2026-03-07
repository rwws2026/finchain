//lib/features/menty/pages/menty_question_status_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../services/firestore_service.dart';
import '../../shared/consultation_detail_page.dart';

class MentyQuestionStatusPage extends StatelessWidget {
  const MentyQuestionStatusPage({super.key});

  String _statusText(String status) {
    switch (status) {
      case 'requested':
        return '대기중';
      case 'accepted':
        return '수락됨';
      case 'rejected':
        return '거절됨';
      case 'answered':
        return '답변완료';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final fs = FirestoreService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('질문 현황')),
      body: StreamBuilder(
        stream: fs.consultationsForMentyStream(
          uid,
          statuses: const ['requested', 'accepted', 'rejected'],
        ),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('질문 현황을 불러오지 못했어.\n${snap.error}'),
              ),
            );
          }

          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snap.hasData) {
            return const Center(child: Text('진행 중인 질문이 없어.'));
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('진행 중인 질문이 없어.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i].data();
              final consultationId = docs[i].id;
              final question = (d['questionText'] ?? '') as String;
              final status = (d['status'] ?? '') as String;

              return Card(
                child: ListTile(
                  title: Text(question),
                  subtitle: Text('상태: ${_statusText(status)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ConsultationDetailPage(
                          consultationId: consultationId,
                          viewerRole: 'menty',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}