class RouteNames {
  // Auth Routes
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String lock = '/lock';

  // Main Routes
  static const String home = '/home';

  // Transaction Routes
  static const String transactionList = '/transactions';
  static const String addTransaction = '/transactions/add';
  static const String editTransaction = '/transactions/edit';
  static const String transactionDetail = '/transactions/detail';

  // Category Routes
  static const String categoryList = '/categories';
  static const String addCategory = '/categories/add';

  // Budget Routes
  static const String budgetList = '/budgets';
  static const String addBudget = '/budgets/add';
  static const String budgetDetail = '/budgets/detail';
  static const String monthlyBudget = '/budgets/monthly';

  // Wallet Routes
  static const String walletList = '/wallets';
  static const String addWallet = '/wallets/add';

  // Recurring Routes
  static const String recurringList = '/recurring';
  static const String addRecurring = '/recurring/add';

  // Report Routes
  static const String report = '/report';
  static const String expenseReport = '/report/expense';
  static const String incomeReport = '/report/income';

  // Profile Routes
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String changePassword = '/settings/change-password';
  static const String pinSetup = '/settings/pin-setup';
  static const String biometricSetup = '/settings/biometric-setup';
  static const String notificationSettings = '/settings/notifications';
  static const String notifications = '/notifications';

  // Search Route
  static const String search = '/search';

  // AI Routes
  static const String aiInsights = '/ai-insights';
  static const String aiSettings = '/ai-settings';

  // Community Routes
  static const String communityWallets = '/community-wallets';
  static const String createCommunityWallet = '/community-wallets/create';
  static const String communityWalletDetail = '/community-wallets/detail';
  static const String inviteMember = '/community-wallets/invite-member';
  static const String memberDetail = '/community-wallets/member-detail';
  static const String uniqueIdentifierSetup = '/settings/unique-identifier';
}
