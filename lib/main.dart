import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'core/di/injection_container.dart' as di;
import 'core/utils/notification_helper.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/transaction_provider.dart';
import 'presentation/providers/category_provider.dart';
import 'presentation/providers/budget_provider.dart';
import 'presentation/providers/wallet_provider.dart';
import 'presentation/providers/recurring_provider.dart';
import 'presentation/providers/report_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/ai_provider.dart';
import 'presentation/providers/ai_settings_provider.dart';
import 'presentation/providers/backup_provider.dart';
import 'presentation/providers/community_wallet_provider.dart';
import 'presentation/providers/firestore_community_provider.dart';
import 'presentation/providers/notification_provider.dart';
import 'presentation/providers/firestore_notification_provider.dart';
import 'presentation/providers/community_transaction_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase (check if already initialized)
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      if (e.toString().contains('duplicate-app')) {
        // Firebase already initialized, continue
        debugPrint('Firebase already initialized');
      } else {
        // Other Firebase initialization error
        rethrow;
      }
    }

    // Initialize timezone
    tz.initializeTimeZones();
    
    // Set local timezone to Vietnam
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    // Initialize date formatting for Vietnamese locale
    await initializeDateFormatting('vi');

    // Initialize notifications
    await NotificationHelper.instance.initialize();

    // Initialize dependency injection
    await di.init();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => di.sl<AuthProvider>()),
          ChangeNotifierProvider(create: (_) => di.sl<TransactionProvider>()),
          ChangeNotifierProvider(create: (_) => di.sl<CategoryProvider>()),
          ChangeNotifierProvider(create: (_) => di.sl<BudgetProvider>()),
          ChangeNotifierProvider(create: (_) => di.sl<WalletProvider>()),
          ChangeNotifierProvider(create: (_) => di.sl<RecurringProvider>()),
          ChangeNotifierProvider(create: (_) => di.sl<ReportProvider>()),
          ChangeNotifierProvider(create: (_) => di.sl<ThemeProvider>()),
          ChangeNotifierProvider(create: (_) => AISettingsProvider()),
          ChangeNotifierProvider(create: (_) => BackupProvider()),
          ChangeNotifierProvider(
              create: (_) => di.sl<CommunityWalletProvider>()),
          ChangeNotifierProvider(create: (_) => FirestoreCommunityProvider()),
          ChangeNotifierProvider(create: (_) => CommunityTransactionProvider()),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
          ChangeNotifierProvider(
              create: (_) => FirestoreNotificationProvider()),
          // AI Provider - depends on multiple providers for comprehensive analysis
          ChangeNotifierProxyProvider6<TransactionProvider, CommunityTransactionProvider, FirestoreCommunityProvider, AuthProvider, CategoryProvider, AISettingsProvider, AIProvider>(
            create: (context) => AIProvider(
              transactionProvider: context.read<TransactionProvider>(),
              communityTransactionProvider: context.read<CommunityTransactionProvider>(),
              communityProvider: context.read<FirestoreCommunityProvider>(),
              authProvider: context.read<AuthProvider>(),
              categoryProvider: context.read<CategoryProvider>(),
              aiSettingsProvider: context.read<AISettingsProvider>(),
            ),
            update: (context, transactionProvider, communityTransactionProvider, communityProvider, authProvider, categoryProvider, aiSettingsProvider, previous) =>
                previous ??
                AIProvider(
                  transactionProvider: transactionProvider,
                  communityTransactionProvider: communityTransactionProvider,
                  communityProvider: communityProvider,
                  authProvider: authProvider,
                  categoryProvider: categoryProvider,
                  aiSettingsProvider: aiSettingsProvider,
                ),
          ),
        ],
        child: const MoneyManagerApp(),
      ),
    );
  } catch (e) {
    debugPrint('Error initializing app: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Lỗi khởi tạo ứng dụng'),
                const SizedBox(height: 8),
                Text('$e', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
