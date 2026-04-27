import '../../entities/recurring_transaction.dart';
import '../../entities/transaction.dart';
import '../../repositories/recurring_repository.dart';
import '../../repositories/transaction_repository.dart';
import 'package:uuid/uuid.dart';

class ProcessRecurringTransactions {
  final RecurringRepository recurringRepository;
  final TransactionRepository transactionRepository;
  final Uuid uuid;

  ProcessRecurringTransactions({
    required this.recurringRepository,
    required this.transactionRepository,
    required this.uuid,
  });

  Future<int> call() async {
    final dueRecurring = await recurringRepository.getDueRecurringTransactions();
    int processedCount = 0;

    for (var recurring in dueRecurring) {
      if (_shouldProcess(recurring)) {
        await _createTransactionFromRecurring(recurring);
        await recurringRepository.updateLastProcessedDate(
          recurring.id,
          DateTime.now(),
        );
        processedCount++;
      }
    }

    return processedCount;
  }

  bool _shouldProcess(RecurringTransaction recurring) {
    if (!recurring.isActive) return false;

    final now = DateTime.now();
    
    // Check if end date has passed
    if (recurring.endDate != null && now.isAfter(recurring.endDate!)) {
      return false;
    }

    // Check if it's time to process based on frequency
    final lastProcessed = recurring.lastProcessedDate ?? recurring.startDate;
    
    switch (recurring.frequency) {
      case 'daily':
        return now.difference(lastProcessed).inDays >= 1;
      case 'weekly':
        return now.difference(lastProcessed).inDays >= 7;
      case 'monthly':
        return now.difference(lastProcessed).inDays >= 30;
      case 'yearly':
        return now.difference(lastProcessed).inDays >= 365;
      default:
        return false;
    }
  }

  Future<void> _createTransactionFromRecurring(
    RecurringTransaction recurring,
  ) async {
    final transaction = Transaction(
      id: uuid.v4(),
      userId: recurring.userId,
      categoryId: recurring.categoryId,
      amount: recurring.amount,
      type: recurring.type,
      description: recurring.description,
      date: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await transactionRepository.addTransaction(transaction);
  }
}
