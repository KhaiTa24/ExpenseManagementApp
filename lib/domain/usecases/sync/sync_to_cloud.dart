import '../../repositories/sync_repository.dart';

class SyncToCloud {
  final SyncRepository repository;

  SyncToCloud(this.repository);

  Future<void> call() async {
    final isOnline = await repository.isOnline();
    if (!isOnline) {
      throw Exception('Không có kết nối internet');
    }

    return await repository.syncToCloud();
  }
}
