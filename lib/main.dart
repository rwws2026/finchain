//lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'routing/auth_gate.dart';

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
      title: 'PinChain',
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}
