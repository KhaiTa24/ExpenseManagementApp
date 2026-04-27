import '../../entities/transaction.dart';
import '../../repositories/transaction_repository.dart';

class IncomeReport {
  final double totalIncome;
  final List<Transaction> transactions;
  final Map<String, double> categoryBreakdown;
  final DateTime startDate;
  final DateTime endDate;

  IncomeReport({
    required this.totalIncome,
    required this.transactions,
    required this.categoryBreakdown,
    required this.startDate,
    required this.endDate,
  });
}

class GetIncomeReport {
  final TransactionRepository repository;

  GetIncomeReport(this.repository);

  Future<IncomeReport> call({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final transactions = await repository.getTransactions(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      type: 'income',
    );

    double totalIncome = 0;
    Map<String, double> categoryBreakdown = {};

    for (var transaction in transactions) {
      totalIncome += transaction.amount;
      
      categoryBreakdown[transaction.categoryId] = 
          (categoryBreakdown[transaction.categoryId] ?? 0) + transaction.amount;
    }

    return IncomeReport(
      totalIncome: totalIncome,
      transactions: transactions,
      categoryBreakdown: categoryBreakdown,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
