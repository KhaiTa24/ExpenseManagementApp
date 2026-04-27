import '../entities/transaction.dart';

abstract class TransactionRepository {
  Future<List<Transaction>> getTransactions({
    String? userId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    int? limit,
    int? offset,
  });
  
  Future<Transaction?> getTransactionById(String id);
  
  Future<String> addTransaction(Transaction transaction);
  
  Future<void> updateTransaction(Transaction transaction);
  
  Future<void> deleteTransaction(String id);
  
  Future<double> getTotalIncome({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  Future<double> getTotalExpense({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  });
  
  Future<double> getBalance({String? userId});
  
  Future<List<Transaction>> searchTransactions(String query, {String? userId});
}
