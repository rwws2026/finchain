//lib/features/shared/consultation_detail_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/firestore_service.dart';

class ConsultationDetailPage extends StatefulWidget {
  const ConsultationDetailPage({
    super.key,
    required this.consultationId,
    required this.viewerRole, // mentor | menty
  });

  final String consultationId;
  final String viewerRole;

  @override
  State<ConsultationDetailPage> createState() => _ConsultationDetailPageState();
}

class _ConsultationDetailPageState extends State<ConsultationDetailPage> {
  final _fs = FirestoreService.instance;
  final _answerCtrl = TextEditingController();
  final _rejectCtrl = TextEditingController();
  final _followCtrl = TextEditingController();

  bool _loading = false;
  double _rating = 5.0;
  bool _recommend = false;

  @override
  void dispose() {
    _answerCtrl.dispose();
    _rejectCtrl.dispose();
    _followCtrl.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    setState(() => _loading = true);
    try {
      await _fs.acceptConsultation(consultationId: widget.consultationId);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reject() async {
    final reason = _rejectCtrl.text.trim();
    if (reason.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;

    setState(() => _loading = true);
    try {
      await _fs.rejectConsultation(
        consultationId: widget.consultationId,
        mentorUid: uid,
        reason: reason,
      );
      _rejectCtrl.clear();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _answer() async {
    final text = _answerCtrl.text.trim();
    if (text.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;

    setState(() => _loading = true);
    try {
      await _fs.answerConsultation(
        consultationId: widget.consultationId,
        mentorUid: uid,
        answerText: text,
      );
      _answerCtrl.clear();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addFollowUp() async {
    final text = _followCtrl.text.trim();
    if (text.isEmpty) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;

    setState(() => _loading = true);
    try {
      await _fs.addFollowUpQuestion(
        consultationId: widget.consultationId,
        mentyUid: uid,
        text: text,
      );
      _followCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('추가 질문을 보냈어.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitReview({
    required String mentorUid,
    required String mentyUid,
  }) async {
    setState(() => _loading = true);
    try {
      await _fs.submitMentorReview(
        consultationId: widget.consultationId,
        mentorUid: mentorUid,
        mentyUid: mentyUid,
        rating: _rating,
        recommend: _recommend,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('평가를 저장했어.')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _portfolio(Map<String, dynamic> p) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          '주수익: ${p['mainProfit'] ?? 0}\n'
          '부수익: ${p['subProfit'] ?? 0}\n'
          '예금: ${p['deposit'] ?? 0}\n'
          '적금: ${p['saving'] ?? 0}\n'
          '주식: ${p['stock'] ?? 0}\n'
          '펀드: ${p['fund'] ?? 0}\n'
          '기타 재테크 포트폴리오: ${p['otherPortfolio'] ?? 0}\n'
          '고정지출: ${p['fixedSpending'] ?? 0}\n'
          '저축 목표: ${p['savingGoal'] ?? '-'}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('상담 상세')),
      body: StreamBuilder(
        stream: _fs.consultationStream(widget.consultationId),
        builder: (context, consultationSnap) {
          if (!consultationSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = consultationSnap.data!.data() ?? {};
          final status = (data['status'] ?? '') as String;
          final questionText = (data['questionText'] ?? '') as String;
          final answerText = (data['answerText'] ?? '') as String;
          final rejectReason = (data['rejectReason'] ?? '') as String;
          final followUpCount = (data['followUpCount'] ?? 0) as int;
          final mentorUid = (data['mentorUid'] ?? '') as String;
          final mentyUid = (data['mentyUid'] ?? '') as String;
          final portfolio =
              (data['portfolioSnapshot'] ?? <String, dynamic>{})
                  as Map<String, dynamic>;

          return StreamBuilder(
            stream: _fs.consultationMessagesStream(widget.consultationId),
            builder: (context, messageSnap) {
              if (!messageSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final messages = messageSnap.data!.docs;

              return FutureBuilder<bool>(
                future: widget.viewerRole == 'menty' && status == 'answered'
                    ? _fs.hasReview(
                        consultationId: widget.consultationId,
                        mentyUid: myUid,
                      )
                    : Future.value(false),
                builder: (context, reviewSnap) {
                  final reviewed = reviewSnap.data == true;

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: ListTile(
                          title: const Text('최초 질문'),
                          subtitle: Text(questionText),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _portfolio(portfolio),
                      const SizedBox(height: 8),
                      const Text(
                        '대화 내용',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...messages.map((m) {
                        final d = m.data();
                        final senderRole = (d['senderRole'] ?? '') as String;
                        final type = (d['type'] ?? '') as String;
                        final text = (d['text'] ?? '') as String;

                        return Card(
                          child: ListTile(
                            title: Text('$senderRole / $type'),
                            subtitle: Text(text),
                          ),
                        );
                      }),
                      if (rejectReason.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Card(
                          child: ListTile(
                            title: const Text('거절 사유'),
                            subtitle: Text(rejectReason),
                          ),
                        ),
                      ],
                      if (answerText.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Card(
                          child: ListTile(
                            title: const Text('최종 답변'),
                            subtitle: Text(answerText),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      if (widget.viewerRole == 'mentor' && status == 'requested') ...[
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _accept,
                            child: const Text('수락'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _rejectCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: '거절 사유',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _loading ? null : _reject,
                            child: const Text('거절'),
                          ),
                        ),
                      ],

                      if (widget.viewerRole == 'mentor' && status == 'accepted') ...[
                        TextField(
                          controller: _answerCtrl,
                          maxLines: 6,
                          decoration: const InputDecoration(
                            labelText: '상담 답변 작성',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _answer,
                            child: const Text('보내기'),
                          ),
                        ),
                      ],

                      if (widget.viewerRole == 'menty' &&
                          (status == 'accepted' || status == 'answered') &&
                          followUpCount < 3) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _followCtrl,
                          maxLines: 4,
                          maxLength: 300,
                          decoration: const InputDecoration(
                            labelText: '추가 질문',
                            hintText: '최대 3회까지 가능',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _loading ? null : _addFollowUp,
                            child: Text('추가 질문 보내기 (${followUpCount}/3)'),
                          ),
                        ),
                      ],

                      if (widget.viewerRole == 'menty' &&
                          status == 'answered' &&
                          !reviewed) ...[
                        const SizedBox(height: 16),
                        const Text(
                          '멘토 평가',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('별점: ${_rating.toStringAsFixed(1)}'),
                        Slider(
                          value: _rating,
                          min: 0.5,
                          max: 5.0,
                          divisions: 9,
                          label: _rating.toStringAsFixed(1),
                          onChanged: (v) => setState(() => _rating = v),
                        ),
                        CheckboxListTile(
                          value: _recommend,
                          onChanged: (v) =>
                              setState(() => _recommend = v ?? false),
                          title: const Text('이 멘토를 추천할게요'),
                        ),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _loading
                                ? null
                                : () => _submitReview(
                                      mentorUid: mentorUid,
                                      mentyUid: mentyUid,
                                    ),
                            child: const Text('평가 저장'),
                          ),
                        ),
                      ],

                      if (widget.viewerRole == 'menty' &&
                          status == 'answered' &&
                          reviewed)
                        const Card(
                          child: ListTile(
                            title: Text('평가 완료'),
                            subtitle: Text('이미 이 상담에 대한 평가를 저장했어.'),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}