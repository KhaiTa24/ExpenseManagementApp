import 'package:flutter/foundation.dart';
import '../../data/services/ai_service.dart';
import '../providers/transaction_provider.dart';
import '../providers/community_transaction_provider.dart';
import '../providers/firestore_community_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/category_provider.dart';
import '../providers/ai_settings_provider.dart';

class AIProvider extends ChangeNotifier {
  final TransactionProvider _transactionProvider;
  final CommunityTransactionProvider _communityTransactionProvider;
  final FirestoreCommunityProvider _communityProvider;
  final AuthProvider _authProvider;
  final CategoryProvider _categoryProvider;
  final AISettingsProvider _aiSettingsProvider;

  AIProvider({
    required TransactionProvider transactionProvider,
    required CommunityTransactionProvider communityTransactionProvider,
    required FirestoreCommunityProvider communityProvider,
    required AuthProvider authProvider,
    required CategoryProvider categoryProvider,
    required AISettingsProvider aiSettingsProvider,
  })  : _transactionProvider = transactionProvider,
        _communityTransactionProvider = communityTransactionProvider,
        _communityProvider = communityProvider,
        _authProvider = authProvider,
        _categoryProvider = categoryProvider,
        _aiSettingsProvider = aiSettingsProvider;

  // Loading states
  bool _isLoadingPrediction = false;
  bool _isLoadingBudget = false;
  bool _isLoadingAnomalies = false;
  bool _isLoadingSavings = false;
  bool _isLoadingComprehensive = false;

  // Data
  Map<String, dynamic>? _monthlyPrediction;
  Map<String, dynamic>? _budgetRecommendations;
  Map<String, dynamic>? _anomalies;
  List<dynamic>? _savingOpportunities;
  Map<String, dynamic>? _comprehensiveInsights;

  // Errors
  String? _errorMessage;

  // Getters
  bool get isLoadingPrediction => _isLoadingPrediction;
  bool get isLoadingBudget => _isLoadingBudget;
  bool get isLoadingAnomalies => _isLoadingAnomalies;
  bool get isLoadingSavings => _isLoadingSavings;
  bool get isLoadingComprehensive => _isLoadingComprehensive;

  bool get isLoading =>
      _isLoadingPrediction ||
      _isLoadingBudget ||
      _isLoadingAnomalies ||
      _isLoadingSavings ||
      _isLoadingComprehensive;

  Map<String, dynamic>? get monthlyPrediction => _monthlyPrediction;
  Map<String, dynamic>? get budgetRecommendations => _budgetRecommendations;
  Map<String, dynamic>? get anomalies => _anomalies;
  List<dynamic>? get savingOpportunities => _savingOpportunities;
  Map<String, dynamic>? get comprehensiveInsights => _comprehensiveInsights;
  String? get errorMessage => _errorMessage;

  /// Convert transactions to format for AI API (includes both personal and community)
  List<Map<String, dynamic>> _convertTransactions() {
    final userId = _authProvider.currentUser?.id;
    if (userId == null) return [];

    final allTransactions = <Map<String, dynamic>>[];

    // Add personal transactions
    for (final t in _transactionProvider.transactions) {
      final category = _categoryProvider.categories
          .where((c) => c.id == t.categoryId)
          .firstOrNull;

      allTransactions.add({
        'date': t.date.toIso8601String(),
        'amount': t.amount,
        'category': category?.name ?? 'Unknown',
        'description': t.description ?? '',
        'type': t.type, // 'income' or 'expense'
        'source': 'personal',
        'category_type':
            category?.type ?? t.type, // Ensure category type is included
      });
    }

    // Add community transactions (only user's own transactions)
    for (final wallet in _communityProvider.userWallets) {
      final walletTransactions =
          _communityTransactionProvider.getTransactionsForWallet(wallet.id);
      for (final t in walletTransactions.where((tx) => tx.userId == userId)) {
        allTransactions.add({
          'date': t.date.toIso8601String(),
          'amount': t.amount,
          'category': t.categoryName,
          'description': t.description,
          'type': t.isIncome ? 'income' : 'expense',
          'source': 'community',
          'wallet_name': wallet.name,
          'category_type': t.isIncome ? 'income' : 'expense',
        });
      }
    }

    // Sort by date (newest first)
    allTransactions.sort((a, b) =>
        DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));

    return allTransactions;
  }

  /// Get total monthly income for budget recommendations
  double _calculateMonthlyIncome() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    double totalIncome = 0;

    // Personal income
    for (final t in _transactionProvider.transactions) {
      if (t.type == 'income' &&
          t.date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
          t.date.isBefore(endOfMonth.add(const Duration(days: 1)))) {
        totalIncome += t.amount;
      }
    }

    // Community income (user's own)
    final userId = _authProvider.currentUser?.id;
    if (userId != null) {
      for (final wallet in _communityProvider.userWallets) {
        final walletTransactions =
            _communityTransactionProvider.getTransactionsForWallet(wallet.id);
        for (final t in walletTransactions.where((tx) => tx.userId == userId)) {
          if (t.isIncome &&
              t.date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
              t.date.isBefore(endOfMonth.add(const Duration(days: 1)))) {
            totalIncome += t.amount;
          }
        }
      }
    }

    return totalIncome;
  }

  /// Lấy dự đoán chi tiêu tháng tới
  Future<void> loadMonthlyPrediction() async {
    // Check if predictions are enabled
    if (!_aiSettingsProvider.enablePredictions) {
      _monthlyPrediction = null;
      return;
    }

    try {
      _isLoadingPrediction = true;
      _errorMessage = null;
      notifyListeners();

      final userId = _authProvider.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final transactions = _convertTransactions();

      if (transactions.isEmpty) {
        _monthlyPrediction = null;
        _errorMessage = 'Không có dữ liệu giao dịch để dự đoán';
        return;
      }

      _monthlyPrediction = await AIService.predictMonthlySpending(
        userId: userId,
        transactions: transactions,
      );

      if (_monthlyPrediction == null) {
        _errorMessage = 'Không thể lấy dự đoán từ AI server';
      } else {
        // Clear error if successful
        _errorMessage = null;
      }
    } catch (e) {
      _errorMessage = 'Lỗi dự đoán: ${e.toString()}';
      _monthlyPrediction = null;
    } finally {
      _isLoadingPrediction = false;
      notifyListeners();
    }
  }

  /// Lấy gợi ý ngân sách
  Future<void> loadBudgetRecommendations({double? monthlyIncome}) async {
    // Check if budget recommendations are enabled
    if (!_aiSettingsProvider.enableBudgetRecommendations) {
      _budgetRecommendations = null;
      return;
    }

    try {
      _isLoadingBudget = true;
      _errorMessage = null;
      notifyListeners();

      final userId = _authProvider.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final transactions = _convertTransactions();
      if (transactions.isEmpty) {
        _budgetRecommendations = null;
        _errorMessage = 'Không có dữ liệu giao dịch để gợi ý ngân sách';
        return;
      }

      // Calculate monthly income if not provided
      final calculatedIncome = monthlyIncome ?? _calculateMonthlyIncome();

      _budgetRecommendations = await AIService.getBudgetRecommendations(
        userId: userId,
        transactions: transactions,
        monthlyIncome: calculatedIncome,
      );

      if (_budgetRecommendations == null) {
        _errorMessage = 'Không thể lấy gợi ý ngân sách từ AI server';
      }
    } catch (e) {
      _errorMessage = 'Lỗi gợi ý ngân sách: ${e.toString()}';
      _budgetRecommendations = null;
    } finally {
      _isLoadingBudget = false;
      notifyListeners();
    }
  }

  /// Phát hiện chi tiêu bất thường
  Future<void> loadAnomalies() async {
    // Check if anomaly detection is enabled
    if (!_aiSettingsProvider.enableAnomalyDetection) {
      _anomalies = null;
      return;
    }

    try {
      _isLoadingAnomalies = true;
      _errorMessage = null;
      notifyListeners();

      final userId = _authProvider.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final transactions = _convertTransactions();
      if (transactions.length < 3) {
        _anomalies = null;
        _errorMessage = 'Cần ít nhất 3 giao dịch để phát hiện bất thường';
        return;
      }

      _anomalies = await AIService.detectAnomalies(
        userId: userId,
        transactions: transactions,
      );

      if (_anomalies == null) {
        _errorMessage = 'Không thể phân tích bất thường từ AI server';
      }
    } catch (e) {
      _errorMessage = 'Lỗi phát hiện bất thường: ${e.toString()}';
      _anomalies = null;
    } finally {
      _isLoadingAnomalies = false;
      notifyListeners();
    }
  }

  /// Tìm cơ hội tiết kiệm
  Future<void> loadSavingOpportunities() async {
    // Check if saving tips are enabled
    if (!_aiSettingsProvider.enableSavingTips) {
      _savingOpportunities = null;
      return;
    }

    try {
      _isLoadingSavings = true;
      _errorMessage = null;
      notifyListeners();

      final userId = _authProvider.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final transactions = _convertTransactions();
      if (transactions.isEmpty) {
        _savingOpportunities = null;
        _errorMessage = 'Không có dữ liệu giao dịch để tìm cơ hội tiết kiệm';
        return;
      }

      _savingOpportunities = await AIService.getSavingOpportunities(
        userId: userId,
        transactions: transactions,
      );

      if (_savingOpportunities == null) {
        _errorMessage = 'Không thể tìm cơ hội tiết kiệm từ AI server';
      }
    } catch (e) {
      _errorMessage = 'Lỗi tìm cơ hội tiết kiệm: ${e.toString()}';
      _savingOpportunities = null;
    } finally {
      _isLoadingSavings = false;
      notifyListeners();
    }
  }

  /// Lấy tất cả insights cùng lúc
  Future<void> loadComprehensiveInsights() async {
    try {
      _isLoadingComprehensive = true;
      _errorMessage = null;
      notifyListeners();

      final userId = _authProvider.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final transactions = _convertTransactions();
      if (transactions.isEmpty) {
        _comprehensiveInsights = null;
        _errorMessage = 'Không có dữ liệu giao dịch để phân tích';
        return;
      }

      _comprehensiveInsights = await AIService.getComprehensiveInsights(
        userId: userId,
        transactions: transactions,
      );

      if (_comprehensiveInsights == null) {
        _errorMessage = 'Không thể lấy insights từ AI server';
      } else {
        // Update individual data from comprehensive insights based on settings
        if (_aiSettingsProvider.enablePredictions) {
          _monthlyPrediction = _comprehensiveInsights!['monthly_prediction'];
        } else {
          _monthlyPrediction = null;
        }

        if (_aiSettingsProvider.enableBudgetRecommendations) {
          _budgetRecommendations = _comprehensiveInsights!['budget_recommendations'];
        } else {
          _budgetRecommendations = null;
        }

        if (_aiSettingsProvider.enableAnomalyDetection) {
          _anomalies = _comprehensiveInsights!['anomaly_analysis'];
        } else {
          _anomalies = null;
        }

        if (_aiSettingsProvider.enableSavingTips) {
          _savingOpportunities = _comprehensiveInsights!['saving_opportunities'];
        } else {
          _savingOpportunities = null;
        }
      }
    } catch (e) {
      _errorMessage = 'Lỗi phân tích tổng hợp: ${e.toString()}';
      _comprehensiveInsights = null;
    } finally {
      _isLoadingComprehensive = false;
      notifyListeners();
    }
  }

  /// Kiểm tra server có hoạt động không
  Future<bool> checkServerHealth() async {
    return await AIService.checkServerHealth();
  }

  /// Clear tất cả dữ liệu
  void clearAllData() {
    _monthlyPrediction = null;
    _budgetRecommendations = null;
    _anomalies = null;
    _savingOpportunities = null;
    _comprehensiveInsights = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Force refresh prediction (clear cache and reload)
  Future<void> forceRefreshPrediction() async {
    _monthlyPrediction = null;
    _errorMessage = null;
    await loadMonthlyPrediction();
  }

  /// Reset all loading states (emergency reset)
  void resetLoadingStates() {
    _isLoadingPrediction = false;
    _isLoadingBudget = false;
    _isLoadingAnomalies = false;
    _isLoadingSavings = false;
    _isLoadingComprehensive = false;
    notifyListeners();
  }
}
