//../features/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  /// ✅ 기존 코드에서 FirestoreService() 쓰고 있으니, 이렇게 열어준다
  factory FirestoreService() => instance;

  final _db = FirebaseFirestore.instance;

  /// ✅ users/{uid}
  DocumentReference<Map<String, dynamic>> userRef(String uid) =>
      _db.collection('users').doc(uid);

  Stream<DocumentSnapshot<Map<String, dynamic>>> userStream(String uid) =>
      userRef(uid).snapshots();

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDoc(String uid) =>
      userRef(uid).get();

  /// users/{uid} merge 업데이트
  Future<void> updateUserMerge(String uid, Map<String, dynamic> data) async {
    await userRef(uid).set(data, SetOptions(merge: true));
  }

  /// -------------------------
  /// ✅ 기존 코드 호환용 메서드들
  /// -------------------------

  /// signup_form_page.dart에서 쓰는 createUser(...)
  Future<void> createUser({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await updateUserMerge(uid, {
      ...data,
      'createdAt': data['createdAt'] ?? DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// mentor_request_page.dart 등에서 쓰는 updateUser(uid, data)
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await updateUserMerge(uid, {
      ...data,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// mentor_request_page.dart에서 쓰는 createMentorRequest(...)
  Future<DocumentReference<Map<String, dynamic>>> createMentorRequest({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    // ✅ 네 프로젝트 컬렉션명이 다르면 여기만 수정
    final ref = _db.collection('mentor_requests').doc();

    await ref.set({
      ...data,
      'uid': uid,
      'status': data['status'] ?? 'pending',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    return ref;
  }

  /// -------------------------
  /// ✅ 중복 체크 (A안)
  /// -------------------------

  Future<bool> isStudentIdTaken({
    required String studentId,
    required String myUid,
  }) async {
    final q = await _db
        .collection('users')
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .get();

    if (q.docs.isEmpty) return false;
    return q.docs.first.id != myUid;
  }

  Future<bool> isNicknameTaken({
    required String nickname,
    required String myUid,
  }) async {
    final q = await _db
        .collection('users')
        .where('nickname', isEqualTo: nickname)
        .limit(1)
        .get();

    if (q.docs.isEmpty) return false;
    return q.docs.first.id != myUid;
  }
}