import '../../entities/budget.dart';
import '../../repositories/budget_repository.dart';

class GetBudgets {
  final BudgetRepository repository;

  GetBudgets(this.repository);

  Future<List<Budget>> call({
    String? userId,
    String? categoryId,
    int? month,
    int? year,
  }) async {
    return await repository.getBudgets(
      userId: userId,
      categoryId: categoryId,
      month: month,
      year: year,
    );
  }
}
