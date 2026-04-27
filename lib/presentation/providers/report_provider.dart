import 'package:flutter/foundation.dart';
import '../../domain/usecases/report/get_expense_report.dart';
import '../../domain/usecases/report/get_income_report.dart';
import '../../domain/usecases/report/get_category_analysis.dart';
import '../../domain/usecases/report/calculate_balance.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/community_transaction.dart';
import 'category_provider.dart';

enum ReportLoadingState { initial, loading, loaded, error }

class ReportProvider extends ChangeNotifier {
  final GetExpenseReport getExpenseReport;
  final GetIncomeReport getIncomeReport;
  final GetCategoryAnalysis getCategoryAnalysis;
  final CalculateBalance calculateBalance;

  ReportProvider({
    required this.getExpenseReport,
    required this.getIncomeReport,
    required this.getCategoryAnalysis,
    required this.calculateBalance,
  });

  ReportLoadingState _state = ReportLoadingState.initial;
  ExpenseReport? _expenseReport;
  IncomeReport? _incomeReport;
  List<CategoryAnalysis>? _categoryAnalysis;
  BalanceInfo? _balanceInfo;
  String? _errorMessage;

  ReportLoadingState get state => _state;
  ExpenseReport? get expenseReport => _expenseReport;
  IncomeReport? get incomeReport => _incomeReport;
  List<CategoryAnalysis>? get categoryAnalysis => _categoryAnalysis;
  BalanceInfo? get balanceInfo => _balanceInfo;
  String? get errorMessage => _errorMessage;

  void _setState(ReportLoadingState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _setState(ReportLoadingState.error);
  }

  Future<void> loadExpenseReport({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      _setState(ReportLoadingState.loading);
      _errorMessage = null;

      _expenseReport = await getExpenseReport(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      _setState(ReportLoadingState.loaded);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> loadIncomeReport({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      _setState(ReportLoadingState.loading);
      _errorMessage = null;

      _incomeReport = await getIncomeReport(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      _setState(ReportLoadingState.loaded);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> loadCategoryAnalysis({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    String? type,
  }) async {
    try {
      _setState(ReportLoadingState.loading);
      _errorMessage = null;

      _categoryAnalysis = await getCategoryAnalysis(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
        type: type,
      );

      _setState(ReportLoadingState.loaded);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> loadBalance({
    required String userId,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    try {
      _setState(ReportLoadingState.loading);
      _errorMessage = null;

      _balanceInfo = await calculateBalance(
        userId: userId,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );

      _setState(ReportLoadingState.loaded);
    } catch (e) {
      _setError(e.toString());
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Method to calculate combined reports from personal and community transactions
  Future<void> loadCombinedBalance({
    required String userId,
    required List<Transaction> personalTransactions,
    required List<CommunityTransaction> communityTransactions,
    DateTime? periodStart,
    DateTime? periodEnd,
  }) async {
    try {
      _setState(ReportLoadingState.loading);
      _errorMessage = null;

      // Filter transactions by date range
      final filteredPersonal = personalTransactions.where((t) {
        if (periodStart != null && t.date.isBefore(periodStart)) return false;
        if (periodEnd != null && t.date.isAfter(periodEnd)) return false;
        return true;
      }).toList();

      final filteredCommunity = communityTransactions.where((t) {
        if (periodStart != null && t.date.isBefore(periodStart)) return false;
        if (periodEnd != null && t.date.isAfter(periodEnd)) return false;
        return true;
      }).toList();

      // Calculate totals
      double totalIncome = 0;
      double totalExpense = 0;
      double periodIncome = 0;
      double periodExpense = 0;

      // Personal transactions (all time)
      for (final transaction in personalTransactions) {
        if (transaction.isIncome) {
          totalIncome += transaction.amount;
        } else {
          totalExpense += transaction.amount;
        }
      }

      // Community transactions (all time) - ALL transactions
      for (final transaction in communityTransactions) {
        if (transaction.isIncome) {
          totalIncome += transaction.amount;
        } else {
          totalExpense += transaction.amount;
        }
      }

      // Period transactions (filtered)
      for (final transaction in filteredPersonal) {
        if (transaction.isIncome) {
          periodIncome += transaction.amount;
        } else {
          periodExpense += transaction.amount;
        }
      }

      for (final transaction in filteredCommunity) {
        if (transaction.isIncome) {
          periodIncome += transaction.amount;
        } else {
          periodExpense += transaction.amount;
        }
      }

      _balanceInfo = BalanceInfo(
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        currentBalance: totalIncome - totalExpense,
        periodIncome: periodIncome,
        periodExpense: periodExpense,
        periodBalance: periodIncome - periodExpense,
      );

      _setState(ReportLoadingState.loaded);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> loadCombinedCategoryAnalysis({
    required String userId,
    required List<Transaction> personalTransactions,
    required List<CommunityTransaction> communityTransactions,
    required DateTime startDate,
    required DateTime endDate,
    String? type,
    CategoryProvider? categoryProvider,
  }) async {
    try {
      _setState(ReportLoadingState.loading);
      _errorMessage = null;

      // Filter transactions by date range and type
      final filteredPersonal = personalTransactions.where((t) {
        if (t.date.isBefore(startDate) || t.date.isAfter(endDate)) return false;
        if (type == 'income' && !t.isIncome) return false;
        if (type == 'expense' && t.isIncome) return false;
        return true;
      }).toList();

      final filteredCommunity = communityTransactions.where((t) {
        if (t.date.isBefore(startDate) || t.date.isAfter(endDate)) return false;
        if (type == 'income' && !t.isIncome) return false;
        if (type == 'expense' && t.isIncome) return false;
        return true;
      }).toList();

      // Group by category
      final categoryTotals = <String, CategoryAnalysisData>{};

      // Process personal transactions (use categoryId as key)
      for (final transaction in filteredPersonal) {
        final key = transaction.categoryId;
        if (!categoryTotals.containsKey(key)) {
          // Get category info from provider
          final category = categoryProvider?.getCategoryById(transaction.categoryId);
          categoryTotals[key] = CategoryAnalysisData(
            categoryId: transaction.categoryId,
            categoryName: category?.name ?? 'Unknown Category',
            categoryIcon: category?.icon ?? '📌',
            totalAmount: 0,
            transactionCount: 0,
          );
        }
        categoryTotals[key]!.totalAmount += transaction.amount;
        categoryTotals[key]!.transactionCount++;
      }

      // Process community transactions
      for (final transaction in filteredCommunity) {
        final key = 'community_${transaction.categoryName}';
        if (!categoryTotals.containsKey(key)) {
          categoryTotals[key] = CategoryAnalysisData(
            categoryId: 'community',
            categoryName: transaction.categoryName,
            categoryIcon: transaction.categoryIcon,
            totalAmount: 0,
            transactionCount: 0,
          );
        }
        categoryTotals[key]!.totalAmount += transaction.amount;
        categoryTotals[key]!.transactionCount++;
      }

      // Calculate percentages and create analysis list
      final totalAmount = categoryTotals.values.fold<double>(0, (sum, data) => sum + data.totalAmount);
      
      _categoryAnalysis = categoryTotals.values.map((data) {
        return CategoryAnalysis(
          categoryId: data.categoryId,
          categoryName: data.categoryName,
          totalAmount: data.totalAmount,
          transactionCount: data.transactionCount,
          percentage: totalAmount > 0 ? (data.totalAmount / totalAmount) * 100 : 0,
          transactions: [], // Empty for now, can be populated if needed
        );
      }).toList();

      // Sort by total amount descending
      _categoryAnalysis!.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

      _setState(ReportLoadingState.loaded);
    } catch (e) {
      _setError(e.toString());
    }
  }
}

class CategoryAnalysisData {
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  double totalAmount;
  int transactionCount;

  CategoryAnalysisData({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.totalAmount,
    required this.transactionCount,
  });
}
