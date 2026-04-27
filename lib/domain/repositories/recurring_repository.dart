import '../entities/recurring_transaction.dart';

abstract class RecurringRepository {
  Future<List<RecurringTransaction>> getRecurringTransactions({
    String? userId,
    bool? isActive,
  });
  
  Future<RecurringTransaction?> getRecurringById(String id);
  
  Future<String> createRecurring(RecurringTransaction recurring);
  
  Future<void> updateRecurring(RecurringTransaction recurring);
  
  Future<void> deleteRecurring(String id);
  
  Future<List<RecurringTransaction>> getDueRecurringTransactions();
  
  Future<void> updateLastProcessedDate(String id, DateTime date);
}
