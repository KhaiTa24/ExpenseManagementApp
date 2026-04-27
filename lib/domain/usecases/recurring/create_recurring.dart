import '../../entities/recurring_transaction.dart';
import '../../repositories/recurring_repository.dart';

class CreateRecurring {
  final RecurringRepository repository;

  CreateRecurring(this.repository);

  Future<String> call(RecurringTransaction recurring) async {
    return await repository.createRecurring(recurring);
  }
}
