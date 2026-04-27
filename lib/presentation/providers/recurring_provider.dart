import 'package:flutter/foundation.dart';
import '../../domain/entities/recurring_transaction.dart';
import '../../domain/usecases/recurring/create_recurring.dart';
import '../../domain/usecases/recurring/update_recurring.dart';
import '../../domain/usecases/recurring/delete_recurring.dart';
import '../../domain/usecases/recurring/process_recurring_transactions.dart';

enum RecurringLoadingState { initial, loading, loaded, error }

class RecurringProvider extends ChangeNotifier {
  final CreateRecurring createRecurring;
  final UpdateRecurring updateRecurring;
  final DeleteRecurring deleteRecurring;
  final ProcessRecurringTransactions processRecurringTransactions;

  RecurringProvider({
    required this.createRecurring,
    required this.updateRecurring,
    required this.deleteRecurring,
    required this.processRecurringTransactions,
  });

  RecurringLoadingState _state = RecurringLoadingState.initial;
  List<RecurringTransaction> _recurringTransactions = [];
  String? _errorMessage;

  RecurringLoadingState get state => _state;
  List<RecurringTransaction> get recurringTransactions => _recurringTransactions;
  String? get errorMessage => _errorMessage;

  List<RecurringTransaction> get activeRecurring =>
      _recurringTransactions.where((r) => r.isActive).toList();

  void _setState(RecurringLoadingState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _setState(RecurringLoadingState.error);
  }

  Future<bool> addNewRecurring(RecurringTransaction recurring) async {
    try {
      _errorMessage = null;
      await createRecurring(recurring);
      _recurringTransactions.add(recurring);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> editRecurring(RecurringTransaction recurring) async {
    try {
      _errorMessage = null;
      await updateRecurring(recurring);
      
      final index = _recurringTransactions.indexWhere((r) => r.id == recurring.id);
      if (index != -1) {
        _recurringTransactions[index] = recurring;
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> removeRecurring(String id) async {
    try {
      _errorMessage = null;
      await deleteRecurring(id);
      _recurringTransactions.removeWhere((r) => r.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<int> processDueTransactions() async {
    try {
      _errorMessage = null;
      final count = await processRecurringTransactions();
      return count;
    } catch (e) {
      _setError(e.toString());
      return 0;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
