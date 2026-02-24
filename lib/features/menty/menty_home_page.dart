//lib/features/menty/menty_home_page.dart

import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

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
      body: const Center(child: Text('멘티 홈 화면')),
    );
  }
}
