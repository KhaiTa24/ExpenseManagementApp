import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../datasources/local/transaction_local_datasource.dart';
import '../models/transaction_model.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionLocalDataSource localDataSource;

  TransactionRepositoryImpl(this.localDataSource);

  @override
  Future<List<Transaction>> getTransactions({
    String? userId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    int? limit,
    int? offset,
  }) async {
    return await localDataSource.getTransactions(
      userId: userId,
      categoryId: categoryId,
      startDate: startDate,
      endDate: endDate,
      type: type,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<Transaction?> getTransactionById(String id) async {
    return await localDataSource.getTransactionById(id);
  }

  @override
  Future<String> addTransaction(Transaction transaction) async {
    final model = TransactionModel.fromEntity(transaction);
    return await localDataSource.insertTransaction(model);
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    final model = TransactionModel.fromEntity(transaction);
    await localDataSource.updateTransaction(model);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await localDataSource.deleteTransaction(id);
  }

  @override
  Future<double> getTotalIncome({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await localDataSource.getTotalAmount(
      userId: userId,
      type: 'income',
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<double> getTotalExpense({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await localDataSource.getTotalAmount(
      userId: userId,
      type: 'expense',
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<double> getBalance({String? userId}) async {
    final income = await getTotalIncome(userId: userId);
    final expense = await getTotalExpense(userId: userId);
    return income - expense;
  }

  @override
  Future<List<Transaction>> searchTransactions(String query, {String? userId}) async {
    return await localDataSource.searchTransactions(query, userId: userId);
  }
}
