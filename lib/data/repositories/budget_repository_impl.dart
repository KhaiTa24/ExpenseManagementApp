import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../datasources/local/budget_local_datasource.dart';
import '../models/budget_model.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetLocalDataSource localDataSource;

  BudgetRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Budget>> getBudgets({
    String? userId,
    String? categoryId,
    int? month,
    int? year,
  }) async {
    if (userId == null) {
      throw Exception('User ID is required');
    }
    
    final budgets = await localDataSource.getBudgets(userId: userId);
    
    // Filter by additional parameters if provided
    return budgets.where((budget) {
      if (categoryId != null && budget.categoryId != categoryId) return false;
      if (month != null && budget.month != month) return false;
      if (year != null && budget.year != year) return false;
      return true;
    }).toList();
  }

  @override
  Future<Budget?> getBudgetById(String id) async {
    return await localDataSource.getBudgetById(id);
  }

  @override
  Future<String> createBudget(Budget budget) async {
    final model = BudgetModel.fromEntity(budget);
    await localDataSource.insertBudget(model);
    return budget.id;
  }

  @override
  Future<void> updateBudget(Budget budget) async {
    final model = BudgetModel.fromEntity(budget);
    await localDataSource.updateBudget(model);
  }

  @override
  Future<void> deleteBudget(String id) async {
    await localDataSource.deleteBudget(id);
  }

  @override
  Future<Budget?> getBudgetForCategory({
    required String categoryId,
    required int month,
    required int year,
  }) async {
    final budgets = await getBudgets(
      categoryId: categoryId,
      month: month,
      year: year,
    );
    
    return budgets.isNotEmpty ? budgets.first : null;
  }

  @override
  Future<double> getSpentAmount({
    required String categoryId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // This would need transaction repository to calculate
    // For now, returning 0
    // TODO: Inject transaction repository and calculate spent amount
    return 0.0;
  }
}
