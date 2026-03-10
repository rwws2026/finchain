// lib/features/mentor/mentor_home_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'pages/mentor_consultation_completed_page.dart';
import 'pages/mentor_consultation_requests_page.dart';
import 'pages/mentor_profile_edit_page.dart';
import '../menty/pages/mentor_ranking_page.dart';

class MentorHomePage extends StatelessWidget {
  const MentorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('로그인이 필요합니다.')));

    final fs = FirestoreService.instance;
    const pointColor = Color(0xFF00B4DB);

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: fs.mentorProfileStream(uid),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final profile = snap.data?.data() ?? {};
            final nickname = (profile['nickname'] ?? '멘토') as String;
            final specialty = (profile['specialty'] ?? '분야 미설정') as String;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(context, uid, nickname, specialty, pointColor),
                const SizedBox(height: 24),
                _buildDashboardCards(context, uid, fs),
                const SizedBox(height: 32),
                _buildRankingSection(context, uid, fs, pointColor),
              ],
            );
          },
        ),
      ),
    );
  }

  // 1. 상단 프로필 및 헤더 (로그아웃 버튼 적용)
  Widget _buildHeader(BuildContext context, String uid, String nickname, String specialty, Color pointColor) {
    final initials = nickname.isNotEmpty ? nickname.substring(0, 1) : 'M';
    
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const MentorProfileEditPage()));
          },
          child: CircleAvatar(
            radius: 26,
            backgroundColor: pointColor,
            child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(nickname, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: pointColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('Expert', style: TextStyle(color: pointColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(specialty, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        
        // 알림 아이콘
        Stack(
          children: [
            const IconButton(icon: Icon(Icons.notifications_none), onPressed: null),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Text('2', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
        
        // 🔥 금액 표시 대신 로그아웃 버튼 배치
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.grey),
          onPressed: () => AuthService().signOut(),
        ),
      ],
    );
  }

  // 2. 핵심 지표 대시보드
  Widget _buildDashboardCards(BuildContext context, String uid, FirestoreService fs) {
    return Row(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: fs.consultationsForMentorStream(uid, statuses: ['requested', 'accepted']),
            builder: (context, snap) {
              final count = snap.hasData ? snap.data!.docs.length : 0;
              return _buildStatCard(
                context: context,
                title: '대기중 상담',
                value: '$count',
                icon: Icons.access_time,
                color: Colors.orangeAccent,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MentorConsultationRequestsPage())),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: fs.consultationsForMentorStream(uid, statuses: ['answered']),
            builder: (context, snap) {
              final count = snap.hasData ? snap.data!.docs.length : 0;
              return _buildStatCard(
                context: context,
                title: '완료 상담',
                value: '$count',
                icon: Icons.check_circle_outline,
                color: Colors.greenAccent,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MentorConsultationCompletedPage())),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context: context,
            title: '이번달 수익',
            value: '2.4M',
            icon: Icons.link,
            color: const Color(0xFF00B4DB),
            onTap: () {},
          ),
        ),
      ],
    );
  }

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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
          ],
        ),
      ),
    );
  }

  // 3. 이달의 TOP 멘토 섹션
  Widget _buildRankingSection(BuildContext context, String currentUid, FirestoreService fs, Color pointColor) {
    final now = DateTime.now();
    final currentMonthString = '${now.year}년 ${now.month}월';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                const SizedBox(width: 6),
                const Text('이달의 TOP 멘토', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            Text(currentMonthString, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 16),
        
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: fs.mentorProfilesByScoreStream(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return const Center(child: Text('랭킹 데이터가 없습니다.'));
            }

            final docs = snap.data!.docs.take(5).toList();

            return Column(
              children: List.generate(docs.length, (index) {
                final d = docs[index].data();
                final uid = docs[index].id;
                final isMe = uid == currentUid;
                
                return _buildRankCard(context, index + 1, uid, d, isMe, pointColor);
              }),
            );
          },
        ),
        
        TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MentorRankingPage())),
          child: const Center(child: Text('전체 랭킹 보기')),
        ),
      ],
    );
  }

  Widget _buildRankCard(BuildContext context, int rank, String uid, Map<String, dynamic> data, bool isMe, Color pointColor) {
    final nickname = (data['nickname'] ?? '이름 없음') as String;
    final specialty = (data['specialty'] ?? '') as String;
    final rating = ((data['averageRating'] ?? 0) as num).toDouble();
    final consultCount = (data['consultCount'] ?? 0) as int;
    final initials = nickname.isNotEmpty ? nickname.substring(0, 1) : 'M';
    final thisMonthCount = (consultCount * 0.15).toInt(); 

    Widget rankIcon;
    if (rank == 1) {
      rankIcon = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.emoji_events, color: Colors.amber, size: 24),
          Text('#1', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        ],
      );
    } else if (rank == 2) {
      rankIcon = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.workspace_premium, color: Color(0xFFC0C0C0), size: 24),
          Text('#2', style: TextStyle(color: Color(0xFFC0C0C0), fontWeight: FontWeight.bold)),
        ],
      );
    } else if (rank == 3) {
      rankIcon = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.workspace_premium, color: Color(0xFFCD7F32), size: 24),
          Text('#3', style: TextStyle(color: Color(0xFFCD7F32), fontWeight: FontWeight.bold)),
        ],
      );
    } else {
      rankIcon = Center(child: Text('#$rank', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)));
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe ? pointColor : Theme.of(context).dividerColor.withOpacity(0.1),
          width: isMe ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 40, child: rankIcon),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 22,
            backgroundColor: pointColor,
            child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(nickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: pointColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('내 순위', style: TextStyle(color: pointColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(specialty.isEmpty ? '분야 없음' : specialty, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 4),
                  Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 4),
              Text('이번달 ${thisMonthCount}회', style: TextStyle(fontSize: 11, color: pointColor, fontWeight: FontWeight.bold)),
              Text('총 ${consultCount}회', style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }
}