// lib/features/menty/menty_home_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'pages/menty_profile_edit_page.dart';
import 'pages/mentor_list_page.dart';
import 'pages/mentor_profile_page.dart';
import 'pages/menty_question_status_page.dart'; // 추가됨
import 'pages/menty_answer_status_page.dart';   // 추가됨

class MentyHomePage extends StatelessWidget {
  const MentyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('로그인이 필요합니다.')));

    final fs = FirestoreService.instance;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: fs.userStream(uid),
          builder: (context, userSnap) {
            if (!userSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final userData = userSnap.data!.data() ?? {};
            final name = (userData['name'] ?? '사용자') as String;
            final nickname = (userData['nickname'] ?? '') as String;
            final savingGoal = (userData['savingGoal'] ?? '') as String;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(context, name, nickname),
                const SizedBox(height: 24),
                // 🔥 여기에 대시보드 카드를 추가했습니다.
                _buildDashboardCards(context, uid, fs), 
                const SizedBox(height: 24),
                _buildConsultationBanner(context),
                const SizedBox(height: 24),
                _buildTopMentorsSection(context, fs, colorScheme),
                const SizedBox(height: 16),
                _buildNewsSection(context, colorScheme),
                const SizedBox(height: 16),
                _buildSavingsGoalSection(context, savingGoal, colorScheme),
              ],
            );
          },
        ),
      ),
    );
  }

  // 1. 상단 프로필 헤더
  Widget _buildHeader(BuildContext context, String name, String nickname) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          backgroundImage: const NetworkImage('https://i.pravatar.cc/150?img=1'),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber, width: 1),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.monetization_on, size: 14, color: Colors.amber),
                      SizedBox(width: 4),
                      Text('100', style: TextStyle(fontSize: 12, color: Colors.amber, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            Text(
              '@${nickname.isNotEmpty ? nickname : 'nickname'}',
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.logout, size: 20),
          onPressed: () => AuthService().signOut(),
        ),
      ],
    );
  }

  // 🔥 2. 멘티용 대시보드 카드 추가 
  Widget _buildDashboardCards(BuildContext context, String uid, FirestoreService fs) {
    return Row(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: fs.consultationsForMentyStream(uid, statuses: const ['requested', 'accepted']),
            builder: (context, snap) {
              final count = snap.hasData ? snap.data!.docs.length : 0;
              return _buildStatCard(
                context: context,
                title: '대기중 상담',
                value: '$count',
                icon: Icons.access_time,
                color: Colors.orangeAccent,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MentyQuestionStatusPage())),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: fs.consultationsForMentyStream(uid, statuses: const ['answered']),
            builder: (context, snap) {
              final count = snap.hasData ? snap.data!.docs.length : 0;
              return _buildStatCard(
                context: context,
                title: '완료된 상담',
                value: '$count',
                icon: Icons.check_circle_outline,
                color: Colors.greenAccent,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MentyAnswerStatusPage())),
              );
            },
          ),
        ),
      ],
    );
  }

  // 대시보드 박스 위젯
  Widget _buildStatCard({
    required BuildContext context, 
    required String title, 
    required String value, 
    required IconData icon, 
    required Color color, 
    required VoidCallback onTap
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
          ],
        ),
      ),
    );
  }

  // 3. 전문가 상담 배너 (그라데이션)
  Widget _buildConsultationBanner(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MentorListPage()));
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00C6FF), Color(0xFF0072FF)], 
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.people, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('전문가 상담', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 4),
                  Text('최고의 재무 전문가와 연결하세요', style: TextStyle(fontSize: 14, color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white, size: 32),
          ],
        ),
      ),
    );
  }

  // 4. 이달의 TOP 멘토 섹션
  Widget _buildTopMentorsSection(BuildContext context, FirestoreService fs, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('이달의 TOP 멘토', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Icon(Icons.bookmark_border, color: colorScheme.primary),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: fs.mentorProfilesByScoreStream(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                
                final docs = snap.data!.docs.take(3).toList(); 
                if (docs.isEmpty) return const Text('등록된 멘토가 없습니다.');

                return Column(
                  children: List.generate(docs.length, (index) {
                    final d = docs[index].data();
                    final uid = docs[index].id;
                    return _buildMentorRow(context, index + 1, uid, d, colorScheme);
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMentorRow(BuildContext context, int rank, String uid, Map<String, dynamic> data, ColorScheme colorScheme) {
    final nickname = (data['nickname'] ?? '이름 없음') as String;
    final specialty = (data['specialty'] ?? '') as String;
    final tags = specialty.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).take(2).toList();
    
    Color rankColor;
    if (rank == 1) rankColor = const Color(0xFF00C6FF);
    else if (rank == 2) rankColor = const Color(0xFF00B4DB);
    else rankColor = const Color(0xFF0083B0);

    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => MentorProfilePage(mentorUid: uid)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: rankColor,
              child: Text('$rank', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 20,
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              child: Text(nickname.isNotEmpty ? nickname.substring(0, 1) : 'M', style: TextStyle(color: colorScheme.primary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Row(
                    children: tags.map((tag) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
                        ),
                        child: Text(tag, style: TextStyle(fontSize: 10, color: colorScheme.primary)),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                Text('+32%', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                Text('이번달', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            )
          ],
        ),
      ),
    );
  }

  // 5. 금융 경제 뉴스 섹션
  Widget _buildNewsSection(BuildContext context, ColorScheme colorScheme) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.show_chart, color: colorScheme.primary),
        ),
        title: const Text('금융 경제 뉴스', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('연준, 새로운 금리 변경 발표'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }

  // 6. 저축 목표 진행상황 섹션
  Widget _buildSavingsGoalSection(BuildContext context, String savingGoal, ColorScheme colorScheme) {
    final hasGoal = savingGoal.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('저축 목표 진행상황', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasGoal ? colorScheme.primary.withOpacity(0.1) : colorScheme.surface,
                    border: Border.all(color: hasGoal ? colorScheme.primary : Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    hasGoal ? '진행중' : '목표 없음',
                    style: TextStyle(fontSize: 12, color: hasGoal ? colorScheme.primary : Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            hasGoal
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text('현재 목표:\n$savingGoal', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                    ),
                  )
                : InkWell(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const MentyProfileEditPage()));
                    },
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.track_changes, size: 48, color: Colors.grey.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          const Text('아직 저축 목표가 없습니다', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('클릭하여 목표를 설정하세요', style: TextStyle(fontSize: 12, color: colorScheme.primary)),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}