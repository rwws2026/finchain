// lib/features/mentor/pages/mentor_consultation_completed_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../services/firestore_service.dart';
import '../../shared/consultation_detail_page.dart';

class MentorConsultationCompletedPage extends StatefulWidget {
  const MentorConsultationCompletedPage({super.key});

  @override
  State<MentorConsultationCompletedPage> createState() => _MentorConsultationCompletedPageState();
}

class _MentorConsultationCompletedPageState extends State<MentorConsultationCompletedPage> {
  final _fs = FirestoreService.instance;
  final String _uid = FirebaseAuth.instance.currentUser!.uid;
  final Color pointColor = const Color(0xFF0096C7);

  String _calculateAge(String? birthDate) {
    if (birthDate == null || birthDate.length < 4) return '미상';
    final birthYear = int.tryParse(birthDate.substring(0, 4)) ?? 2000;
    final currentYear = DateTime.now().year;
    return '${currentYear - birthYear + 1}세';
  }

  String _getInvestmentStyle(bool highRisk, bool leverage) {
    if (highRisk && leverage) return '공격투자형';
    if (highRisk) return '적극투자형';
    if (leverage) return '위험중립형';
    return '안정추구형';
  }

  // 🔥 String이든 Timestamp든 에러 없이 변환
  String _timeAgo(dynamic timestampData) {
    if (timestampData == null) return '방금 전';
    DateTime? date;
    if (timestampData is Timestamp) {
      date = timestampData.toDate();
    } else if (timestampData is String) {
      date = DateTime.tryParse(timestampData);
    }
    if (date == null) return '방금 전';
    
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}일 전';
    if (diff.inHours > 0) return '${diff.inHours}시간 전';
    if (diff.inMinutes > 0) return '${diff.inMinutes}분 전';
    return '방금 전';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('완료 상담', style: TextStyle(fontWeight: FontWeight.bold))),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _fs.consultationsForMentorStream(_uid, statuses: const ['answered', 'rejected']),
        builder: (context, snap) {
          
          if (snap.hasError) {
            return Center(
              child: Text('오류가 발생했습니다.\n${snap.error}', 
                style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            );
          }
          
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('완료된 상담이 없습니다.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i].data();
              final consultationId = docs[i].id;
              final mentyUid = (d['mentyUid'] ?? '') as String;
              
              final rawQuestion = (d['questionText'] ?? '') as String;
              final title = rawQuestion.split('\n').first.replaceAll(RegExp(r'[\[\]]'), '').trim();
              
              // 🔥 강제 변환 제거
              final createdAt = d['createdAt'];

              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: _fs.getUserDoc(mentyUid),
                builder: (context, userSnap) {
                  
                  // 🔥 로딩 중일 때 빈 카드 표시 (하얀 화면 방지)
                  if (userSnap.connectionState == ConnectionState.waiting) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: const SizedBox(
                        height: 140,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }

                  final mentyData = userSnap.data?.data() ?? {};
                  final name = (mentyData['name'] ?? '익명') as String;
                  final initials = name.isNotEmpty ? name.substring(0, 1) : '?';
                  final ageStr = _calculateAge(mentyData['birthDate']?.toString());
                  final job = (mentyData['job'] ?? '직업미상') as String;
                  final style = _getInvestmentStyle(mentyData['riskHighReturn'] == true, mentyData['wantLeverage'] == true);

                  return _buildCard(
                    context,
                    consultationId,
                    initials, name, ageStr, job, style,
                    title.isEmpty ? '제목 없음' : title,
                    _timeAgo(createdAt),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // 완료 전용 카드 디자인 (우선순위 뱃지 대신 '완료' 텍스트, '상담상세' 버튼 적용)
  Widget _buildCard(
    BuildContext context, String consultationId, String initials, String name, 
    String ageStr, String job, String style, String title, String timeAgo) {
    
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: pointColor.withOpacity(0.1),
                  child: Text(initials, style: TextStyle(color: pointColor, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(ageStr, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                      Text('$job · $style', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Text('완료', style: TextStyle(color: pointColor, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(timeAgo, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ConsultationDetailPage(consultationId: consultationId, viewerRole: 'mentor'))),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.surface,
                      foregroundColor: pointColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: const Text('상담상세', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}