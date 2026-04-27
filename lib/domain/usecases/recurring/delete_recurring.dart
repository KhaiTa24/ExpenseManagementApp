import '../../repositories/recurring_repository.dart';

class DeleteRecurring {
  final RecurringRepository repository;

  DeleteRecurring(this.repository);

  Future<void> call(String id) async {
    return await repository.deleteRecurring(id);
  }
}
