import '../../entities/budget.dart';
import '../../repositories/transaction_repository.dart';

enum BudgetAlertLevel {
  safe,      // < 80%
  warning,   // 80% - 99%
  danger,    // 100%
  critical,  // > 100%
}

class BudgetStatus {
  final Budget budget;
  final double spentAmount;
  final double remainingAmount;
  final double percentage;
  final BudgetAlertLevel alertLevel;

  BudgetStatus({
    required this.budget,
    required this.spentAmount,
    required this.remainingAmount,
    required this.percentage,
    required this.alertLevel,
  });

  bool get isOverBudget => percentage > 100;
  bool get needsAlert => alertLevel != BudgetAlertLevel.safe;
}

class CheckBudgetStatus {
  final TransactionRepository transactionRepository;

  CheckBudgetStatus(this.transactionRepository);

  Future<BudgetStatus> call(Budget budget) async {
    // Calculate period dates
    final periodStart = DateTime(budget.year, budget.month, 1);
    final periodEnd = DateTime(budget.year, budget.month + 1, 0, 23, 59, 59);

    // Get transactions for this category in the period
    final transactions = await transactionRepository.getTransactions(
      userId: budget.userId,
      categoryId: budget.categoryId,
      startDate: periodStart,
      endDate: periodEnd,
      type: 'expense',
    );

    // Calculate spent amount
    double spentAmount = 0;
    for (var transaction in transactions) {
      spentAmount += transaction.amount;
    }

    // Calculate remaining and percentage
    final remainingAmount = budget.amount - spentAmount;
    final percentage = (spentAmount / budget.amount) * 100;

    // Determine alert level
    BudgetAlertLevel alertLevel;
    if (percentage > 100) {
      alertLevel = BudgetAlertLevel.critical;
    } else if (percentage >= 100) {
      alertLevel = BudgetAlertLevel.danger;
    } else if (percentage >= 80) {
      alertLevel = BudgetAlertLevel.warning;
    } else {
      alertLevel = BudgetAlertLevel.safe;
    }

    return BudgetStatus(
      budget: budget,
      spentAmount: spentAmount,
      remainingAmount: remainingAmount,
      percentage: percentage,
      alertLevel: alertLevel,
    );
  }

  Future<List<BudgetStatus>> checkAllBudgets(List<Budget> budgets) async {
    final statusList = <BudgetStatus>[];
    
    for (var budget in budgets) {
      final status = await call(budget);
      statusList.add(status);
    }

    return statusList;
  }
}
