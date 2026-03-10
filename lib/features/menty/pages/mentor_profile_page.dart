//../menty/pages/mentor_profile_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../services/firestore_service.dart';
import 'consultation_request_page.dart';

class MentorProfilePage extends StatelessWidget {
  const MentorProfilePage({super.key, required this.mentorUid});

  final String mentorUid;

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('멘토 프로필')),
      body: StreamBuilder(
        stream: fs.mentorProfileStream(mentorUid),
        builder: (context, profileSnap) {
          if (profileSnap.hasError) {
            return Center(
              child: Text('멘토 프로필을 불러오지 못했어.\n${profileSnap.error}'),
            );
          }

          if (!profileSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = profileSnap.data!.data() ?? {};
          final myUid = FirebaseAuth.instance.currentUser?.uid;

          return FutureBuilder(
            future: fs.getUserDoc(mentorUid),
            builder: (context, userSnap) {
              Map<String, dynamic> user = {};

              if (userSnap.hasData) {
                user = userSnap.data!.data() ?? {};
              }

              final nickname =
                  (profile['nickname'] ?? user['nickname'] ?? '') as String;
              final name = (user['name'] ?? profile['name'] ?? '') as String;
              final headline = (profile['headline'] ?? '') as String;
              final bio = (profile['bio'] ?? '') as String;
              final specialty = (profile['specialty'] ?? '') as String;
              final consultingField =
                  (profile['consultingField'] ?? '') as String;
              final averageRating =
                  ((profile['averageRating'] ?? 0) as num).toDouble();
              final recommendCount = (profile['recommendCount'] ?? 0) as int;
              final consultCount = (profile['consultCount'] ?? 0) as int;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    nickname.isNotEmpty ? nickname : '이름 없음',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (name.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('이름: $name'),
                  ],
                  const SizedBox(height: 12),
                  _InfoCard(title: '한줄 소개', value: headline),
                  _InfoCard(title: '상세 소개', value: bio),
                  _InfoCard(title: '전문분야', value: specialty),
                  _InfoCard(title: '상담 가능 분야', value: consultingField),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '평균 별점: ${averageRating.toStringAsFixed(1)}\n추천 수: $recommendCount\n상담 수: $consultCount',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (myUid != mentorUid)
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ConsultationRequestPage(mentorUid: mentorUid),
                            ),
                          );
                        },
                        child: const Text('상담 요청'),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(value.isEmpty ? '-' : value),
        ),
      ),
    );
  }
}