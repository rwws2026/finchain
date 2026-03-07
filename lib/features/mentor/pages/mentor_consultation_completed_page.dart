//lib/features/mentor/pages/mentor_consultation_completed_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../services/firestore_service.dart';
import '../../shared/consultation_detail_page.dart';

class MentorConsultationCompletedPage extends StatelessWidget {
  const MentorConsultationCompletedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final fs = FirestoreService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('상담 완료 목록')),
      body: StreamBuilder(
        stream: fs.consultationsForMentorStream(
          uid,
          statuses: const ['answered', 'rejected'],
        ),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('완료된 상담이 없어.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i].data();
              final consultationId = docs[i].id;
              final status = (d['status'] ?? '') as String;
              final question = (d['questionText'] ?? '') as String;

              return Card(
                child: ListTile(
                  title: Text(question),
                  subtitle: Text('상태: $status'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ConsultationDetailPage(
                          consultationId: consultationId,
                          viewerRole: 'mentor',
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