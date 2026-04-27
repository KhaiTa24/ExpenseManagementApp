class FirebaseConstants {
  // Firestore Collections
  static const String usersCollection = 'users';
  static const String categoriesCollection = 'categories';
  static const String transactionsCollection = 'transactions';
  static const String budgetsCollection = 'budgets';
  static const String settingsCollection = 'settings';
  
  // Storage Paths
  static const String backupsPath = 'backups';
  static const String userBackupsPath = 'backups/users';
  
  // Firestore Fields
  static const String fieldUserId = 'userId';
  static const String fieldEmail = 'email';
  static const String fieldDisplayName = 'displayName';
  static const String fieldCreatedAt = 'createdAt';
  static const String fieldUpdatedAt = 'updatedAt';
  static const String fieldLastSyncAt = 'lastSyncAt';
  
  // Auth Providers
  static const String emailProvider = 'password';
  static const String googleProvider = 'google.com';
}
