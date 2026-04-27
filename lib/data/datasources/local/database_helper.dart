import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../../core/constants/database_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, DatabaseConstants.databaseName);

    return await openDatabase(
      path,
      version: DatabaseConstants.databaseVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Users Table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableUsers} (
        ${DatabaseConstants.columnUserId} TEXT PRIMARY KEY,
        ${DatabaseConstants.columnUserEmail} TEXT UNIQUE,
        ${DatabaseConstants.columnUserDisplayName} TEXT,
        ${DatabaseConstants.columnUserUniqueIdentifier} TEXT,
        ${DatabaseConstants.columnUserCreatedAt} INTEGER
      )
    ''');

    // Categories Table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableCategories} (
        ${DatabaseConstants.columnCategoryId} TEXT PRIMARY KEY,
        ${DatabaseConstants.columnCategoryUserId} TEXT,
        ${DatabaseConstants.columnCategoryName} TEXT NOT NULL,
        ${DatabaseConstants.columnCategoryIcon} TEXT,
        ${DatabaseConstants.columnCategoryColor} TEXT,
        ${DatabaseConstants.columnCategoryType} TEXT CHECK(${DatabaseConstants.columnCategoryType} IN ('income', 'expense')),
        ${DatabaseConstants.columnCategoryIsDefault} INTEGER DEFAULT 0,
        ${DatabaseConstants.columnCategoryCreatedAt} INTEGER,
        FOREIGN KEY (${DatabaseConstants.columnCategoryUserId}) REFERENCES ${DatabaseConstants.tableUsers}(${DatabaseConstants.columnUserId})
      )
    ''');

    // Transactions Table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableTransactions} (
        ${DatabaseConstants.columnTransactionId} TEXT PRIMARY KEY,
        ${DatabaseConstants.columnTransactionUserId} TEXT,
        ${DatabaseConstants.columnTransactionCategoryId} TEXT,
        ${DatabaseConstants.columnTransactionAmount} REAL NOT NULL,
        ${DatabaseConstants.columnTransactionType} TEXT CHECK(${DatabaseConstants.columnTransactionType} IN ('income', 'expense')),
        ${DatabaseConstants.columnTransactionDescription} TEXT,
        ${DatabaseConstants.columnTransactionDate} INTEGER NOT NULL,
        ${DatabaseConstants.columnTransactionCreatedAt} INTEGER,
        ${DatabaseConstants.columnTransactionUpdatedAt} INTEGER,
        ${DatabaseConstants.columnTransactionWalletId} TEXT,
        ${DatabaseConstants.columnTransactionCommunityWalletId} TEXT,
        FOREIGN KEY (${DatabaseConstants.columnTransactionUserId}) REFERENCES ${DatabaseConstants.tableUsers}(${DatabaseConstants.columnUserId}),
        FOREIGN KEY (${DatabaseConstants.columnTransactionCategoryId}) REFERENCES ${DatabaseConstants.tableCategories}(${DatabaseConstants.columnCategoryId}),
        FOREIGN KEY (${DatabaseConstants.columnTransactionWalletId}) REFERENCES ${DatabaseConstants.walletsTable}(${DatabaseConstants.walletId}),
        FOREIGN KEY (${DatabaseConstants.columnTransactionCommunityWalletId}) REFERENCES ${DatabaseConstants.communityWalletsTable}(${DatabaseConstants.communityWalletId})
      )
    ''');

    // Budgets Table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableBudgets} (
        ${DatabaseConstants.columnBudgetId} TEXT PRIMARY KEY,
        ${DatabaseConstants.columnBudgetUserId} TEXT,
        ${DatabaseConstants.columnBudgetCategoryId} TEXT,
        ${DatabaseConstants.columnBudgetAmount} REAL NOT NULL,
        ${DatabaseConstants.columnBudgetPeriod} TEXT CHECK(${DatabaseConstants.columnBudgetPeriod} IN ('monthly', 'yearly')),
        ${DatabaseConstants.columnBudgetMonth} INTEGER,
        ${DatabaseConstants.columnBudgetYear} INTEGER,
        ${DatabaseConstants.columnBudgetCreatedAt} INTEGER,
        FOREIGN KEY (${DatabaseConstants.columnBudgetUserId}) REFERENCES ${DatabaseConstants.tableUsers}(${DatabaseConstants.columnUserId}),
        FOREIGN KEY (${DatabaseConstants.columnBudgetCategoryId}) REFERENCES ${DatabaseConstants.tableCategories}(${DatabaseConstants.columnCategoryId})
      )
    ''');

    // Settings Table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.tableSettings} (
        ${DatabaseConstants.columnSettingId} TEXT PRIMARY KEY,
        ${DatabaseConstants.columnSettingUserId} TEXT,
        ${DatabaseConstants.columnSettingKey} TEXT NOT NULL,
        ${DatabaseConstants.columnSettingValue} TEXT,
        FOREIGN KEY (${DatabaseConstants.columnSettingUserId}) REFERENCES ${DatabaseConstants.tableUsers}(${DatabaseConstants.columnUserId})
      )
    ''');

    // Wallets Table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.walletsTable} (
        ${DatabaseConstants.walletId} TEXT PRIMARY KEY,
        ${DatabaseConstants.walletUserId} TEXT,
        ${DatabaseConstants.walletName} TEXT NOT NULL,
        ${DatabaseConstants.walletBalance} REAL NOT NULL DEFAULT 0,
        ${DatabaseConstants.walletIcon} TEXT,
        ${DatabaseConstants.walletColor} TEXT,
        ${DatabaseConstants.walletCreatedAt} INTEGER,
        ${DatabaseConstants.walletUpdatedAt} INTEGER,
        FOREIGN KEY (${DatabaseConstants.walletUserId}) REFERENCES ${DatabaseConstants.tableUsers}(${DatabaseConstants.columnUserId})
      )
    ''');

    // Recurring Transactions Table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.recurringTable} (
        ${DatabaseConstants.recurringId} TEXT PRIMARY KEY,
        ${DatabaseConstants.recurringUserId} TEXT,
        ${DatabaseConstants.recurringCategoryId} TEXT,
        ${DatabaseConstants.recurringAmount} REAL NOT NULL,
        ${DatabaseConstants.recurringType} TEXT CHECK(${DatabaseConstants.recurringType} IN ('income', 'expense')),
        ${DatabaseConstants.recurringDescription} TEXT,
        ${DatabaseConstants.recurringFrequency} TEXT CHECK(${DatabaseConstants.recurringFrequency} IN ('daily', 'weekly', 'monthly', 'yearly')),
        ${DatabaseConstants.recurringStartDate} INTEGER NOT NULL,
        ${DatabaseConstants.recurringEndDate} INTEGER,
        ${DatabaseConstants.recurringLastProcessedDate} INTEGER,
        ${DatabaseConstants.recurringIsActive} INTEGER DEFAULT 1,
        ${DatabaseConstants.recurringCreatedAt} INTEGER,
        FOREIGN KEY (${DatabaseConstants.recurringUserId}) REFERENCES ${DatabaseConstants.tableUsers}(${DatabaseConstants.columnUserId}),
        FOREIGN KEY (${DatabaseConstants.recurringCategoryId}) REFERENCES ${DatabaseConstants.tableCategories}(${DatabaseConstants.columnCategoryId})
      )
    ''');

    // Community Wallets Table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.communityWalletsTable} (
        ${DatabaseConstants.communityWalletId} TEXT PRIMARY KEY,
        ${DatabaseConstants.communityWalletName} TEXT NOT NULL,
        ${DatabaseConstants.communityWalletDescription} TEXT,
        ${DatabaseConstants.communityWalletBalance} REAL NOT NULL DEFAULT 0,
        ${DatabaseConstants.communityWalletOwnerId} TEXT NOT NULL,
        ${DatabaseConstants.communityWalletIcon} TEXT,
        ${DatabaseConstants.communityWalletColor} TEXT,
        ${DatabaseConstants.communityWalletCreatedAt} INTEGER,
        ${DatabaseConstants.communityWalletUpdatedAt} INTEGER,
        FOREIGN KEY (${DatabaseConstants.communityWalletOwnerId}) REFERENCES ${DatabaseConstants.tableUsers}(${DatabaseConstants.columnUserId})
      )
    ''');

    // Community Members Table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.communityMembersTable} (
        ${DatabaseConstants.communityMemberId} TEXT PRIMARY KEY,
        ${DatabaseConstants.communityMemberWalletId} TEXT NOT NULL,
        ${DatabaseConstants.communityMemberUserId} TEXT NOT NULL,
        ${DatabaseConstants.communityMemberRole} TEXT CHECK(${DatabaseConstants.communityMemberRole} IN ('owner', 'admin', 'member')),
        ${DatabaseConstants.communityMemberJoinedAt} INTEGER,
        ${DatabaseConstants.communityMemberIsActive} INTEGER DEFAULT 1,
        FOREIGN KEY (${DatabaseConstants.communityMemberWalletId}) REFERENCES ${DatabaseConstants.communityWalletsTable}(${DatabaseConstants.communityWalletId}),
        FOREIGN KEY (${DatabaseConstants.communityMemberUserId}) REFERENCES ${DatabaseConstants.tableUsers}(${DatabaseConstants.columnUserId}),
        UNIQUE(${DatabaseConstants.communityMemberWalletId}, ${DatabaseConstants.communityMemberUserId})
      )
    ''');

    // Notifications Table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.notificationsTable} (
        ${DatabaseConstants.notificationId} TEXT PRIMARY KEY,
        ${DatabaseConstants.notificationUserId} TEXT NOT NULL,
        ${DatabaseConstants.notificationType} TEXT NOT NULL,
        ${DatabaseConstants.notificationTitle} TEXT NOT NULL,
        ${DatabaseConstants.notificationMessage} TEXT NOT NULL,
        ${DatabaseConstants.notificationData} TEXT,
        ${DatabaseConstants.notificationIsRead} INTEGER DEFAULT 0,
        ${DatabaseConstants.notificationCreatedAt} INTEGER,
        FOREIGN KEY (${DatabaseConstants.notificationUserId}) REFERENCES ${DatabaseConstants.tableUsers}(${DatabaseConstants.columnUserId})
      )
    ''');

    // Community Invitations Table
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.communityInvitationsTable} (
        ${DatabaseConstants.invitationId} TEXT PRIMARY KEY,
        ${DatabaseConstants.invitationCommunityWalletId} TEXT NOT NULL,
        ${DatabaseConstants.invitationInviterId} TEXT NOT NULL,
        ${DatabaseConstants.invitationInviteeId} TEXT NOT NULL,
        ${DatabaseConstants.invitationStatus} TEXT CHECK(${DatabaseConstants.invitationStatus} IN ('pending', 'accepted', 'rejected')) DEFAULT 'pending',
        ${DatabaseConstants.invitationCreatedAt} INTEGER,
        ${DatabaseConstants.invitationRespondedAt} INTEGER,
        FOREIGN KEY (${DatabaseConstants.invitationCommunityWalletId}) REFERENCES ${DatabaseConstants.communityWalletsTable}(${DatabaseConstants.communityWalletId}),
        FOREIGN KEY (${DatabaseConstants.invitationInviterId}) REFERENCES ${DatabaseConstants.tableUsers}(${DatabaseConstants.columnUserId}),
        FOREIGN KEY (${DatabaseConstants.invitationInviteeId}) REFERENCES ${DatabaseConstants.tableUsers}(${DatabaseConstants.columnUserId}),
        UNIQUE(${DatabaseConstants.invitationCommunityWalletId}, ${DatabaseConstants.invitationInviteeId})
      )
    ''');

    // Create indexes for better query performance
    await db.execute('''
      CREATE INDEX idx_transactions_user_date 
      ON ${DatabaseConstants.tableTransactions}(${DatabaseConstants.columnTransactionUserId}, ${DatabaseConstants.columnTransactionDate})
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_category 
      ON ${DatabaseConstants.tableTransactions}(${DatabaseConstants.columnTransactionCategoryId})
    ''');

    await db.execute('''
      CREATE INDEX idx_categories_user_type 
      ON ${DatabaseConstants.tableCategories}(${DatabaseConstants.columnCategoryUserId}, ${DatabaseConstants.columnCategoryType})
    ''');

    await db.execute('''
      CREATE INDEX idx_wallets_user 
      ON ${DatabaseConstants.walletsTable}(${DatabaseConstants.walletUserId})
    ''');

    await db.execute('''
      CREATE INDEX idx_recurring_user_active 
      ON ${DatabaseConstants.recurringTable}(${DatabaseConstants.recurringUserId}, ${DatabaseConstants.recurringIsActive})
    ''');

    await db.execute('''
      CREATE INDEX idx_community_wallets_owner 
      ON ${DatabaseConstants.communityWalletsTable}(${DatabaseConstants.communityWalletOwnerId})
    ''');

    await db.execute('''
      CREATE INDEX idx_community_members_wallet 
      ON ${DatabaseConstants.communityMembersTable}(${DatabaseConstants.communityMemberWalletId})
    ''');

    await db.execute('''
      CREATE INDEX idx_community_members_user 
      ON ${DatabaseConstants.communityMembersTable}(${DatabaseConstants.communityMemberUserId})
    ''');

    await db.execute('''
      CREATE INDEX idx_users_unique_identifier 
      ON ${DatabaseConstants.tableUsers}(${DatabaseConstants.columnUserUniqueIdentifier})
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_community_wallet 
      ON ${DatabaseConstants.tableTransactions}(${DatabaseConstants.columnTransactionCommunityWalletId})
    ''');

    await db.execute('''
      CREATE INDEX idx_notifications_user_read 
      ON ${DatabaseConstants.notificationsTable}(${DatabaseConstants.notificationUserId}, ${DatabaseConstants.notificationIsRead})
    ''');

    await db.execute('''
      CREATE INDEX idx_invitations_invitee_status 
      ON ${DatabaseConstants.communityInvitationsTable}(${DatabaseConstants.invitationInviteeId}, ${DatabaseConstants.invitationStatus})
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add unique_identifier column to users table
      await db.execute('''
        ALTER TABLE ${DatabaseConstants.tableUsers} 
        ADD COLUMN ${DatabaseConstants.columnUserUniqueIdentifier} TEXT
      ''');

      // Add wallet_id and community_wallet_id columns to transactions table
      await db.execute('''
        ALTER TABLE ${DatabaseConstants.tableTransactions} 
        ADD COLUMN ${DatabaseConstants.columnTransactionWalletId} TEXT
      ''');

      await db.execute('''
        ALTER TABLE ${DatabaseConstants.tableTransactions} 
        ADD COLUMN ${DatabaseConstants.columnTransactionCommunityWalletId} TEXT
      ''');

      // Create Community Wallets Table
      await db.execute('''
        CREATE TABLE ${DatabaseConstants.communityWalletsTable} (
          ${DatabaseConstants.communityWalletId} TEXT PRIMARY KEY,
          ${DatabaseConstants.communityWalletName} TEXT NOT NULL,
          ${DatabaseConstants.communityWalletDescription} TEXT,
          ${DatabaseConstants.communityWalletBalance} REAL NOT NULL DEFAULT 0,
          ${DatabaseConstants.communityWalletOwnerId} TEXT NOT NULL,
          ${DatabaseConstants.communityWalletIcon} TEXT,
          ${DatabaseConstants.communityWalletColor} TEXT,
          ${DatabaseConstants.communityWalletCreatedAt} INTEGER,
          ${DatabaseConstants.communityWalletUpdatedAt} INTEGER,
          FOREIGN KEY (${DatabaseConstants.communityWalletOwnerId}) REFERENCES ${DatabaseConstants.tableUsers}(${DatabaseConstants.columnUserId})
        )
      ''');

      // Create Community Members Table
      await db.execute('''
        CREATE TABLE ${DatabaseConstants.communityMembersTable} (
          ${DatabaseConstants.communityMemberId} TEXT PRIMARY KEY,
          ${DatabaseConstants.communityMemberWalletId} TEXT NOT NULL,
          ${DatabaseConstants.communityMemberUserId} TEXT NOT NULL,
          ${DatabaseConstants.communityMemberRole} TEXT CHECK(${DatabaseConstants.communityMemberRole} IN ('owner', 'admin', 'member')),
          ${DatabaseConstants.communityMemberJoinedAt} INTEGER,
          ${DatabaseConstants.communityMemberIsActive} INTEGER DEFAULT 1,
          FOREIGN KEY (${DatabaseConstants.communityMemberWalletId}) REFERENCES ${DatabaseConstants.communityWalletsTable}(${DatabaseConstants.communityWalletId}),
          FOREIGN KEY (${DatabaseConstants.communityMemberUserId}) REFERENCES ${DatabaseConstants.tableUsers}(${DatabaseConstants.columnUserId}),
          UNIQUE(${DatabaseConstants.communityMemberWalletId}, ${DatabaseConstants.communityMemberUserId})
        )
      ''');
    }

    if (oldVersion < 3) {
      // Create Notifications Table
      await db.execute('''
        CREATE TABLE ${DatabaseConstants.notificationsTable} (
          ${DatabaseConstants.notificationId} TEXT PRIMARY KEY,
          ${DatabaseConstants.notificationUserId} TEXT NOT NULL,
          ${DatabaseConstants.notificationType} TEXT NOT NULL,
          ${DatabaseConstants.notificationTitle} TEXT NOT NULL,
          ${DatabaseConstants.notificationMessage} TEXT NOT NULL,
          ${DatabaseConstants.notificationData} TEXT,
          ${DatabaseConstants.notificationIsRead} INTEGER DEFAULT 0,
          ${DatabaseConstants.notificationCreatedAt} INTEGER,
          FOREIGN KEY (${DatabaseConstants.notificationUserId}) REFERENCES ${DatabaseConstants.tableUsers}(${DatabaseConstants.columnUserId})
        )
      ''');

      // Create Community Invitations Table
      await db.execute('''
        CREATE TABLE ${DatabaseConstants.communityInvitationsTable} (
          ${DatabaseConstants.invitationId} TEXT PRIMARY KEY,
          ${DatabaseConstants.invitationCommunityWalletId} TEXT NOT NULL,
          ${DatabaseConstants.invitationInviterId} TEXT NOT NULL,
          ${DatabaseConstants.invitationInviteeId} TEXT NOT NULL,
          ${DatabaseConstants.invitationStatus} TEXT CHECK(${DatabaseConstants.invitationStatus} IN ('pending', 'accepted', 'rejected')) DEFAULT 'pending',
          ${DatabaseConstants.invitationCreatedAt} INTEGER,
          ${DatabaseConstants.invitationRespondedAt} INTEGER,
          FOREIGN KEY (${DatabaseConstants.invitationCommunityWalletId}) REFERENCES ${DatabaseConstants.communityWalletsTable}(${DatabaseConstants.communityWalletId}),
          FOREIGN KEY (${DatabaseConstants.invitationInviterId}) REFERENCES ${DatabaseConstants.tableUsers}(${DatabaseConstants.columnUserId}),
          FOREIGN KEY (${DatabaseConstants.invitationInviteeId}) REFERENCES ${DatabaseConstants.tableUsers}(${DatabaseConstants.columnUserId}),
          UNIQUE(${DatabaseConstants.invitationCommunityWalletId}, ${DatabaseConstants.invitationInviteeId})
        )
      ''');

      // Create indexes for new tables
      await db.execute('''
        CREATE INDEX idx_notifications_user_read 
        ON ${DatabaseConstants.notificationsTable}(${DatabaseConstants.notificationUserId}, ${DatabaseConstants.notificationIsRead})
      ''');

      await db.execute('''
        CREATE INDEX idx_invitations_invitee_status 
        ON ${DatabaseConstants.communityInvitationsTable}(${DatabaseConstants.invitationInviteeId}, ${DatabaseConstants.invitationStatus})
      ''');
    }

    if (oldVersion < 5) {
      // Force recreate all tables for clean schema
      await db.execute('DROP TABLE IF EXISTS ${DatabaseConstants.communityInvitationsTable}');
      await db.execute('DROP TABLE IF EXISTS ${DatabaseConstants.notificationsTable}');
      
      // Recreate notifications table
      await db.execute('''
        CREATE TABLE ${DatabaseConstants.notificationsTable} (
          ${DatabaseConstants.notificationId} TEXT PRIMARY KEY,
          ${DatabaseConstants.notificationUserId} TEXT NOT NULL,
          ${DatabaseConstants.notificationType} TEXT NOT NULL,
          ${DatabaseConstants.notificationTitle} TEXT NOT NULL,
          ${DatabaseConstants.notificationMessage} TEXT NOT NULL,
          ${DatabaseConstants.notificationData} TEXT,
          ${DatabaseConstants.notificationIsRead} INTEGER DEFAULT 0,
          ${DatabaseConstants.notificationCreatedAt} INTEGER,
          FOREIGN KEY (${DatabaseConstants.notificationUserId}) REFERENCES ${DatabaseConstants.tableUsers}(${DatabaseConstants.columnUserId})
        )
      ''');

      // Recreate invitations table
      await db.execute('''
        CREATE TABLE ${DatabaseConstants.communityInvitationsTable} (
          ${DatabaseConstants.invitationId} TEXT PRIMARY KEY,
          ${DatabaseConstants.invitationCommunityWalletId} TEXT NOT NULL,
          ${DatabaseConstants.invitationInviterId} TEXT NOT NULL,
          ${DatabaseConstants.invitationInviteeId} TEXT NOT NULL,
          ${DatabaseConstants.invitationStatus} TEXT CHECK(${DatabaseConstants.invitationStatus} IN ('pending', 'accepted', 'rejected')) DEFAULT 'pending',
          ${DatabaseConstants.invitationCreatedAt} INTEGER,
          ${DatabaseConstants.invitationRespondedAt} INTEGER,
          FOREIGN KEY (${DatabaseConstants.invitationCommunityWalletId}) REFERENCES ${DatabaseConstants.communityWalletsTable}(${DatabaseConstants.communityWalletId}),
          FOREIGN KEY (${DatabaseConstants.invitationInviterId}) REFERENCES ${DatabaseConstants.tableUsers}(${DatabaseConstants.columnUserId}),
          FOREIGN KEY (${DatabaseConstants.invitationInviteeId}) REFERENCES ${DatabaseConstants.tableUsers}(${DatabaseConstants.columnUserId}),
          UNIQUE(${DatabaseConstants.invitationCommunityWalletId}, ${DatabaseConstants.invitationInviteeId})
        )
      ''');

      // Recreate indexes
      await db.execute('''
        CREATE INDEX idx_notifications_user_read 
        ON ${DatabaseConstants.notificationsTable}(${DatabaseConstants.notificationUserId}, ${DatabaseConstants.notificationIsRead})
      ''');

      await db.execute('''
        CREATE INDEX idx_invitations_invitee_status 
        ON ${DatabaseConstants.communityInvitationsTable}(${DatabaseConstants.invitationInviteeId}, ${DatabaseConstants.invitationStatus})
      ''');
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, DatabaseConstants.databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
