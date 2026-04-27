abstract class SyncRepository {
  Future<void> syncToCloud();
  
  Future<void> syncFromCloud();
  
  Future<DateTime?> getLastSyncTime();
  
  Future<bool> isOnline();
  
  Future<void> enableAutoSync();
  
  Future<void> disableAutoSync();
  
  Future<bool> isAutoSyncEnabled();
}
