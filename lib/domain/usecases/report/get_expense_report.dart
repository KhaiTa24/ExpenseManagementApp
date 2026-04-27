import '../../entities/transaction.dart';
import '../../repositories/transaction_repository.dart';

class ExpenseReport {
  final double totalExpense;
  final List<Transaction> transactions;
  final Map<String, double> categoryBreakdown;
  final DateTime startDate;
  final DateTime endDate;

  ExpenseReport({
    required this.totalExpense,
    required this.transactions,
    required this.categoryBreakdown,
    required this.startDate,
    required this.endDate,
  });
}

class GetExpenseReport {
  final TransactionRepository repository;

  GetExpenseReport(this.repository);

  Future<ExpenseReport> call({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final transactions = await repository.getTransactions(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      type: 'expense',
    );

    double totalExpense = 0;
    Map<String, double> categoryBreakdown = {};

    for (var transaction in transactions) {
      totalExpense += transaction.amount;
      
      categoryBreakdown[transaction.categoryId] = 
          (categoryBreakdown[transaction.categoryId] ?? 0) + transaction.amount;
    }

    return ExpenseReport(
      totalExpense: totalExpense,
      transactions: transactions,
      categoryBreakdown: categoryBreakdown,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
