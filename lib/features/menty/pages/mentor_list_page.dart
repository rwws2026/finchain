// lib/features/menty/pages/mentor_list_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../services/firestore_service.dart';
import 'mentor_profile_page.dart';
import 'consultation_request_page.dart';

class MentorListPage extends StatelessWidget {
  const MentorListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService.instance;
    final colorScheme = Theme.of(context).colorScheme;
    
    // 샘플 이미지의 포인트 컬러 (밝은 파란색/청록색)
    const Color pointColor = Color(0xFF0096C7); 

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('전문가 상담', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              '인증된 재무 전문가와 연결하세요',
              style: TextStyle(fontSize: 12, color: pointColor.withOpacity(0.8)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: pointColor),
            onPressed: () {
              // 검색 기능 구현
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTrustBanner(context, pointColor),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: fs.mentorsStream(), // 실제로는 조건에 맞는 멘토 프로필을 가져와야 함
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('등록된 전문가가 없습니다.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final d = docs[i].data();
                    final uid = docs[i].id;
                    return _buildMentorCard(context, uid, d, pointColor);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 상단 신뢰도 배너
  Widget _buildTrustBanner(BuildContext context, Color pointColor) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: pointColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.security, color: pointColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('모든 전문가는 검증되었습니다', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('입증된 실적을 가진 공인 전문가', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 멘토 카드
  Widget _buildMentorCard(BuildContext context, String uid, Map<String, dynamic> data, Color pointColor) {
    final name = (data['name'] ?? '이름 없음') as String;
    final nickname = (data['nickname'] ?? name) as String;
    final specialty = (data['specialty'] ?? '') as String;
    final tags = specialty.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    
    // 임시 데이터 (DB에 없는 값들을 그럴싸하게 생성)
    final rating = ((data['averageRating'] ?? 4.8) as num).toDouble();
    final consultCount = (data['consultCount'] ?? 892) as int;
    final topPercent = (rating > 4.8) ? '1%' : '5%';
    final expYears = (rating > 4.8) ? '15년 이상' : '12년 이상';
    final responseTime = (rating > 4.8) ? '2시간 이내' : '4시간 이내';
    final initials = nickname.isNotEmpty ? nickname.substring(0, 1).toUpperCase() : 'E';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 프로필 헤더 (아바타 + 이름 + 뱃지)
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: pointColor.withOpacity(0.1),
                    border: Border.all(color: pointColor, width: 2),
                  ),
                  child: Text(
                    initials,
                    style: TextStyle(color: pointColor, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(nickname, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        Icon(Icons.check_circle, color: pointColor, size: 16),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: pointColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('상위 $topPercent', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.star, color: pointColor, size: 14),
                        const SizedBox(width: 4),
                        Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 2. 전문 분야 태그
            Text('전문분야', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: pointColor.withOpacity(0.5)),
                  color: pointColor.withOpacity(0.05),
                ),
                child: Text(tag, style: TextStyle(color: pointColor, fontSize: 12)),
              )).toList(),
            ),
            const SizedBox(height: 24),

            // 3. 주요 지표 박스 (경력, 상담건수, 응답시간)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor, // 배경색과 분리된 어두운 박스 느낌
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  _buildStatColumn(context, '경력', expYears),
                  _buildStatColumn(context, '상담건수', '$consultCount'),
                  _buildStatColumn(context, '응답시간', responseTime),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. 문의 버튼
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  // 버튼 클릭 시 프로필 페이지나 바로 상담 요청 페이지로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ConsultationRequestPage(mentorUid: uid),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: pointColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('전문가에게 문의', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 지표 컬럼을 그려주는 위젯
  Widget _buildStatColumn(BuildContext context, String title, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}