import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'pages/menty_answer_status_page.dart';
import 'pages/menty_profile_edit_page.dart';
import 'pages/menty_question_status_page.dart';
import 'pages/mentor_list_page.dart';
import 'pages/mentor_ranking_page.dart';

class MentyHomePage extends StatelessWidget {
  const MentyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('멘티 홈'),
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
              title: '프로필',
              subtitle: '기본정보 / 수익 / 포트폴리오 / 지출 / 목표 수정',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MentyProfileEditPage()),
                );
              },
            ),
            _HomeMenuTile(
              title: '멘토 리스트',
              subtitle: '전체 멘토 보기 > 멘토 프로필 > 상담 요청',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MentorListPage()),
                );
              },
            ),
            _HomeMenuTile(
              title: '멘토 상담 순위',
              subtitle: '랭킹 기준으로 멘토 보기',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MentorRankingPage()),
                );
              },
            ),
            _HomeMenuTile(
              title: '질문 현황',
              subtitle: '승인 / 거절 / 대기 상태 확인',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MentyQuestionStatusPage(),
                  ),
                );
              },
            ),
            _HomeMenuTile(
              title: '답변 현황',
              subtitle: '답변 완료 상담 확인 및 평가',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MentyAnswerStatusPage(),
                  ),
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