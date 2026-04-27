import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user.dart';
import '../models/user_model.dart';

class FirestoreUserService {
  static final FirestoreUserService _instance =
      FirestoreUserService._internal();
  factory FirestoreUserService() => _instance;
  FirestoreUserService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';

  // Tạo hoặc cập nhật user trong Firestore
  Future<void> createOrUpdateUser(User user) async {
    try {
      final userModel = UserModel.fromEntity(user);
      await _firestore
          .collection(_usersCollection)
          .doc(user.id)
          .set(userModel.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to create/update user: $e');
    }
  }

  // Tìm user theo ID
  Future<User?> getUserById(String userId) async {
    try {
      final doc =
          await _firestore.collection(_usersCollection).doc(userId).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return UserModel.fromJson(doc.data()!);
    } catch (e) {
      return null;
    }
  }

  // Tìm user theo unique identifier hoặc email
  Future<User?> findUserByIdentifier(String identifier) async {
    try {
      // Tìm theo unique identifier trước
      final queryByIdentifier = await _firestore
          .collection(_usersCollection)
          .where('unique_identifier', isEqualTo: identifier)
          .limit(1)
          .get();

      if (queryByIdentifier.docs.isNotEmpty) {
        return UserModel.fromJson(queryByIdentifier.docs.first.data());
      }

      // Nếu không tìm thấy, tìm theo email
      final queryByEmail = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: identifier)
          .limit(1)
          .get();

      if (queryByEmail.docs.isNotEmpty) {
        return UserModel.fromJson(queryByEmail.docs.first.data());
      }

      return null;
    } catch (e) {
      throw Exception('Failed to find user: $e');
    }
  }

  // Tìm kiếm users theo query
  Future<List<User>> searchUsers(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final lowercaseQuery = query.toLowerCase();
      final List<User> results = [];

      // Tìm theo unique identifier (exact match và prefix)
      try {
        final identifierQuery = await _firestore
            .collection(_usersCollection)
            .where('unique_identifier', isGreaterThanOrEqualTo: lowercaseQuery)
            .where('unique_identifier', isLessThan: '${lowercaseQuery}z')
            .limit(10)
            .get();

        for (final doc in identifierQuery.docs) {
          final user = UserModel.fromJson(doc.data());
          if (!results.any((u) => u.id == user.id)) {
            results.add(user);
          }
        }
      } catch (e) {
        // Ignore identifier search errors
      }

      // Tìm theo email (prefix)
      try {
        final emailQuery = await _firestore
            .collection(_usersCollection)
            .where('email', isGreaterThanOrEqualTo: lowercaseQuery)
            .where('email', isLessThan: '${lowercaseQuery}z')
            .limit(10)
            .get();

        for (final doc in emailQuery.docs) {
          final user = UserModel.fromJson(doc.data());
          if (!results.any((u) => u.id == user.id)) {
            results.add(user);
          }
        }
      } catch (e) {
        // Ignore email search errors
      }

      return results.take(10).toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  // Kiểm tra unique identifier có tồn tại không
  Future<bool> isUniqueIdentifierExists(String identifier) async {
    try {
      final query = await _firestore
          .collection(_usersCollection)
          .where('unique_identifier', isEqualTo: identifier)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check identifier: $e');
    }
  }

  // Lấy danh sách users theo IDs (cho community members)
  Future<List<User>> getUsersByIds(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return [];

      final List<User> users = [];

      // Firestore chỉ cho phép tối đa 10 items trong whereIn
      for (int i = 0; i < userIds.length; i += 10) {
        final batch = userIds.skip(i).take(10).toList();

        final query = await _firestore
            .collection(_usersCollection)
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in query.docs) {
          final user = UserModel.fromJson(doc.data());
          users.add(user);
        }
      }

      return users;
    } catch (e) {
      throw Exception('Failed to get users by IDs: $e');
    }
  }
}
