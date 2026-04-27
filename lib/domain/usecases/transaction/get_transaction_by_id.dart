import '../../entities/transaction.dart';
import '../../repositories/transaction_repository.dart';

class GetTransactionById {
  final TransactionRepository repository;

  GetTransactionById(this.repository);

  Future<Transaction?> call(String id) async {
    return await repository.getTransactionById(id);
  }
}
