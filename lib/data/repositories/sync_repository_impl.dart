import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/sync_repository.dart';
import '../datasources/local/transaction_local_datasource.dart';
import '../datasources/local/category_local_datasource.dart';
import '../datasources/local/budget_local_datasource.dart';
import '../datasources/remote/firestore_datasource.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/budget_model.dart';

class SyncRepositoryImpl implements SyncRepository {
  final FirestoreDataSource firestoreDataSource;
  final TransactionLocalDataSource transactionLocalDataSource;
  final CategoryLocalDataSource categoryLocalDataSource;
  final BudgetLocalDataSource budgetLocalDataSource;
  final SharedPreferences sharedPreferences;

  static const String _lastSyncKey = 'last_sync_time';
  static const String _autoSyncKey = 'auto_sync_enabled';

  SyncRepositoryImpl({
    required this.firestoreDataSource,
    required this.transactionLocalDataSource,
    required this.categoryLocalDataSource,
    required this.budgetLocalDataSource,
    required this.sharedPreferences,
  });

  @override
  Future<void> syncToCloud() async {
    // Get current user ID (should be passed from auth)
    // For now, we'll assume it's available
    final userId = sharedPreferences.getString('current_user_id');
    if (userId == null) {
      throw Exception('User not logged in');
    }

    final lastSyncTime = await getLastSyncTime();

    // Get local data
    final transactions = await transactionLocalDataSource.getTransactions(userId: userId);
    final categories = await categoryLocalDataSource.getCategories(userId: userId);
    final budgets = await budgetLocalDataSource.getBudgets(userId: userId);

    // Filter data modified after last sync
    final transactionsToSync = lastSyncTime != null
        ? transactions.where((t) => t.updatedAt.isAfter(lastSyncTime)).toList()
        : transactions;

    // Sync to Firestore
    if (transactionsToSync.isNotEmpty) {
      await firestoreDataSource.syncTransactions(
        userId,
        transactionsToSync.map((t) => TransactionModel.fromEntity(t).toJson()).toList(),
      );
    }

    if (categories.isNotEmpty) {
      await firestoreDataSource.syncCategories(
        userId,
        categories.map((c) => CategoryModel.fromEntity(c).toJson()).toList(),
      );
    }

    if (budgets.isNotEmpty) {
      await firestoreDataSource.syncBudgets(
        userId,
        budgets.map((b) => BudgetModel.fromEntity(b).toJson()).toList(),
      );
    }

    // Update last sync time
    await sharedPreferences.setInt(
      _lastSyncKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  Future<void> syncFromCloud() async {
    final userId = sharedPreferences.getString('current_user_id');
    if (userId == null) {
      throw Exception('User not logged in');
    }

    final lastSyncTime = await getLastSyncTime();

    // Get data from Firestore
    final transactions = await firestoreDataSource.getTransactions(
      userId,
      lastSyncTime,
    );
    final categories = await firestoreDataSource.getCategories(
      userId,
      lastSyncTime,
    );
    final budgets = await firestoreDataSource.getBudgets(
      userId,
      lastSyncTime,
    );

    // Save to local database
    for (var transaction in transactions) {
      final model = TransactionModel.fromJson(transaction);
      await transactionLocalDataSource.insertTransaction(model);
    }

    for (var category in categories) {
      final model = CategoryModel.fromJson(category);
      await categoryLocalDataSource.insertCategory(model);
    }

    for (var budget in budgets) {
      final model = BudgetModel.fromJson(budget);
      await budgetLocalDataSource.insertBudget(model);
    }

    // Update last sync time
    await sharedPreferences.setInt(
      _lastSyncKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    final timestamp = sharedPreferences.getInt(_lastSyncKey);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  @override
  Future<bool> isOnline() async {
    // This would require connectivity_plus package
    // For now, returning true
    return true;
  }

  @override
  Future<void> enableAutoSync() async {
    await sharedPreferences.setBool(_autoSyncKey, true);
  }

  @override
  Future<void> disableAutoSync() async {
    await sharedPreferences.setBool(_autoSyncKey, false);
  }

  @override
  Future<bool> isAutoSyncEnabled() async {
    return sharedPreferences.getBool(_autoSyncKey) ?? false;
  }
}
