import '../../repositories/transaction_repository.dart';

class BalanceInfo {
  final double totalIncome;
  final double totalExpense;
  final double currentBalance;
  final double periodIncome;
  final double periodExpense;
  final double periodBalance;

  BalanceInfo({
    required this.totalIncome,
    required this.totalExpense,
    required this.currentBalance,
    required this.periodIncome,
    required this.periodExpense,
    required this.periodBalance,
  });
}

class CalculateBalance {
  final TransactionRepository repository;

  CalculateBalance(this.repository);

  Future<BalanceInfo> call({
    required String userId,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    // Get all transactions for total balance
    final allTransactions = await repository.getTransactions(userId: userId);

    double totalIncome = 0;
    double totalExpense = 0;

    for (var transaction in allTransactions) {
      if (transaction.isIncome) {
        totalIncome += transaction.amount;
      } else {
        totalExpense += transaction.amount;
      }
    }

    final currentBalance = totalIncome - totalExpense;

    // Calculate period balance if dates provided
    double periodIncome = 0;
    double periodExpense = 0;

    if (periodStart != null && periodEnd != null) {
      final periodTransactions = await repository.getTransactions(
        userId: userId,
        startDate: periodStart,
        endDate: periodEnd,
      );

      for (var transaction in periodTransactions) {
        if (transaction.isIncome) {
          periodIncome += transaction.amount;
        } else {
          periodExpense += transaction.amount;
        }
      }
    }

    final periodBalance = periodIncome - periodExpense;

    return BalanceInfo(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      currentBalance: currentBalance,
      periodIncome: periodIncome,
      periodExpense: periodExpense,
      periodBalance: periodBalance,
    );
  }
}
