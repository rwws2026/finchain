//../menty/pages/mentor_list_page.dart

import 'package:flutter/material.dart';

import '../../../services/firestore_service.dart';
import 'mentor_profile_page.dart';

class MentorListPage extends StatelessWidget {
  const MentorListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('멘토 리스트')),
      body: StreamBuilder(
        stream: fs.mentorsStream(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('등록된 멘토가 없어.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i].data();
              final uid = docs[i].id;
              final name = (d['name'] ?? '') as String;
              final nickname = (d['nickname'] ?? '') as String;

              return ListTile(
                title: Text(nickname.isNotEmpty ? nickname : name),
                subtitle: Text(name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MentorProfilePage(mentorUid: uid),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}