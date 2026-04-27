import '../../entities/recurring_transaction.dart';
import '../../repositories/recurring_repository.dart';

class UpdateRecurring {
  final RecurringRepository repository;

  UpdateRecurring(this.repository);

  Future<void> call(RecurringTransaction recurring) async {
    return await repository.updateRecurring(recurring);
  }
}
