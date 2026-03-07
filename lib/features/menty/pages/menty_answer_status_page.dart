//lib/features/menty/pages/menty_answer_status_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../services/firestore_service.dart';
import '../../shared/consultation_detail_page.dart';

class MentyAnswerStatusPage extends StatelessWidget {
  const MentyAnswerStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final fs = FirestoreService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('답변 현황')),
      body: StreamBuilder(
        stream: fs.consultationsForMentyStream(
          uid,
          statuses: const ['answered'],
        ),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('답변 현황을 불러오지 못했어.\n${snap.error}'),
              ),
            );
          }

          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snap.hasData) {
            return const Center(child: Text('답변 완료된 상담이 없어.'));
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('답변 완료된 상담이 없어.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i].data();
              final consultationId = docs[i].id;
              final question = (d['questionText'] ?? '') as String;

              return Card(
                child: ListTile(
                  title: Text(question),
                  subtitle: const Text('답변 완료'),
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