//lib/features/mentor/mentor_pending_page.dart

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class MentorPendingPage extends StatelessWidget {
  final String status; // pending/rejected/suspended/...
  const MentorPendingPage({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final text = switch (status) {
      'pending' => '현재 멘토 심사 진행 중입니다.',
      'rejected' => '멘토 심사가 반려되었습니다. 재신청이 필요합니다.',
      'suspended' => '멘토 계정이 정지되었습니다.',
      _ => '멘토 상태: $status',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('멘토 상태'),
        actions: [
          IconButton(
            onPressed: () => AuthService().signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(child: Text(text)),
    );
  }
}
