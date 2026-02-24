//lib/services/storage_service.dart

import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;

  /// licenseImage 업로드 예시: mentor_licenses/{uid}/{timestamp}.jpg
  Future<String> uploadMentorLicenseImage({
    required String uid,
    required Uint8List bytes,
    required String contentType, // "image/jpeg" 등
  }) async {
    final path = 'mentor_licenses/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child(path);

    final meta = SettableMetadata(contentType: contentType);
    await ref.putData(bytes, meta);

    // 저장은 URL이 아니라 "경로"로 저장하는 걸 추천 (rules/권한 관리 편함)
    return path;
  }

  Future<String> getDownloadUrl(String path) async {
    return _storage.ref().child(path).getDownloadURL();
  }
}
