import '../../../core/errors/exceptions.dart';
import '../../repositories/budget_repository.dart';

class ValidateBudget {
  final BudgetRepository repository;

  static const double minBudget = 10000;
  static const double maxBudget = 999999999;

  ValidateBudget(this.repository);

  Future<void> call({
    required double amount,
    required String categoryId,
    required String period,
    required int month,
    required int year,
    required String userId,
    String? budgetId,
  }) async {
    // Validate amount
    if (amount < minBudget) {
      throw ValidationException('Ngân sách tối thiểu là 10,000 VND');
    }

    if (amount > maxBudget) {
      throw ValidationException('Ngân sách vượt quá giới hạn');
    }

    // Validate period
    if (period != 'monthly' && period != 'yearly') {
      throw ValidationException('Chu kỳ ngân sách không hợp lệ');
    }

    // Validate month and year
    if (month < 1 || month > 12) {
      throw ValidationException('Tháng không hợp lệ');
    }

    if (year < 2000 || year > 2100) {
      throw ValidationException('Năm không hợp lệ');
    }

    // Check for existing budget in same period
    final budgets = await repository.getBudgets(userId: userId);
    final existingBudget = budgets.where(
      (b) => b.categoryId == categoryId &&
             b.period == period &&
             b.month == month &&
             b.year == year &&
             b.id != budgetId,
    );

    if (existingBudget.isNotEmpty) {
      throw ValidationException('Ngân sách cho danh mục này đã tồn tại');
    }
  }
}
