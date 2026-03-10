// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'routing/auth_gate.dart';
import 'theme/app_theme.dart'; // 테마 파일 임포트 추가

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const PinChainApp());
}

class PinChainApp extends StatelessWidget {
  const PinChainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinChain',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, // 라이트 테마 연결
      darkTheme: AppTheme.darkTheme, // 다크 테마 연결
      themeMode: ThemeMode.system, // 시스템 설정(라이트/다크)에 따라 자동 전환
      home: const AuthGate(),
    );
  }
}