import 'package:flutter/foundation.dart';
import '../../data/services/backup_service.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/category.dart' as app_category;
import '../../domain/entities/budget.dart';

class BackupProvider extends ChangeNotifier {
  bool _isBackingUp = false;
  bool _isRestoring = false;
  bool _isSyncing = false;
  String? _errorMessage;
  Map<String, dynamic>? _backupInfo;

  // Getters
  bool get isBackingUp => _isBackingUp;
  bool get isRestoring => _isRestoring;
  bool get isSyncing => _isSyncing;
  bool get isLoading => _isBackingUp || _isRestoring || _isSyncing;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get backupInfo => _backupInfo;

  /// Backup data
  Future<bool> backupData({
    required String userId,
    required List<Transaction> transactions,
    required List<app_category.Category> categories,
    required List<Budget> budgets,
  }) async {
    try {
      _isBackingUp = true;
      _errorMessage = null;
      notifyListeners();

      final success = await BackupService.backupAllData(
        userId: userId,
        transactions: transactions,
        categories: categories,
        budgets: budgets,
      );

      if (success) {
        await loadBackupInfo(userId: userId);
      } else {
        _errorMessage = 'Backup failed. Please try again.';
      }

      return success;
    } catch (e) {
      _errorMessage = 'Backup error: ${e.toString()}';
      return false;
    } finally {
      _isBackingUp = false;
      notifyListeners();
    }
  }

  /// Restore data
  Future<Map<String, dynamic>?> restoreData({
    required String userId,
  }) async {
    try {
      _isRestoring = true;
      _errorMessage = null;
      notifyListeners();

      final data = await BackupService.restoreAllData(userId: userId);

      if (data == null) {
        _errorMessage = 'No backup data found.';
      }

      return data;
    } catch (e) {
      _errorMessage = 'Restore error: ${e.toString()}';
      return null;
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  /// Sync data
  Future<bool> syncData({
    required String userId,
    required List<Transaction> transactions,
    required List<app_category.Category> categories,
    required List<Budget> budgets,
  }) async {
    try {
      _isSyncing = true;
      _errorMessage = null;
      notifyListeners();

      final success = await BackupService.syncData(
        userId: userId,
        localTransactions: transactions,
        localCategories: categories,
        localBudgets: budgets,
      );

      if (success) {
        await loadBackupInfo(userId: userId);
      } else {
        _errorMessage = 'Sync failed. Please try again.';
      }

      return success;
    } catch (e) {
      _errorMessage = 'Sync error: ${e.toString()}';
      return false;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Load backup info
  Future<void> loadBackupInfo({required String userId}) async {
    try {
      _backupInfo = await BackupService.getBackupInfo(userId: userId);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading backup info: $e');
      }
    }
  }

  /// Check if backup exists
  Future<bool> hasBackup({required String userId}) async {
    try {
      return await BackupService.hasBackup(userId: userId);
    } catch (e) {
      return false;
    }
  }

  /// Delete backup
  Future<bool> deleteBackup({required String userId}) async {
    try {
      final success = await BackupService.deleteBackup(userId: userId);
      if (success) {
        _backupInfo = null;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Delete backup error: ${e.toString()}';
      return false;
    }
  }

  /// Test Firestore connection
  Future<bool> testConnection({required String userId}) async {
    try {
      return await BackupService.testFirestoreConnection(userId: userId);
    } catch (e) {
      _errorMessage = 'Connection test error: ${e.toString()}';
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
