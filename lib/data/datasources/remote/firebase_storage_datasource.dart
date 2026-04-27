import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../core/errors/exceptions.dart';

abstract class FirebaseStorageDataSource {
  Future<String> uploadBackup(String userId, File backupFile);
  Future<File> downloadBackup(String userId, String fileName);
  Future<List<String>> listBackups(String userId);
  Future<void> deleteBackup(String userId, String fileName);
}

class FirebaseStorageDataSourceImpl implements FirebaseStorageDataSource {
  final FirebaseStorage _storage;

  FirebaseStorageDataSourceImpl({required FirebaseStorage storage})
      : _storage = storage;

  @override
  Future<String> uploadBackup(String userId, File backupFile) async {
    try {
      final fileName = 'backup_${DateTime.now().millisecondsSinceEpoch}.db';
      final ref = _storage.ref().child(
          '${FirebaseConstants.userBackupsPath}/$userId/$fileName');

      await ref.putFile(backupFile);
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw ServerException('Không thể upload backup');
    }
  }

  @override
  Future<File> downloadBackup(String userId, String fileName) async {
    try {
      final ref = _storage.ref().child(
          '${FirebaseConstants.userBackupsPath}/$userId/$fileName');

      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/$fileName');

      await ref.writeToFile(file);
      return file;
    } catch (e) {
      throw ServerException('Không thể download backup');
    }
  }

  @override
  Future<List<String>> listBackups(String userId) async {
    try {
      final ref = _storage.ref().child(
          '${FirebaseConstants.userBackupsPath}/$userId');

      final result = await ref.listAll();
      return result.items.map((item) => item.name).toList();
    } catch (e) {
      throw ServerException('Không thể lấy danh sách backup');
    }
  }

  @override
  Future<void> deleteBackup(String userId, String fileName) async {
    try {
      final ref = _storage.ref().child(
          '${FirebaseConstants.userBackupsPath}/$userId/$fileName');

      await ref.delete();
    } catch (e) {
      throw ServerException('Không thể xóa backup');
    }
  }
}
