import '../../entities/transaction.dart';
import '../../repositories/transaction_repository.dart';

class GetTransactions {
  final TransactionRepository repository;

  GetTransactions(this.repository);

  Future<List<Transaction>> call({
    String? userId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    int? limit,
    int? offset,
  }) async {
    return await repository.getTransactions(
      userId: userId,
      categoryId: categoryId,
      startDate: startDate,
      endDate: endDate,
      type: type,
      limit: limit,
      offset: offset,
    );
  }
}
