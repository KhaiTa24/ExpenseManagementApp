import '../entities/budget.dart';

abstract class BudgetRepository {
  Future<List<Budget>> getBudgets({
    String? userId,
    String? categoryId,
    int? month,
    int? year,
  });
  
  Future<Budget?> getBudgetById(String id);
  
  Future<String> createBudget(Budget budget);
  
  Future<void> updateBudget(Budget budget);
  
  Future<void> deleteBudget(String id);
  
  Future<Budget?> getBudgetForCategory({
    required String categoryId,
    required int month,
    required int year,
  });
  
  Future<double> getSpentAmount({
    required String categoryId,
    required DateTime startDate,
    required DateTime endDate,
  });
}
