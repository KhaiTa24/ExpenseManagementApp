import '../../entities/budget.dart';
import '../../repositories/budget_repository.dart';

class UpdateBudget {
  final BudgetRepository repository;

  UpdateBudget(this.repository);

  Future<void> call(Budget budget) async {
    return await repository.updateBudget(budget);
  }
}
