//lib/models/app_user.dart

class AppUser {
  final String uid;
  final String role; // "menty" | "mentor"
  final String mentorStatus; // "none" | "pending" | "approved" | "rejected" | "suspended"
  final String name;
  final String nickname;
  final String email;

  AppUser({
    required this.uid,
    required this.role,
    required this.mentorStatus,
    required this.name,
    required this.nickname,
    required this.email,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      role: (data['role'] ?? 'menty') as String,
      mentorStatus: (data['mentorStatus'] ?? 'none') as String,
      name: (data['name'] ?? '') as String,
      nickname: (data['nickname'] ?? '') as String,
      email: (data['email'] ?? '') as String,
    );
  }
}
