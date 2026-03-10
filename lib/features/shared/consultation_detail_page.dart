// lib/features/shared/consultation_detail_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';

class ConsultationDetailPage extends StatefulWidget {
  final String consultationId;
  final String viewerRole; // 'mentor' 또는 'menty'

  const ConsultationDetailPage({
    super.key,
    required this.consultationId,
    required this.viewerRole,
  });

  @override
  State<ConsultationDetailPage> createState() => _ConsultationDetailPageState();
}

class _ConsultationDetailPageState extends State<ConsultationDetailPage> {
  final _fs = FirestoreService.instance;
  final _answerCtrl = TextEditingController();
  bool _isSubmitting = false;

  // 🔥 1. 스트림과 퓨처를 저장할 변수 선언
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _consultStream;
  Future<DocumentSnapshot<Map<String, dynamic>>>? _mentyFuture;
  String? _cachedMentyUid;

  @override
  void initState() {
    super.initState();
    // 🔥 2. 화면이 켜질 때 스트림을 딱 한 번만 생성해서 변수에 저장
    _consultStream = _fs.consultationStream(widget.consultationId);
  }

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  // 금액 포맷터
  String _formatMoney(int amount) {
    if (amount == 0) return '0원';
    final formatted = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},'
    );
    return '${formatted}원';
  }

  // 나이 계산기
  String _calculateAge(String? birthDate) {
    if (birthDate == null || birthDate.length < 4) return '미상';
    final birthYear = int.tryParse(birthDate.substring(0, 4)) ?? 2000;
    final currentYear = DateTime.now().year;
    return '${currentYear - birthYear + 1}세';
  }

  // 투자 성향 변환
  String _getInvestmentStyle(bool highRisk, bool leverage) {
    if (highRisk && leverage) return '공격투자형';
    if (highRisk) return '적극투자형';
    if (leverage) return '위험중립형';
    return '안정추구형';
  }

  // 시간 계산기
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

  // 답변 제출 로직
  Future<void> _submitAnswer() async {
    final text = _answerCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      await _fs.updateConsultation(widget.consultationId, {
        'answerText': text,
        'status': 'answered',
        'answeredAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('답변이 등록되었습니다.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

@override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        // ... 기존 앱바 코드 ...
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        // 🔥 3. 직접 함수를 호출하지 않고 아까 저장한 변수를 넣습니다.
        stream: _consultStream, 
        builder: (context, consultSnap) {
          if (consultSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!consultSnap.hasData || !consultSnap.data!.exists) {
            return const Center(child: Text('상담 정보를 찾을 수 없습니다.'));
          }

          final consultData = consultSnap.data!.data()!;
          final mentyUid = consultData['mentyUid'] as String;
          final status = consultData['status'] as String;
          
          final rawQuestion = consultData['questionText'] as String? ?? '';
          final qSplit = rawQuestion.split('\n');
          final qTitle = qSplit.first.replaceAll(RegExp(r'[\[\]]'), '').trim();
          final qBody = qSplit.length > 1 ? qSplit.sublist(1).join('\n').trim() : rawQuestion;
          
          final answerText = consultData['answerText'] as String? ?? '';
          final createdAt = consultData['createdAt'];

          // 🔥 4. mentyUid를 확인한 후, 처음 한 번만 퓨처를 생성해서 저장합니다.
          if (_cachedMentyUid != mentyUid) {
            _cachedMentyUid = mentyUid;
            _mentyFuture = _fs.getUserDoc(mentyUid);
          }

          return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            // 🔥 5. 직접 호출 대신 저장된 퓨처 변수를 넣습니다.
            future: _mentyFuture,
            builder: (context, userSnap) {
              if (userSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final mentyData = userSnap.data?.data() ?? {};
              
              
              // 멘티 기본 정보
              final name = (mentyData['name'] ?? '익명') as String;
              final initials = name.isNotEmpty ? name.substring(0, 1) : '?';
              final ageStr = _calculateAge(mentyData['birthDate'] as String?);
              final job = (mentyData['job'] ?? '직업미상') as String;
              final address = (mentyData['address'] ?? '지역미상') as String;
              final style = _getInvestmentStyle(mentyData['riskHighReturn'] == true, mentyData['wantLeverage'] == true);

              // 재무 데이터 계산
              final mainProfit = (mentyData['mainProfit'] as num?)?.toInt() ?? 0;
              final subProfit = (mentyData['subProfit'] as num?)?.toInt() ?? 0;
              final totalIncome = mainProfit + subProfit;

              final deposit = (mentyData['deposit'] as num?)?.toInt() ?? 0;
              final saving = (mentyData['saving'] as num?)?.toInt() ?? 0;
              final stock = (mentyData['stock'] as num?)?.toInt() ?? 0;
              final fund = (mentyData['fund'] as num?)?.toInt() ?? 0;
              final otherPortfolio = (mentyData['otherPortfolio'] as num?)?.toInt() ?? 0;
              final totalAssets = deposit + saving + stock + fund + otherPortfolio;

              final fixedSpending = (mentyData['fixedSpending'] as num?)?.toInt() ?? 0;
              final netIncome = totalIncome - fixedSpending;
              final savingRate = totalIncome > 0 ? (netIncome / totalIncome * 100).clamp(0, 100).toStringAsFixed(1) : '0.0';

              final goal = (mentyData['savingGoal'] ?? mentyData['goal'] ?? '목표 없음') as String;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. 프로필 요약 카드
                    _buildProfileHeader(initials, name, ageStr, job, address, style, colorScheme),
                    const SizedBox(height: 16),

                    // 2. 수입 정보
                    _buildFinancialBox(
                      title: '수입 정보',
                      icon: Icons.attach_money,
                      iconColor: Colors.greenAccent,
                      items: {'주 수익 (월)': mainProfit, '부 수익 (월)': subProfit},
                      totalLabel: '총 수입 (월)',
                      totalValue: totalIncome,
                      totalColor: Colors.greenAccent,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 16),

                    // 3. 보유 자산
                    _buildFinancialBox(
                      title: '보유 자산',
                      icon: Icons.domain,
                      iconColor: const Color(0xFF00B4DB),
                      items: {'예금': deposit, '적금': saving, '주식': stock, '펀드': fund, '기타': otherPortfolio},
                      totalLabel: '총 자산',
                      totalValue: totalAssets,
                      totalColor: const Color(0xFF00B4DB),
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 16),

                    // 4. 고정 지출
                    _buildFinancialBox(
                      title: '고정 지출 (월)',
                      icon: Icons.receipt_long,
                      iconColor: Colors.orangeAccent,
                      items: {'월별 고정 지출액': fixedSpending}, // 기존 DB 구조에 맞춤
                      totalLabel: '총 고정 지출',
                      totalValue: fixedSpending,
                      totalColor: Colors.orangeAccent,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 16),

                    // 5. 재무 요약
                    _buildSummaryBox(netIncome, savingRate, colorScheme),
                    const SizedBox(height: 16),

                    // 6. 설정한 목표
                    _buildGoalBox(goal, colorScheme),
                    const SizedBox(height: 16),

                    // 7. 멘티 질문 내용
                    _buildQuestionBox(qTitle, qBody, _timeAgo(createdAt), colorScheme),
                    const SizedBox(height: 16),

                    // 8. 전문가 답변 영역
                    _buildAnswerSection(status, answerText, colorScheme),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // UI 컴포넌트: 프로필 헤더
  Widget _buildProfileHeader(String initials, String name, String age, String job, String address, String style, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF00B4DB),
                child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(age, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.work_outline, size: 14, color: Color(0xFF00B4DB)),
              const SizedBox(width: 4),
              Expanded(child: Text(job, style: const TextStyle(fontSize: 13))),
              const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF00B4DB)),
              const SizedBox(width: 4),
              Expanded(child: Text(address, style: const TextStyle(fontSize: 13))),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.trending_up, size: 14, color: Colors.amber),
                const SizedBox(width: 6),
                Text(style, style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // UI 컴포넌트: 재무 박스 (수입, 자산, 지출 공통)
  Widget _buildFinancialBox({
    required String title, required IconData icon, required Color iconColor,
    required Map<String, int> items, required String totalLabel, required int totalValue, required Color totalColor, required ColorScheme colorScheme
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ...items.entries.where((e) => e.value > 0).map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e.key, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                Text(_formatMoney(e.value), style: TextStyle(color: iconColor.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          )),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(totalLabel, style: const TextStyle(fontSize: 14)),
              Text(_formatMoney(totalValue), style: TextStyle(color: totalColor, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  // UI 컴포넌트: 재무 요약 박스
  Widget _buildSummaryBox(int netIncome, String savingRate, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF00B4DB).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00B4DB).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF00B4DB), size: 18),
              SizedBox(width: 8),
              Text('재무 요약', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('월 순수입', style: TextStyle(color: Colors.grey, fontSize: 13)),
              Text(_formatMoney(netIncome), style: const TextStyle(color: Color(0xFF00B4DB), fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('저축률', style: TextStyle(color: Colors.grey, fontSize: 13)),
              Text('$savingRate%', style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  // UI 컴포넌트: 설정한 목표 박스
  Widget _buildGoalBox(String goal, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.track_changes, color: Colors.amber, size: 18),
              SizedBox(width: 8),
              Text('설정한 목표', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00B4DB).withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF00B4DB).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.home_outlined, color: Color(0xFF00B4DB)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('저축 목표', style: TextStyle(color: Color(0xFF00B4DB), fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(goal, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // UI 컴포넌트: 질문 박스
  Widget _buildQuestionBox(String title, String body, String timeAgo, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(timeAgo, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(body, style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.white70)),
        ],
      ),
    );
  }

  // UI 컴포넌트: 전문가 답변 영역
  Widget _buildAnswerSection(String status, String answerText, ColorScheme colorScheme) {
    if (status == 'answered') {
      // 답변이 완료된 상태 (멘토/멘티 공통 열람)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('전문가 답변', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF00B4DB).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00B4DB).withOpacity(0.3)),
            ),
            child: Text(answerText, style: const TextStyle(fontSize: 14, height: 1.6)),
          ),
        ],
      );
    } else if (widget.viewerRole == 'mentor') {
      // 멘토가 답변을 달아야 하는 폼 상태
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('전문가 답변', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _answerCtrl,
            maxLines: 8,
            maxLength: 500,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '상담 답변을 작성해주세요...',
              counterText: '',
              fillColor: colorScheme.surface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${500 - _answerCtrl.text.length}자 남음', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitAnswer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0096C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16), // 🔥 양옆 여백 추가!
                  ),
                  icon: _isSubmitting 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send, size: 16),
                  label: const Text('답변 보내기', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // 멘티가 아직 답변을 기다리는 상태
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        ),
        child: const Center(
          child: Text('전문가의 답변을 기다리고 있습니다.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }
  }
}