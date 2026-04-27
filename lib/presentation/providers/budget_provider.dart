import 'package:flutter/foundation.dart';
import '../../domain/entities/budget.dart';
import '../../domain/usecases/budget/create_budget.dart';
import '../../domain/usecases/budget/update_budget.dart';
import '../../domain/usecases/budget/delete_budget.dart';
import '../../domain/usecases/budget/get_budgets.dart';
import '../../domain/usecases/budget/check_budget_status.dart';
import '../../domain/usecases/validation/validate_budget.dart';

enum BudgetLoadingState { initial, loading, loaded, error }

class BudgetProvider extends ChangeNotifier {
  final CreateBudget createBudget;
  final UpdateBudget updateBudget;
  final DeleteBudget deleteBudget;
  final GetBudgets getBudgets;
  final CheckBudgetStatus checkBudgetStatus;
  final ValidateBudget validateBudget;

  BudgetProvider({
    required this.createBudget,
    required this.updateBudget,
    required this.deleteBudget,
    required this.getBudgets,
    required this.checkBudgetStatus,
    required this.validateBudget,
  });

  BudgetLoadingState _state = BudgetLoadingState.initial;
  List<Budget> _budgets = [];
  List<BudgetStatus> _budgetStatuses = [];
  String? _errorMessage;

  BudgetLoadingState get state => _state;
  List<Budget> get budgets => _budgets;
  List<BudgetStatus> get budgetStatuses => _budgetStatuses;
  String? get errorMessage => _errorMessage;

  List<BudgetStatus> get alertBudgets =>
      _budgetStatuses.where((s) => s.needsAlert).toList();

  void _setState(BudgetLoadingState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _setState(BudgetLoadingState.error);
  }

  Future<void> loadBudgets({String? userId}) async {
    try {
      _setState(BudgetLoadingState.loading);
      _errorMessage = null;

      _budgets = await getBudgets(userId: userId);
      
      // Check status for all budgets
      _budgetStatuses = await checkBudgetStatus.checkAllBudgets(_budgets);
      
      _setState(BudgetLoadingState.loaded);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<bool> addNewBudget(Budget budget) async {
    try {
      _errorMessage = null;

      await validateBudget(
        amount: budget.amount,
        categoryId: budget.categoryId,
        period: budget.period,
        month: budget.month,
        year: budget.year,
        userId: budget.userId,
      );

      await createBudget(budget);
      await loadBudgets(userId: budget.userId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> editBudget(Budget budget) async {
    try {
      _errorMessage = null;

      await validateBudget(
        amount: budget.amount,
        categoryId: budget.categoryId,
        period: budget.period,
        month: budget.month,
        year: budget.year,
        userId: budget.userId,
        budgetId: budget.id,
      );

      await updateBudget(budget);
      await loadBudgets(userId: budget.userId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> removeBudget(String id, String userId) async {
    try {
      _errorMessage = null;
      await deleteBudget(id);
      await loadBudgets(userId: userId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  BudgetStatus? getBudgetStatus(String budgetId) {
    try {
      return _budgetStatuses.firstWhere((s) => s.budget.id == budgetId);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
