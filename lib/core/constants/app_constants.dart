class AppConstants {
  // App Info
  static const String appName = 'Money Manager';
  static const String appVersion = '1.0.0';
  
  // Validation
  static const double minAmount = 1000.0; // 1,000 VND
  static const double maxAmount = 999999999999.0;
  static const int maxDecimalPlaces = 2;
  static const int minCategoryNameLength = 2;
  static const int maxCategoryNameLength = 50;
  static const int maxDescriptionLength = 200;
  static const int maxCategoriesPerUser = 50;
  
  // PIN & Security
  static const int pinLength = 6;
  static const int maxPinAttempts = 5;
  static const int lockoutDurationMinutes = 30;
  static const int maxBiometricAttempts = 3;
  static const int reAuthTimeoutMinutes = 30;
  
  // Password Requirements
  static const int minPasswordLength = 8;
  
  // Budget
  static const double minBudget = 10000.0; // 10,000 VND
  static const double maxBudget = 999999999.0;
  static const double budgetWarningThreshold = 0.8; // 80%
  static const double budgetDangerThreshold = 1.0; // 100%
  
  // Pagination
  static const int transactionsPerPage = 50;
  static const int cacheLimit = 100;
  
  // Sync
  static const int autoSyncIntervalMinutes = 5;
  static const int cacheTimeoutHours = 1;
  
  // Backup
  static const int backupRetentionDays = 30;
  static const int autoBackupHour = 2; // 2:00 AM
  
  // Notifications
  static const int defaultReminderHour = 20; // 20:00
  static const int noTransactionReminderDays = 3;
  static const int maxNotificationsPerCategoryPerDay = 1;
  
  // Currency
  static const String defaultCurrency = 'VND';
  static const String currencySymbol = '₫';
  
  // Date Format
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String monthYearFormat = 'MM/yyyy';
}
