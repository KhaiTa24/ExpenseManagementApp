import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:uuid/uuid.dart';

// Data sources
import '../../data/datasources/local/database_helper.dart';
import '../../data/datasources/local/transaction_local_datasource.dart';
import '../../data/datasources/local/category_local_datasource.dart';
import '../../data/datasources/local/budget_local_datasource.dart';
import '../../data/datasources/local/wallet_local_datasource.dart';
import '../../data/datasources/local/recurring_local_datasource.dart';
import '../../data/datasources/remote/firebase_auth_datasource.dart';
import '../../data/datasources/remote/firestore_datasource.dart';
import '../../data/datasources/remote/firebase_storage_datasource.dart';

// Repositories
import '../../data/repositories/transaction_repository_impl.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../data/repositories/budget_repository_impl.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../data/repositories/recurring_repository_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/sync_repository_impl.dart';
import '../../data/repositories/community_wallet_repository_impl.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/budget_repository.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../domain/repositories/recurring_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/sync_repository.dart';
import '../../domain/repositories/community_wallet_repository.dart';

// Use cases - Transaction
import '../../domain/usecases/transaction/add_transaction.dart';
import '../../domain/usecases/transaction/update_transaction.dart';
import '../../domain/usecases/transaction/delete_transaction.dart';
import '../../domain/usecases/transaction/get_transactions.dart';
import '../../domain/usecases/transaction/get_transaction_by_id.dart';

// Use cases - Category
import '../../domain/usecases/category/add_category.dart';
import '../../domain/usecases/category/update_category.dart';
import '../../domain/usecases/category/delete_category.dart';
import '../../domain/usecases/category/get_categories.dart';
import '../../domain/usecases/category/initialize_default_categories.dart';

// Use cases - Budget
import '../../domain/usecases/budget/create_budget.dart';
import '../../domain/usecases/budget/update_budget.dart';
import '../../domain/usecases/budget/delete_budget.dart';
import '../../domain/usecases/budget/get_budgets.dart';
import '../../domain/usecases/budget/check_budget_status.dart';

// Use cases - Wallet
import '../../domain/usecases/wallet/create_wallet.dart';
import '../../domain/usecases/wallet/update_wallet.dart';
import '../../domain/usecases/wallet/delete_wallet.dart';
import '../../domain/usecases/wallet/get_wallets.dart';

// Use cases - Recurring
import '../../domain/usecases/recurring/create_recurring.dart';
import '../../domain/usecases/recurring/update_recurring.dart';
import '../../domain/usecases/recurring/delete_recurring.dart';
import '../../domain/usecases/recurring/process_recurring_transactions.dart';

// Use cases - Auth
import '../../domain/usecases/auth/login_with_email.dart';
import '../../domain/usecases/auth/login_with_google.dart';
import '../../domain/usecases/auth/register.dart';
import '../../domain/usecases/auth/logout.dart';
import '../../domain/usecases/auth/verify_biometric.dart';

// Use cases - Report
import '../../domain/usecases/report/get_expense_report.dart';
import '../../domain/usecases/report/get_income_report.dart';
import '../../domain/usecases/report/get_category_analysis.dart';
import '../../domain/usecases/report/calculate_balance.dart';

// Use cases - Sync
import '../../domain/usecases/sync/sync_to_cloud.dart';
import '../../domain/usecases/sync/sync_from_cloud.dart';

// Use cases - Validation
import '../../domain/usecases/validation/validate_transaction.dart';
import '../../domain/usecases/validation/validate_category.dart';
import '../../domain/usecases/validation/validate_budget.dart';
import '../../domain/usecases/validation/validate_auth.dart';

// Providers
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/transaction_provider.dart';
import '../../presentation/providers/category_provider.dart';
import '../../presentation/providers/budget_provider.dart';
import '../../presentation/providers/wallet_provider.dart';
import '../../presentation/providers/recurring_provider.dart';
import '../../presentation/providers/report_provider.dart';
import '../../presentation/providers/theme_provider.dart';
import '../../presentation/providers/community_wallet_provider.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ============ Providers ============
  sl.registerFactory(() => AuthProvider(
        loginWithEmail: sl(),
        loginWithGoogle: sl(),
        register: sl(),
        logout: sl(),
        verifyBiometric: sl(),
        validateAuth: sl(),
      ));

  sl.registerFactory(() => TransactionProvider(
        addTransaction: sl(),
        updateTransaction: sl(),
        deleteTransaction: sl(),
        getTransactions: sl(),
        getTransactionById: sl(),
        validateTransaction: sl(),
      ));

  sl.registerFactory(() => CategoryProvider(
        addCategory: sl(),
        updateCategory: sl(),
        deleteCategory: sl(),
        getCategories: sl(),
        initializeDefaultCategories: sl(),
        validateCategory: sl(),
        syncFromCloud: sl(),
      ));

  sl.registerFactory(() => BudgetProvider(
        createBudget: sl(),
        updateBudget: sl(),
        deleteBudget: sl(),
        getBudgets: sl(),
        checkBudgetStatus: sl(),
        validateBudget: sl(),
      ));

  sl.registerFactory(() => WalletProvider(
        createWallet: sl(),
        updateWallet: sl(),
        deleteWallet: sl(),
        getWallets: sl(),
      ));

  sl.registerFactory(() => RecurringProvider(
        createRecurring: sl(),
        updateRecurring: sl(),
        deleteRecurring: sl(),
        processRecurringTransactions: sl(),
      ));

  sl.registerFactory(() => ReportProvider(
        getExpenseReport: sl(),
        getIncomeReport: sl(),
        getCategoryAnalysis: sl(),
        calculateBalance: sl(),
      ));

  sl.registerFactory(() => ThemeProvider(sharedPreferences: sl()));

  sl.registerFactory(() => CommunityWalletProvider(sl()));

  // ============ Use Cases - Transaction ============
  sl.registerLazySingleton(() => AddTransaction(sl()));
  sl.registerLazySingleton(() => UpdateTransaction(sl()));
  sl.registerLazySingleton(() => DeleteTransaction(sl()));
  sl.registerLazySingleton(() => GetTransactions(sl()));
  sl.registerLazySingleton(() => GetTransactionById(sl()));

  // ============ Use Cases - Category ============
  sl.registerLazySingleton(() => AddCategory(sl()));
  sl.registerLazySingleton(() => UpdateCategory(sl()));
  sl.registerLazySingleton(() => DeleteCategory(sl()));
  sl.registerLazySingleton(() => GetCategories(sl()));
  sl.registerLazySingleton(() => InitializeDefaultCategories(
        repository: sl(),
        uuid: sl(),
      ));

  // ============ Use Cases - Budget ============
  sl.registerLazySingleton(() => CreateBudget(sl()));
  sl.registerLazySingleton(() => UpdateBudget(sl()));
  sl.registerLazySingleton(() => DeleteBudget(sl()));
  sl.registerLazySingleton(() => GetBudgets(sl()));
  sl.registerLazySingleton(() => CheckBudgetStatus(sl()));

  // ============ Use Cases - Wallet ============
  sl.registerLazySingleton(() => CreateWallet(sl()));
  sl.registerLazySingleton(() => UpdateWallet(sl()));
  sl.registerLazySingleton(() => DeleteWallet(sl()));
  sl.registerLazySingleton(() => GetWallets(sl()));

  // ============ Use Cases - Recurring ============
  sl.registerLazySingleton(() => CreateRecurring(sl()));
  sl.registerLazySingleton(() => UpdateRecurring(sl()));
  sl.registerLazySingleton(() => DeleteRecurring(sl()));
  sl.registerLazySingleton(() => ProcessRecurringTransactions(
        recurringRepository: sl(),
        transactionRepository: sl(),
        uuid: sl(),
      ));

  // ============ Use Cases - Auth ============
  sl.registerLazySingleton(() => LoginWithEmail(sl()));
  sl.registerLazySingleton(() => LoginWithGoogle(sl()));
  sl.registerLazySingleton(() => Register(sl()));
  sl.registerLazySingleton(() => Logout(sl()));
  sl.registerLazySingleton(() => VerifyBiometric(sl()));

  // ============ Use Cases - Report ============
  sl.registerLazySingleton(() => GetExpenseReport(sl()));
  sl.registerLazySingleton(() => GetIncomeReport(sl()));
  sl.registerLazySingleton(() => GetCategoryAnalysis(
        transactionRepository: sl(),
        categoryRepository: sl(),
      ));
  sl.registerLazySingleton(() => CalculateBalance(sl()));

  // ============ Use Cases - Sync ============
  sl.registerLazySingleton(() => SyncToCloud(sl()));
  sl.registerLazySingleton(() => SyncFromCloud(sl()));

  // ============ Use Cases - Validation ============
  sl.registerLazySingleton(() => ValidateTransaction());
  sl.registerLazySingleton(() => ValidateCategory(sl()));
  sl.registerLazySingleton(() => ValidateBudget(sl()));
  sl.registerLazySingleton(() => ValidateAuth());

  // ============ Repositories ============
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<BudgetRepository>(
    () => BudgetRepositoryImpl(localDataSource: sl()),
  );

  sl.registerLazySingleton<WalletRepository>(
    () => WalletRepositoryImpl(localDataSource: sl()),
  );

  sl.registerLazySingleton<RecurringRepository>(
    () => RecurringRepositoryImpl(localDataSource: sl()),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      firebaseAuthDataSource: sl(),
      firestoreDataSource: sl(),
      secureStorage: sl(),
      localAuth: sl(),
    ),
  );

  sl.registerLazySingleton<SyncRepository>(
    () => SyncRepositoryImpl(
      firestoreDataSource: sl(),
      transactionLocalDataSource: sl(),
      categoryLocalDataSource: sl(),
      budgetLocalDataSource: sl(),
      sharedPreferences: sl(),
    ),
  );

  sl.registerLazySingleton<CommunityWalletRepository>(
    () => CommunityWalletRepositoryImpl(sl()),
  );

  // ============ Data Sources - Local ============
  sl.registerLazySingleton(() => TransactionLocalDataSource(sl()));
  sl.registerLazySingleton(() => CategoryLocalDataSource(sl()));
  sl.registerLazySingleton(() => BudgetLocalDataSource(sl()));
  sl.registerLazySingleton(() => WalletLocalDataSourceImpl(databaseHelper: sl()));
  sl.registerLazySingleton(() => RecurringLocalDataSourceImpl(databaseHelper: sl()));

  // ============ Data Sources - Remote ============
  sl.registerLazySingleton<FirebaseAuthDataSource>(
    () => FirebaseAuthDataSourceImpl(
      firebaseAuth: sl(),
      googleSignIn: sl(),
    ),
  );

  sl.registerLazySingleton<FirestoreDataSource>(
    () => FirestoreDataSourceImpl(firestore: sl()),
  );

  sl.registerLazySingleton<FirebaseStorageDataSource>(
    () => FirebaseStorageDataSourceImpl(storage: sl()),
  );

  // ============ Core ============
  sl.registerLazySingleton(() => DatabaseHelper.instance);

  // ============ External ============
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  sl.registerLazySingleton(() => GoogleSignIn());
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  sl.registerLazySingleton(() => LocalAuthentication());
  sl.registerLazySingleton(() => const Uuid());
}
