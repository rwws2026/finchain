// lib/features/menty/pages/consultation_request_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../services/firestore_service.dart';

class ConsultationRequestPage extends StatefulWidget {
  const ConsultationRequestPage({super.key, required this.mentorUid});

  final String mentorUid;

  @override
  State<ConsultationRequestPage> createState() => _ConsultationRequestPageState();
}

class _ConsultationRequestPageState extends State<ConsultationRequestPage> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _fs = FirestoreService.instance;

  bool _loading = false;
  String? _err;

// 1. Future를 저장할 변수를 선언합니다.
  late Future<List<dynamic>> _initialDataFuture;

  // UI 포인트 컬러
  final Color pointColor = const Color(0xFF0096C7);
  final Color goldColor = const Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    // 2. initState에서 데이터를 딱 한 번만 불러오도록 설정합니다.
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _initialDataFuture = Future.wait([
      _fs.getUserDoc(uid),
      _fs.getUserDoc(widget.mentorUid),
      _fs.getMentorProfile(widget.mentorUid),
    ]);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  // 금액 포맷터 (예: 5000000 -> 500만)
  String _formatMoney(int amount) {
    if (amount == 0) return '0원';
    if (amount >= 10000) {
      return '${NumberFormat('#,###').format(amount ~/ 10000)}만';
    }
    return '${NumberFormat('#,###').format(amount)}';
  }

  // 나이 계산기
  String _calculateAge(String birthDate) {
    if (birthDate.isEmpty || birthDate.length < 4) return '미상';
    final birthYear = int.tryParse(birthDate.substring(0, 4)) ?? 2000;
    final currentYear = DateTime.now().year;
    return '${currentYear - birthYear + 1}세';
  }

  // 투자 성향 텍스트 변환
  String _getInvestmentStyle(bool highRisk, bool leverage) {
    if (highRisk && leverage) return '공격투자형';
    if (highRisk) return '적극투자형';
    if (leverage) return '위험중립형';
    return '안정추구형';
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();

    if (title.isEmpty) {
      setState(() => _err = '상담 제목을 입력해줘.');
      return;
    }
    if (content.isEmpty) {
      setState(() => _err = '질문 내용을 입력해줘.');
      return;
    }
    if (content.length > 300) {
      setState(() => _err = '질문은 300자 이하로 작성해줘.');
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() {
      _loading = true;
      _err = null;
    });

    try {
      // 기존 백엔드 호환성을 위해 제목과 내용을 합쳐서 전송
      final questionText = '[$title]\n$content';

      await _fs.createConsultation(
        mentorUid: widget.mentorUid,
        mentyUid: uid,
        questionText: questionText,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('상담 신청이 완료되었습니다.')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('로그인 에러')));

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('상담 문의', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.monetization_on, color: goldColor, size: 16),
                const SizedBox(width: 4),
                const Text('100', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
      body: FutureBuilder(
        // 멘티 정보와 멘토 정보를 동시에 불러옵니다.
        future: _initialDataFuture,
        builder: (context, AsyncSnapshot<List<dynamic>> snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return const Center(child: Text('데이터를 불러오는데 실패했습니다.'));
          }

          final mentyData = snap.data![0].data() as Map<String, dynamic>? ?? {};
          final mentorUserData = snap.data![1].data() as Map<String, dynamic>? ?? {};
          final mentorProfileData = snap.data![2].data() as Map<String, dynamic>? ?? {};

          // 멘토 정보 파싱
          final mentorName = (mentorUserData['name'] ?? '이름 없음') as String;
          final mentorNickname = (mentorProfileData['nickname'] ?? mentorName) as String;
          final mentorSpecialty = (mentorProfileData['specialty'] ?? '') as String;
          final mentorTags = mentorSpecialty.split(',').where((e) => e.trim().isNotEmpty).toList();
          final mentorRating = ((mentorProfileData['averageRat  ing'] ?? 4.9) as num).toDouble();
          final mentorInitials = mentorNickname.isNotEmpty ? mentorNickname.substring(0, 2).toUpperCase() : 'M';

          // 멘티(내) 정보 파싱
          final ageStr = _calculateAge(mentyData['birthDate']?.toString() ?? '');
          final job = mentyData['job']?.toString() ?? '미입력';
          final address = mentyData['address']?.toString() ?? '미입력';
          final investmentStyle = _getInvestmentStyle(mentyData['riskHighReturn'] == true, mentyData['wantLeverage'] == true);
          
          final mainProfit = (mentyData['mainProfit'] as num?)?.toInt() ?? 0;
          final subProfit = (mentyData['subProfit'] as num?)?.toInt() ?? 0;
          final totalAssets = ((mentyData['deposit'] ?? 0) as num) + 
                              ((mentyData['saving'] ?? 0) as num) + 
                              ((mentyData['stock'] ?? 0) as num) + 
                              ((mentyData['fund'] ?? 0) as num) + 
                              ((mentyData['otherPortfolio'] ?? 0) as num);
          final savingGoal = mentyData['savingGoal']?.toString() ?? '미입력';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 멘토 프로필 요약 카드
                _buildMentorHeader(mentorNickname, mentorInitials, mentorTags, mentorRating, colorScheme),
                const SizedBox(height: 16),

                // 2. 상담 비용 안내
                _buildCostBanner(colorScheme),
                const SizedBox(height: 24),

                // 3. 전문가에게 공유되는 정보
                _buildSharedInfoSection(
                  colorScheme: colorScheme,
                  age: ageStr,
                  job: job,
                  address: address,
                  style: investmentStyle,
                  mainP: mainProfit,
                  subP: subProfit,
                  total: totalAssets.toInt(),
                  goal: savingGoal,
                ),
                const SizedBox(height: 24),

                // 4. 입력 폼 (제목, 내용)
                _buildInputSection(colorScheme),
                const SizedBox(height: 24),

                // 5. 상담 신청 버튼
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: pointColor,
                      foregroundColor: Colors.white,
                    ),
                    icon: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send, size: 18),
                    label: Text(_loading ? '처리 중...' : '상담 신청하기', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),

                // 6. 하단 안내문
                _buildNoticeSection(colorScheme),
                const SizedBox(height: 40), // 하단 여백
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMentorHeader(String nickname, String initials, List<String> tags, double rating, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: pointColor,
              child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nickname, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (tags.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: pointColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: pointColor.withOpacity(0.3)),
                        ),
                        child: Text(tags.first, style: TextStyle(fontSize: 10, color: pointColor)),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Icon(Icons.star, color: goldColor, size: 14),
                    const SizedBox(width: 4),
                    Text('$rating', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const Text(' · 15년 이상', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostBanner(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: goldColor.withOpacity(0.05),
        border: Border.all(color: goldColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.monetization_on_outlined, color: goldColor, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('상담 비용', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: '1회 상담 '),
                    TextSpan(text: '10 코인', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
                    const TextSpan(text: '이 차감됩니다'),
                  ],
                ),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSharedInfoSection({
    required ColorScheme colorScheme,
    required String age,
    required String job,
    required String address,
    required String style,
    required int mainP,
    required int subP,
    required int total,
    required String goal,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('전문가에게 공유되는 정보', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('더 정확한 상담을 위해 아래 정보가 전문가에게 전달됩니다', style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.6))),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              _buildInfoRow(Icons.person_outline, '기본 정보', pointColor, [
                _buildSubInfo('나이', age), _buildSubInfo('직업', job),
                _buildSubInfo('지역', address), _buildSubInfo('투자성향', style),
              ]),
              const Divider(height: 24),
              _buildInfoRow(Icons.attach_money, '수입 정보', Colors.green, [
                _buildSubInfo('주 수익', '₩${_formatMoney(mainP)}'), _buildSubInfo('부 수익', '₩${_formatMoney(subP)}'),
              ]),
              const Divider(height: 24),
              _buildInfoRow(Icons.account_balance_wallet_outlined, '보유 자산', pointColor, [
                _buildSubInfo('총 자산', '₩${_formatMoney(total)}'),
              ]),
              const Divider(height: 24),
              _buildInfoRow(Icons.flag_outlined, '설정한 목표', goldColor, [
                _buildSubInfo('내용', goal),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String title, Color iconColor, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: children.map((w) => SizedBox(width: 140, child: w)).toList(),
        ),
      ],
    );
  }

  Widget _buildSubInfo(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 50, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildInputSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('제목', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: _titleCtrl,
          decoration: const InputDecoration(hintText: '상담 제목을 입력하세요'),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('문의 내용', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text('${_contentCtrl.text.length}/300', style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.5))),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _contentCtrl,
          maxLines: 6,
          maxLength: 300,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: '상담받고 싶은 내용을 자세히 작성해주세요\n\n예시:\n- 현재 상황\n- 목표\n- 궁금한 점',
            counterText: '', // 기본 카운터 숨김
          ),
        ),
        if (_err != null) ...[
          const SizedBox(height: 8),
          Text(_err!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
        ]
      ],
    );
  }

  Widget _buildNoticeSection(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('상담 안내', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          _noticeItem('전문가 답변까지 1~3일이 소요됩니다'),
          _noticeItem('구체적으로 작성할수록 더 나은 답변을 받을 수 있습니다'),
          _noticeItem('답변은 마이페이지에서 확인할 수 있습니다'),
          _noticeItem('코인은 상담 신청 즉시 차감됩니다'),
        ],
      ),
    );
  }

  Widget _noticeItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 6),
            child: CircleAvatar(radius: 2, backgroundColor: Colors.grey),
          ),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12))),
        ],
      ),
    );
  }
}