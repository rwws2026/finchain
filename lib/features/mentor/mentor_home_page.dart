//lib/features/mentor/mentor_home_page.dart
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'pages/mentor_consultation_completed_page.dart';
import 'pages/mentor_consultation_requests_page.dart';
import 'pages/mentor_profile_edit_page.dart';
import '../menty/pages/mentor_ranking_page.dart';

class MentorHomePage extends StatelessWidget {
  const MentorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('멘토 홈'),
        actions: [
          IconButton(
            onPressed: () => AuthService().signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _HomeMenuTile(
              title: '본인 프로필',
              subtitle: '자기소개 / 전문분야 / 상담가능분야 수정',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MentorProfileEditPage(),
                  ),
                );
              },
            ),
            _HomeMenuTile(
              title: '상담 현황',
              subtitle: '상담 요청 리스트 > 수락/거절 > 답변 작성',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MentorConsultationRequestsPage(),
                  ),
                );
              },
            ),
            _HomeMenuTile(
              title: '상담 완료',
              subtitle: '답변 완료된 상담 목록',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MentorConsultationCompletedPage(),
                  ),
                );
              },
            ),
            _HomeMenuTile(
              title: '멘토 상담 순위',
              subtitle: '전체 멘토 랭킹 확인',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MentorRankingPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeMenuTile extends StatelessWidget {
  const _HomeMenuTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}