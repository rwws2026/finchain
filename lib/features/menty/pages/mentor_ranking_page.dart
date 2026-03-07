//../menty/pages/mentor_ranking_page.dart
import 'package:flutter/material.dart';

import '../../../services/firestore_service.dart';
import 'mentor_profile_page.dart';

class MentorRankingPage extends StatelessWidget {
  const MentorRankingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('멘토 상담 순위')),
      body: StreamBuilder(
        stream: fs.mentorProfilesByScoreStream(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('순위 데이터를 불러오지 못했어.\n${snap.error}'),
              ),
            );
          }

          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snap.hasData) {
            return const Center(child: Text('랭킹 데이터가 없어.'));
          }

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('랭킹 데이터가 없어.'));
          }

          int currentRank = 0;
          double? prevScore;
          int? prevRecommend;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i].data();
              final uid = docs[i].id;
              final nickname = (d['nickname'] ?? '') as String;
              final specialty = (d['specialty'] ?? '') as String;
              final score = ((d['score'] ?? 0) as num).toDouble();
              final recommendCount = (d['recommendCount'] ?? 0) as int;
              final averageRating =
                  ((d['averageRating'] ?? 0) as num).toDouble();

              if (prevScore == null) {
                currentRank = 1;
              } else {
                if (score == prevScore && recommendCount == prevRecommend) {
                  // same rank
                } else {
                  currentRank = i + 1;
                }
              }
              prevScore = score;
              prevRecommend = recommendCount;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('$currentRank')),
                  title: Text(nickname.isEmpty ? '이름 없음' : nickname),
                  subtitle: Text(
                    '전문분야: $specialty\n평점: ${averageRating.toStringAsFixed(1)} / 추천: $recommendCount / 점수: ${score.toStringAsFixed(1)}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MentorProfilePage(mentorUid: uid),
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