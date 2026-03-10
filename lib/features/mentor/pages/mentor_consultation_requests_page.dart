// lib/features/mentor/pages/mentor_consultation_requests_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../services/firestore_service.dart';
import '../../shared/consultation_detail_page.dart';

class MentorConsultationRequestsPage extends StatefulWidget {
  const MentorConsultationRequestsPage({super.key});

  @override
  State<MentorConsultationRequestsPage> createState() => _MentorConsultationRequestsPageState();
}

class _MentorConsultationRequestsPageState extends State<MentorConsultationRequestsPage> {
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

  // 🔥 String이든 Timestamp든 에러 없이 변환하는 만능 시간 계산기
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
      appBar: AppBar(title: const Text('대기중 상담', style: TextStyle(fontWeight: FontWeight.bold))),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _fs.consultationsForMentorStream(_uid, statuses: const ['requested', 'accepted']),
        builder: (context, snap) {
          
          // 🔥 1. 스트림 에러 발생 시 빨간 화면 대신 텍스트 안내
          if (snap.hasError) {
            return Center(
              child: Text('오류가 발생했습니다.\n${snap.error}', 
                style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            );
          }
          
          // 🔥 2. 상담 리스트 로딩 중 표시
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('대기 중인 상담이 없습니다.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i].data();
              final consultationId = docs[i].id;
              final mentyUid = (d['mentyUid'] ?? '') as String;
              
              final rawQuestion = (d['questionText'] ?? '') as String;
              final title = rawQuestion.split('\n').first.replaceAll(RegExp(r'[\[\]]'), '').trim();
              
              // 🔥 3. 강제 변환(as Timestamp?) 완전 제거
              final createdAt = d['createdAt']; 

              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: _fs.getUserDoc(mentyUid),
                builder: (context, userSnap) {
                  
                  // 🔥 4. 하얀 빈 화면 해결: 멘티 정보 불러오는 동안 로딩 카드 띄워두기
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
                  
                  // 총 자산 합산
                  final totalAssets = ((mentyData['deposit'] ?? 0) as num) + 
                                      ((mentyData['saving'] ?? 0) as num) + 
                                      ((mentyData['stock'] ?? 0) as num) + 
                                      ((mentyData['fund'] ?? 0) as num) + 
                                      ((mentyData['otherPortfolio'] ?? 0) as num);
                  final isUrgent = totalAssets > 100000000; 

                  return _buildCard(
                    context,
                    consultationId,
                    initials, name, ageStr, job, style,
                    title.isEmpty ? '제목 없음' : title,
                    _timeAgo(createdAt),
                    isUrgent,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // 카드 디자인
  Widget _buildCard(
    BuildContext context, String consultationId, String initials, String name, 
    String ageStr, String job, String style, String title, String timeAgo, bool isUrgent) {
    
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: isUrgent ? Colors.redAccent : Colors.orangeAccent),
                  ),
                  child: Text(
                    isUrgent ? '높음' : '보통',
                    style: TextStyle(color: isUrgent ? Colors.redAccent : Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
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
                      backgroundColor: pointColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: const Text('답변하기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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