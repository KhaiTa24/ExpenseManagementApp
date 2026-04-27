import '../../entities/budget.dart';
import '../../repositories/budget_repository.dart';

class CreateBudget {
  final BudgetRepository repository;

  CreateBudget(this.repository);

  Future<String> call(Budget budget) async {
    // Check if budget already exists for this category and period
    final existing = await repository.getBudgetForCategory(
      categoryId: budget.categoryId,
      month: budget.month,
      year: budget.year,
    );
    
    if (existing != null) {
      throw Exception('Ngân sách cho danh mục này đã tồn tại');
    }
    
    return await repository.createBudget(budget);
  }
}
