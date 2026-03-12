// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  static bool _isInitialized = false;

 
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await GoogleSignIn.instance.initialize(serverClientId: '386925733059-h8hgv538ro27qfmp0j7ap8emntf62dj1.apps.googleusercontent.com');
      _isInitialized = true;
    }
  }
// 💡 이메일 관련 함수는 모두 삭제하고 구글 로그인만 남겼습니다.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _ensureInitialized();

      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final docRef = _fs.collection('users').doc(user.uid);
        final docSnap = await docRef.get();

        if (!docSnap.exists) {
          await docRef.set({
            'uid': user.uid,
            'email': user.email ?? '',
            'name': user.displayName ?? '',
            'role': 'menty',
            'onboardingDone': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
      return userCredential;
    } catch (e) {
      print('구글 로그인 에러: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }
}