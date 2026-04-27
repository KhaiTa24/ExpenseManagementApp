import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/transaction.dart' as app_transaction;
import '../../domain/entities/category.dart' as app_category;
import '../../domain/entities/budget.dart';

class BackupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Backup all data to Firebase
  static Future<bool> backupAllData({
    required String userId,
    required List<app_transaction.Transaction> transactions,
    required List<app_category.Category> categories,
    required List<Budget> budgets,
  }) async {
    try {
      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return false;
      }

      if (user.uid != userId) {
        return false;
      }

      final userBackupRef = _firestore.collection('backups').doc(userId);

      // Prepare backup data
      final backupData = {
        'userId': userId,
        'backupDate': FieldValue.serverTimestamp(),
        'version': '1.0.0',
        'transactions': transactions
            .map((t) => {
                  'id': t.id,
                  'userId': t.userId,
                  'categoryId': t.categoryId,
                  'amount': t.amount,
                  'type': t.type,
                  'description': t.description,
                  'date': t.date.toIso8601String(),
                  'createdAt': t.createdAt.toIso8601String(),
                  'updatedAt': t.updatedAt.toIso8601String(),
                })
            .toList(),
        'categories': categories
            .map((c) => {
                  'id': c.id,
                  'name': c.name,
                  'type': c.type,
                  'icon': c.icon,
                  'color': c.color,
                  'isDefault': c.isDefault,
                  'userId': c.userId,
                  'createdAt': c.createdAt.toIso8601String(),
                })
            .toList(),
        'budgets': budgets
            .map((b) => {
                  'id': b.id,
                  'userId': b.userId,
                  'categoryId': b.categoryId,
                  'amount': b.amount,
                  'period': b.period,
                  'month': b.month,
                  'year': b.year,
                  'createdAt': b.createdAt.toIso8601String(),
                })
            .toList(),
      };

      // Use direct set instead of batch for better error handling
      await userBackupRef.set(backupData);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Restore data from Firebase
  static Future<Map<String, dynamic>?> restoreAllData({
    required String userId,
  }) async {
    try {
      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.uid != userId) {
        return null;
      }

      final userBackupRef = _firestore.collection('backups').doc(userId);
      final doc = await userBackupRef.get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;

      return {
        'transactions': data['transactions'] ?? [],
        'categories': data['categories'] ?? [],
        'budgets': data['budgets'] ?? [],
        'backupDate': data['backupDate'],
        'version': data['version'],
      };
    } catch (e) {
      return null;
    }
  }

  /// Check if backup exists
  static Future<bool> hasBackup({required String userId}) async {
    try {
      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.uid != userId) {
        return false;
      }

      final userBackupRef = _firestore.collection('backups').doc(userId);
      final doc = await userBackupRef.get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get backup information (date, version)
  static Future<Map<String, dynamic>?> getBackupInfo({
    required String userId,
  }) async {
    try {
      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.uid != userId) {
        return null;
      }

      final userBackupRef = _firestore.collection('backups').doc(userId);
      final doc = await userBackupRef.get();

      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      return {
        'backupDate': data['backupDate'],
        'version': data['version'],
        'transactionCount': (data['transactions'] as List?)?.length ?? 0,
        'categoryCount': (data['categories'] as List?)?.length ?? 0,
        'budgetCount': (data['budgets'] as List?)?.length ?? 0,
      };
    } catch (e) {
      return null;
    }
  }

  /// Delete backup
  static Future<bool> deleteBackup({required String userId}) async {
    try {
      // Check if user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.uid != userId) {
        return false;
      }

      final userBackupRef = _firestore.collection('backups').doc(userId);
      await userBackupRef.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Test Firestore connection and permissions
  static Future<bool> testFirestoreConnection({required String userId}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return false;
      }

      // Test write to backups collection
      final testRef = _firestore.collection('backups').doc(userId);
      final testData = {
        'test': true,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': userId,
      };

      await testRef.set(testData);

      // Test read
      final doc = await testRef.get();
      if (doc.exists) {
        // Clean up test document
        await testRef.delete();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Sync data (backup + restore if needed)
  static Future<bool> syncData({
    required String userId,
    required List<app_transaction.Transaction> localTransactions,
    required List<app_category.Category> localCategories,
    required List<Budget> localBudgets,
  }) async {
    try {
      // Backup current data
      final backupSuccess = await backupAllData(
        userId: userId,
        transactions: localTransactions,
        categories: localCategories,
        budgets: localBudgets,
      );

      if (!backupSuccess) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
