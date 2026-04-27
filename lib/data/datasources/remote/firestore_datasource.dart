import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firebase_constants.dart';
import '../../../core/errors/exceptions.dart';

abstract class FirestoreDataSource {
  // User operations
  Future<void> createUser(Map<String, dynamic> userData);
  Future<Map<String, dynamic>?> getUser(String userId);
  Future<void> updateUser(String userId, Map<String, dynamic> data);
  
  // Sync operations
  Future<void> syncTransactions(String userId, List<Map<String, dynamic>> transactions);
  Future<void> syncCategories(String userId, List<Map<String, dynamic>> categories);
  Future<void> syncBudgets(String userId, List<Map<String, dynamic>> budgets);
  
  Future<List<Map<String, dynamic>>> getTransactions(String userId, DateTime? lastSyncTime);
  Future<List<Map<String, dynamic>>> getCategories(String userId, DateTime? lastSyncTime);
  Future<List<Map<String, dynamic>>> getBudgets(String userId, DateTime? lastSyncTime);
  
  // Delete operations
  Future<void> deleteTransaction(String userId, String transactionId);
  Future<void> deleteCategory(String userId, String categoryId);
  Future<void> deleteBudget(String userId, String budgetId);
}

class FirestoreDataSourceImpl implements FirestoreDataSource {
  final FirebaseFirestore _firestore;

  FirestoreDataSourceImpl({required FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Future<void> createUser(Map<String, dynamic> userData) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userData['id'])
          .set(userData);
    } catch (e) {
      throw ServerException('Không thể tạo user trên cloud');
    }
  }

  @override
  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .get();
      return doc.data();
    } catch (e) {
      throw ServerException('Không thể lấy thông tin user');
    }
  }

  @override
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .update(data);
    } catch (e) {
      throw ServerException('Không thể cập nhật user');
    }
  }

  @override
  Future<void> syncTransactions(
    String userId,
    List<Map<String, dynamic>> transactions,
  ) async {
    try {
      final batch = _firestore.batch();
      final collection = _firestore
          .collection(FirebaseConstants.transactionsCollection);

      for (var transaction in transactions) {
        final docRef = collection.doc(transaction['id']);
        batch.set(docRef, transaction, SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      throw ServerException('Không thể đồng bộ transactions');
    }
  }

  @override
  Future<void> syncCategories(
    String userId,
    List<Map<String, dynamic>> categories,
  ) async {
    try {
      final batch = _firestore.batch();
      final collection = _firestore
          .collection(FirebaseConstants.categoriesCollection);

      for (var category in categories) {
        final docRef = collection.doc(category['id']);
        batch.set(docRef, category, SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      throw ServerException('Không thể đồng bộ categories');
    }
  }

  @override
  Future<void> syncBudgets(
    String userId,
    List<Map<String, dynamic>> budgets,
  ) async {
    try {
      final batch = _firestore.batch();
      final collection = _firestore
          .collection(FirebaseConstants.budgetsCollection);

      for (var budget in budgets) {
        final docRef = collection.doc(budget['id']);
        batch.set(docRef, budget, SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      throw ServerException('Không thể đồng bộ budgets');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTransactions(
    String userId,
    DateTime? lastSyncTime,
  ) async {
    try {
      Query query = _firestore
          .collection(FirebaseConstants.transactionsCollection)
          .where('user_id', isEqualTo: userId);

      if (lastSyncTime != null) {
        query = query.where('updated_at',
            isGreaterThan: lastSyncTime.millisecondsSinceEpoch);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
    } catch (e) {
      throw ServerException('Không thể lấy transactions từ cloud');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCategories(
    String userId,
    DateTime? lastSyncTime,
  ) async {
    try {
      Query query = _firestore
          .collection(FirebaseConstants.categoriesCollection)
          .where('user_id', isEqualTo: userId);

      if (lastSyncTime != null) {
        query = query.where('created_at',
            isGreaterThan: lastSyncTime.millisecondsSinceEpoch);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
    } catch (e) {
      throw ServerException('Không thể lấy categories từ cloud');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getBudgets(
    String userId,
    DateTime? lastSyncTime,
  ) async {
    try {
      Query query = _firestore
          .collection(FirebaseConstants.budgetsCollection)
          .where('user_id', isEqualTo: userId);

      if (lastSyncTime != null) {
        query = query.where('created_at',
            isGreaterThan: lastSyncTime.millisecondsSinceEpoch);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
    } catch (e) {
      throw ServerException('Không thể lấy budgets từ cloud');
    }
  }

  @override
  Future<void> deleteTransaction(String userId, String transactionId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.transactionsCollection)
          .doc(transactionId)
          .delete();
    } catch (e) {
      throw ServerException('Không thể xóa transaction trên cloud');
    }
  }

  @override
  Future<void> deleteCategory(String userId, String categoryId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.categoriesCollection)
          .doc(categoryId)
          .delete();
    } catch (e) {
      throw ServerException('Không thể xóa category trên cloud');
    }
  }

  @override
  Future<void> deleteBudget(String userId, String budgetId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.budgetsCollection)
          .doc(budgetId)
          .delete();
    } catch (e) {
      throw ServerException('Không thể xóa budget trên cloud');
    }
  }
}
