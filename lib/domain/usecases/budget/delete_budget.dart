import '../../repositories/budget_repository.dart';

class DeleteBudget {
  final BudgetRepository repository;

  DeleteBudget(this.repository);

  Future<void> call(String id) async {
    return await repository.deleteBudget(id);
  }
}
