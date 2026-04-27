import '../../entities/transaction.dart';
import '../../repositories/transaction_repository.dart';

class AddTransaction {
  final TransactionRepository repository;

  AddTransaction(this.repository);

  Future<String> call(Transaction transaction) async {
    return await repository.addTransaction(transaction);
  }
}
