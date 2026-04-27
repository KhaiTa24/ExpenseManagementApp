import '../../domain/entities/recurring_transaction.dart';
import '../../domain/repositories/recurring_repository.dart';
import '../datasources/local/recurring_local_datasource.dart';
import '../models/recurring_model.dart';

class RecurringRepositoryImpl implements RecurringRepository {
  final RecurringLocalDataSource localDataSource;

  RecurringRepositoryImpl({required this.localDataSource});

  @override
  Future<List<RecurringTransaction>> getRecurringTransactions({
    String? userId,
    bool? isActive,
  }) async {
    if (userId == null) {
      throw Exception('User ID is required');
    }

    if (isActive == true) {
      return await localDataSource.getActiveRecurringTransactions(userId);
    }

    return await localDataSource.getRecurringTransactions(userId);
  }

  @override
  Future<RecurringTransaction?> getRecurringById(String id) async {
    return await localDataSource.getRecurringById(id);
  }

  @override
  Future<String> createRecurring(RecurringTransaction recurring) async {
    final model = RecurringModel.fromEntity(recurring);
    await localDataSource.insertRecurring(model);
    return recurring.id;
  }

  @override
  Future<void> updateRecurring(RecurringTransaction recurring) async {
    final model = RecurringModel.fromEntity(recurring);
    await localDataSource.updateRecurring(model);
  }

  @override
  Future<void> deleteRecurring(String id) async {
    await localDataSource.deleteRecurring(id);
  }

  @override
  Future<List<RecurringTransaction>> getDueRecurringTransactions() async {
    // This would need userId from current session
    // For now, returning empty list - will be implemented with auth
    return [];
  }

  @override
  Future<void> updateLastProcessedDate(String id, DateTime date) async {
    await localDataSource.updateLastProcessedDate(id, date);
  }
}
