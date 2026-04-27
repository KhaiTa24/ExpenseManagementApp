import 'package:flutter/foundation.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_filter.dart';
import '../../domain/usecases/transaction/add_transaction.dart';
import '../../domain/usecases/transaction/update_transaction.dart';
import '../../domain/usecases/transaction/delete_transaction.dart';
import '../../domain/usecases/transaction/get_transactions.dart';
import '../../domain/usecases/transaction/get_transaction_by_id.dart';
import '../../domain/usecases/validation/validate_transaction.dart';

enum TransactionLoadingState { initial, loading, loaded, error }

class TransactionProvider extends ChangeNotifier {
  final AddTransaction addTransaction;
  final UpdateTransaction updateTransaction;
  final DeleteTransaction deleteTransaction;
  final GetTransactions getTransactions;
  final GetTransactionById getTransactionById;
  final ValidateTransaction validateTransaction;

  TransactionProvider({
    required this.addTransaction,
    required this.updateTransaction,
    required this.deleteTransaction,
    required this.getTransactions,
    required this.getTransactionById,
    required this.validateTransaction,
  });

  TransactionLoadingState _state = TransactionLoadingState.initial;
  List<Transaction> _transactions = [];
  List<Transaction> _allTransactions = [];
  String? _errorMessage;
  TransactionFilter? _currentFilter;

  TransactionLoadingState get state => _state;
  List<Transaction> get transactions => _currentFilter != null ? filteredTransactions : _transactions;
  String? get errorMessage => _errorMessage;
  TransactionFilter? get currentFilter => _currentFilter;

  List<Transaction> get incomeTransactions =>
      _transactions.where((t) => t.isIncome).toList();

  List<Transaction> get expenseTransactions =>
      _transactions.where((t) => t.isExpense).toList();

  double get totalIncome =>
      incomeTransactions.fold(0, (sum, t) => sum + t.amount);

  double get totalExpense =>
      expenseTransactions.fold(0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;

  void _setState(TransactionLoadingState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _setState(TransactionLoadingState.error);
  }

  Future<void> loadTransactions({
    String? userId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? type,
  }) async {
    try {
      _setState(TransactionLoadingState.loading);
      _errorMessage = null;

      _allTransactions = await getTransactions(
        userId: userId,
        categoryId: categoryId,
        startDate: startDate,
        endDate: endDate,
        type: type,
      );
      
      _transactions = _currentFilter != null ? filteredTransactions : _allTransactions;

      _setState(TransactionLoadingState.loaded);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<bool> addNewTransaction(Transaction transaction) async {
    try {
      _errorMessage = null;

      await validateTransaction(
        amount: transaction.amount,
        categoryId: transaction.categoryId,
        date: transaction.date,
        description: transaction.description,
      );

      await addTransaction(transaction);
      await loadTransactions(userId: transaction.userId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> editTransaction(Transaction transaction) async {
    try {
      _errorMessage = null;

      await validateTransaction(
        amount: transaction.amount,
        categoryId: transaction.categoryId,
        date: transaction.date,
        description: transaction.description,
      );

      await updateTransaction(transaction);
      await loadTransactions(userId: transaction.userId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> removeTransaction(String id, String userId) async {
    try {
      _errorMessage = null;
      await deleteTransaction(id);
      await loadTransactions(userId: userId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<Transaction?> getById(String id) async {
    try {
      return await getTransactionById(id);
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  List<Transaction> get filteredTransactions {
    if (_currentFilter == null) return _allTransactions;

    return _allTransactions.where((transaction) {
      // Filter by type
      if (_currentFilter!.type != null &&
          transaction.type != _currentFilter!.type) {
        return false;
      }

      // Filter by date range
      if (_currentFilter!.startDate != null) {
        final startOfDay = DateTime(
          _currentFilter!.startDate!.year,
          _currentFilter!.startDate!.month,
          _currentFilter!.startDate!.day,
        );
        if (transaction.date.isBefore(startOfDay)) {
          return false;
        }
      }

      if (_currentFilter!.endDate != null) {
        final endOfDay = DateTime(
          _currentFilter!.endDate!.year,
          _currentFilter!.endDate!.month,
          _currentFilter!.endDate!.day,
          23,
          59,
          59,
        );
        if (transaction.date.isAfter(endOfDay)) {
          return false;
        }
      }

      // Filter by category
      if (_currentFilter!.categoryId != null &&
          transaction.categoryId != _currentFilter!.categoryId) {
        return false;
      }

      return true;
    }).toList();
  }

  void setFilter(TransactionFilter? filter) {
    _currentFilter = filter;
    _transactions = filteredTransactions;
    notifyListeners();
  }

  void clearFilter() {
    _currentFilter = null;
    _transactions = _allTransactions;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
