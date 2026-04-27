class DatabaseConstants {
  // Database
  static const String databaseName = 'money_manager.db';
  static const int databaseVersion = 5; // Force recreate database
  
  // Tables
  static const String tableUsers = 'users';
  static const String tableCategories = 'categories';
  static const String tableTransactions = 'transactions';
  static const String tableBudgets = 'budgets';
  static const String tableSettings = 'settings';
  static const String walletsTable = 'wallets';
  static const String recurringTable = 'recurring_transactions';
  static const String communityWalletsTable = 'community_wallets';
  static const String communityMembersTable = 'community_members';
  
  // Users Table Columns
  static const String columnUserId = 'id';
  static const String columnUserEmail = 'email';
  static const String columnUserDisplayName = 'display_name';
  static const String columnUserUniqueIdentifier = 'unique_identifier';
  static const String columnUserCreatedAt = 'created_at';
  
  // Categories Table Columns
  static const String columnCategoryId = 'id';
  static const String columnCategoryUserId = 'user_id';
  static const String columnCategoryName = 'name';
  static const String columnCategoryIcon = 'icon';
  static const String columnCategoryColor = 'color';
  static const String columnCategoryType = 'type';
  static const String columnCategoryIsDefault = 'is_default';
  static const String columnCategoryCreatedAt = 'created_at';
  
  // Transactions Table Columns
  static const String columnTransactionId = 'id';
  static const String columnTransactionUserId = 'user_id';
  static const String columnTransactionCategoryId = 'category_id';
  static const String columnTransactionAmount = 'amount';
  static const String columnTransactionType = 'type';
  static const String columnTransactionDescription = 'description';
  static const String columnTransactionDate = 'date';
  static const String columnTransactionCreatedAt = 'created_at';
  static const String columnTransactionUpdatedAt = 'updated_at';
  static const String columnTransactionWalletId = 'wallet_id';
  static const String columnTransactionCommunityWalletId = 'community_wallet_id';
  
  // Budgets Table Columns
  static const String columnBudgetId = 'id';
  static const String columnBudgetUserId = 'user_id';
  static const String columnBudgetCategoryId = 'category_id';
  static const String columnBudgetAmount = 'amount';
  static const String columnBudgetPeriod = 'period';
  static const String columnBudgetMonth = 'month';
  static const String columnBudgetYear = 'year';
  static const String columnBudgetCreatedAt = 'created_at';
  
  // Settings Table Columns
  static const String columnSettingId = 'id';
  static const String columnSettingUserId = 'user_id';
  static const String columnSettingKey = 'key';
  static const String columnSettingValue = 'value';
  
  // Wallets Table Columns
  static const String walletId = 'id';
  static const String walletUserId = 'user_id';
  static const String walletName = 'name';
  static const String walletBalance = 'balance';
  static const String walletIcon = 'icon';
  static const String walletColor = 'color';
  static const String walletCreatedAt = 'created_at';
  static const String walletUpdatedAt = 'updated_at';
  
  // Recurring Transactions Table Columns
  static const String recurringId = 'id';
  static const String recurringUserId = 'user_id';
  static const String recurringCategoryId = 'category_id';
  static const String recurringAmount = 'amount';
  static const String recurringType = 'type';
  static const String recurringDescription = 'description';
  static const String recurringFrequency = 'frequency';
  static const String recurringStartDate = 'start_date';
  static const String recurringEndDate = 'end_date';
  static const String recurringLastProcessedDate = 'last_processed_date';
  static const String recurringIsActive = 'is_active';
  static const String recurringCreatedAt = 'created_at';
  
  // Community Wallets Table Columns
  static const String communityWalletId = 'id';
  static const String communityWalletName = 'name';
  static const String communityWalletDescription = 'description';
  static const String communityWalletBalance = 'balance';
  static const String communityWalletOwnerId = 'owner_id';
  static const String communityWalletIcon = 'icon';
  static const String communityWalletColor = 'color';
  static const String communityWalletCreatedAt = 'created_at';
  static const String communityWalletUpdatedAt = 'updated_at';
  
  // Community Members Table Columns
  static const String communityMemberId = 'id';
  static const String communityMemberWalletId = 'community_wallet_id';
  static const String communityMemberUserId = 'user_id';
  static const String communityMemberRole = 'role';
  static const String communityMemberJoinedAt = 'joined_at';
  static const String communityMemberIsActive = 'is_active';
  
  // Notifications Table
  static const String notificationsTable = 'notifications';
  static const String notificationId = 'id';
  static const String notificationUserId = 'user_id';
  static const String notificationType = 'type';
  static const String notificationTitle = 'title';
  static const String notificationMessage = 'message';
  static const String notificationData = 'data';
  static const String notificationIsRead = 'is_read';
  static const String notificationCreatedAt = 'created_at';
  
  // Community Invitations Table
  static const String communityInvitationsTable = 'community_invitations';
  static const String invitationId = 'id';
  static const String invitationCommunityWalletId = 'community_wallet_id';
  static const String invitationInviterId = 'inviter_id';
  static const String invitationInviteeId = 'invitee_id';
  static const String invitationStatus = 'status';
  static const String invitationCreatedAt = 'created_at';
  static const String invitationRespondedAt = 'responded_at';
}
