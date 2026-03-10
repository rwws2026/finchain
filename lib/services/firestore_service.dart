//../features/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';


class FirestoreService {
  FirestoreService._();
  static final instance = FirestoreService._();

  factory FirestoreService() => instance;

  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> userRef(String uid) =>
      _db.collection('users').doc(uid);

  Stream<DocumentSnapshot<Map<String, dynamic>>> userStream(String uid) =>
      userRef(uid).snapshots();

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDoc(String uid) =>
      userRef(uid).get();

  Future<void> updateUserMerge(String uid, Map<String, dynamic> data) async {
    await userRef(uid).set(data, SetOptions(merge: true));
  }
  // 상담 내용 업데이트 (답변 등록 등)
  Future<void> updateConsultation(String consultationId, Map<String, dynamic> data) async {
    await FirebaseFirestore.instance
        .collection('consultations')
        .doc(consultationId)
        .update(data);
  }
  
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

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await updateUserMerge(uid, {
      ...data,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<DocumentReference<Map<String, dynamic>>> createMentorRequest({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
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

  // ---------------------------
  // mentor_profiles
  // ---------------------------

  DocumentReference<Map<String, dynamic>> mentorProfileRef(String uid) =>
      _db.collection('mentor_profiles').doc(uid);

  Future<DocumentSnapshot<Map<String, dynamic>>> getMentorProfile(String uid) =>
      mentorProfileRef(uid).get();

  Stream<DocumentSnapshot<Map<String, dynamic>>> mentorProfileStream(
    String uid,
  ) =>
      mentorProfileRef(uid).snapshots();

  Future<void> createOrUpdateMentorProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await mentorProfileRef(uid).set({
      ...data,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> mentorsStream() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'mentor')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> mentorProfilesByScoreStream() {
    return _db
        .collection('mentor_profiles')
        .orderBy('score', descending: true)
        .orderBy('recommendCount', descending: true)
        .snapshots();
  }

  // ---------------------------
  // consultations
  // ---------------------------

  CollectionReference<Map<String, dynamic>> get consultationsRef =>
      _db.collection('consultations');

  CollectionReference<Map<String, dynamic>> consultationMessagesRef(
    String consultationId,
  ) =>
      consultationsRef.doc(consultationId).collection('messages');

  Future<String> createConsultation({
    required String mentorUid,
    required String mentyUid,
    required String questionText,
  }) async {
    final userDoc = await getUserDoc(mentyUid);
    final user = userDoc.data() ?? {};

    final ref = consultationsRef.doc();

    final payload = {
      'consultationId': ref.id,
      'mentorUid': mentorUid,
      'mentyUid': mentyUid,
      'status': 'requested', // requested / accepted / rejected / answered
      'questionText': questionText,
      'answerText': '',
      'rejectReason': '',
      'mentyName': (user['name'] ?? '') as String,
      'mentyNickname': (user['nickname'] ?? '') as String,
      'requestedAt': DateTime.now().toIso8601String(),
      'acceptedAt': null,
      'answeredAt': null,
      'rejectedAt': null,
      'closedAt': null,
      'followUpCount': 0,
      'portfolioSnapshot': {
        'mainProfit': (user['mainProfit'] ?? 0),
        'subProfit': (user['subProfit'] ?? 0),
        'deposit': (user['deposit'] ?? 0),
        'saving': (user['saving'] ?? 0),
        'stock': (user['stock'] ?? 0),
        'fund': (user['fund'] ?? 0),
        'otherPortfolio': (user['otherPortfolio'] ?? 0),
        'fixedSpending': (user['fixedSpending'] ?? 0),
        'savingGoal': (user['savingGoal'] ?? user['goal'] ?? ''),
      },
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    await ref.set(payload);

    await addConsultationMessage(
      consultationId: ref.id,
      senderUid: mentyUid,
      senderRole: 'menty',
      type: 'question',
      text: questionText,
    );

    return ref.id;
  }

  Future<void> addConsultationMessage({
    required String consultationId,
    required String senderUid,
    required String senderRole,
    required String type, // question / follow_up / answer / reject_reason
    required String text,
  }) async {
    final ref = consultationMessagesRef(consultationId).doc();
    await ref.set({
      'messageId': ref.id,
      'senderUid': senderUid,
      'senderRole': senderRole,
      'type': type,
      'text': text,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> acceptConsultation({
    required String consultationId,
  }) async {
    await consultationsRef.doc(consultationId).set({
      'status': 'accepted',
      'acceptedAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> rejectConsultation({
    required String consultationId,
    required String mentorUid,
    required String reason,
  }) async {
    await consultationsRef.doc(consultationId).set({
      'status': 'rejected',
      'rejectReason': reason,
      'rejectedAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      'closedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    await addConsultationMessage(
      consultationId: consultationId,
      senderUid: mentorUid,
      senderRole: 'mentor',
      type: 'reject_reason',
      text: reason,
    );
  }

  Future<void> answerConsultation({
    required String consultationId,
    required String mentorUid,
    required String answerText,
  }) async {
    await consultationsRef.doc(consultationId).set({
      'status': 'answered',
      'answerText': answerText,
      'answeredAt': DateTime.now().toIso8601String(),
      'closedAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    await addConsultationMessage(
      consultationId: consultationId,
      senderUid: mentorUid,
      senderRole: 'mentor',
      type: 'answer',
      text: answerText,
    );

    final doc = await consultationsRef.doc(consultationId).get();
    final data = doc.data() ?? {};
    final mentorUidValue = (data['mentorUid'] ?? '') as String;
    if (mentorUidValue.isNotEmpty) {
      await incrementMentorConsultCount(mentorUidValue);
    }
  }

  Future<void> addFollowUpQuestion({
    required String consultationId,
    required String mentyUid,
    required String text,
  }) async {
    final doc = await consultationsRef.doc(consultationId).get();
    final data = doc.data() ?? {};
    final count = (data['followUpCount'] ?? 0) as int;
    if (count >= 3) {
      throw Exception('추가 질문은 최대 3회까지 가능해.');
    }

    await consultationsRef.doc(consultationId).set({
      'followUpCount': count + 1,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    await addConsultationMessage(
      consultationId: consultationId,
      senderUid: mentyUid,
      senderRole: 'menty',
      type: 'follow_up',
      text: text,
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> consultationsForMentyStream(
    String mentyUid, {
    List<String>? statuses,
  }) {
    Query<Map<String, dynamic>> q = consultationsRef.where(
      'mentyUid',
      isEqualTo: mentyUid,
    );

    if (statuses != null && statuses.isNotEmpty) {
      q = q.where('status', whereIn: statuses);
    }

    return q.orderBy('updatedAt', descending: true).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> consultationsForMentorStream(
    String mentorUid, {
    List<String>? statuses,
  }) {
    Query<Map<String, dynamic>> q = consultationsRef.where(
      'mentorUid',
      isEqualTo: mentorUid,
    );

    if (statuses != null && statuses.isNotEmpty) {
      q = q.where('status', whereIn: statuses);
    }

    return q.orderBy('updatedAt', descending: true).snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> consultationStream(
    String consultationId,
  ) =>
      consultationsRef.doc(consultationId).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> consultationMessagesStream(
    String consultationId,
  ) =>
      consultationMessagesRef(consultationId)
          .orderBy('createdAt', descending: false)
          .snapshots();

  // ---------------------------
  // mentor_reviews
  // ---------------------------

  CollectionReference<Map<String, dynamic>> get mentorReviewsRef =>
      _db.collection('mentor_reviews');

  Future<void> submitMentorReview({
    required String consultationId,
    required String mentorUid,
    required String mentyUid,
    required double rating,
    required bool recommend,
  }) async {
    final reviewDocId = '${consultationId}_$mentyUid';
    await mentorReviewsRef.doc(reviewDocId).set({
      'reviewId': reviewDocId,
      'consultationId': consultationId,
      'mentorUid': mentorUid,
      'mentyUid': mentyUid,
      'rating': double.parse(rating.toStringAsFixed(1)),
      'recommend': recommend,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    await recalculateMentorScore(mentorUid);
  }

  Future<bool> hasReview({
    required String consultationId,
    required String mentyUid,
  }) async {
    final reviewDocId = '${consultationId}_$mentyUid';
    final doc = await mentorReviewsRef.doc(reviewDocId).get();
    return doc.exists;
  }

  Future<void> incrementMentorConsultCount(String mentorUid) async {
    final doc = await getMentorProfile(mentorUid);
    final data = doc.data() ?? {};
    final count = (data['consultCount'] ?? 0) as int;
    await createOrUpdateMentorProfile(
      uid: mentorUid,
      data: {'consultCount': count + 1},
    );
    await recalculateMentorScore(mentorUid);
  }

  Future<void> recalculateMentorScore(String mentorUid) async {
    final q = await mentorReviewsRef
        .where('mentorUid', isEqualTo: mentorUid)
        .get();

    double ratingSum = 0;
    int reviewCount = 0;
    int recommendCount = 0;

    for (final d in q.docs) {
      final data = d.data();
      final rating = ((data['rating'] ?? 0) as num).toDouble();
      final recommend = (data['recommend'] == true);
      ratingSum += rating;
      reviewCount += 1;
      if (recommend) recommendCount += 1;
    }

    double averageRating = 0;
    if (reviewCount > 0) {
      averageRating = ratingSum / reviewCount;
    }
    averageRating = double.parse(averageRating.toStringAsFixed(1));

    final score = recommendCount * (1 + averageRating / 5);
    final roundedScore = double.parse(score.toStringAsFixed(1));

    await createOrUpdateMentorProfile(
      uid: mentorUid,
      data: {
        'averageRating': averageRating,
        'recommendCount': recommendCount,
        'score': roundedScore,
      },
    );
  }
  
  Future<void> submitRating({
    required String consultationId,
    required String mentorUid,
    required double rating,
    required bool recommended,
  }) async {
    final consultRef = _db.collection('consultations').doc(consultationId);
    final mentorRef = _db.collection('mentor_profiles').doc(mentorUid);

    await _db.runTransaction((tx) async {
      final mentorSnap = await tx.get(mentorRef);

      final data = mentorSnap.data() ?? {};

      final double ratingAvg = (data['ratingAvg'] ?? 0).toDouble();
      final int ratingCount = (data['ratingCount'] ?? 0);
      final int recommendCount = (data['recommendCount'] ?? 0);

      final newCount = ratingCount + 1;
      final newAvg = ((ratingAvg * ratingCount) + rating) / newCount;

      final newRecommend = recommended ? recommendCount + 1 : recommendCount;

      final score = newRecommend * (1 + newAvg / 5);

      tx.update(consultRef, {
        'rating': rating,
        'recommended': recommended,
        'ratedAt': DateTime.now(),
      });

      tx.set(
        mentorRef,
        {
          'ratingAvg': double.parse(newAvg.toStringAsFixed(1)),
          'ratingCount': newCount,
          'recommendCount': newRecommend,
          'score': score,
        },
        SetOptions(merge: true),
      );
    });
  }
}