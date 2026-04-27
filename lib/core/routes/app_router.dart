import 'package:flutter/material.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/lock_screen.dart';
import '../../presentation/screens/main_navigation_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/transaction/add_transaction_screen.dart';
import '../../presentation/screens/transaction/transaction_list_screen.dart';
import '../../presentation/screens/category/category_list_screen.dart';
import '../../presentation/screens/category/add_category_screen.dart';
import '../../presentation/screens/budget/monthly_budget_screen.dart';
import '../../presentation/screens/report/report_screen.dart';
import '../../presentation/screens/profile/settings_screen.dart';
import '../../presentation/screens/profile/change_password_screen.dart';
import '../../presentation/screens/profile/pin_setup_screen.dart';
import '../../presentation/screens/profile/biometric_setup_screen.dart';
import '../../presentation/screens/profile/notification_settings_screen.dart';
import '../../presentation/screens/ai/ai_insights_screen.dart';
import '../../presentation/screens/ai/ai_settings_screen.dart';
import '../../presentation/screens/community/community_wallets_screen.dart';
import '../../presentation/screens/community/create_community_wallet_screen.dart';
import '../../presentation/screens/community/community_wallet_detail_screen.dart';
import '../../presentation/screens/community/invite_member_screen.dart';
import '../../presentation/screens/community/member_detail_screen.dart';
import '../../presentation/screens/notifications/notifications_screen.dart';
import '../../presentation/screens/transaction/transaction_detail_screen.dart';
import '../../presentation/screens/profile/unique_identifier_setup_screen.dart';

import 'route_names.dart';

class AppRouter {
  static const String splash = RouteNames.splash;
  static const String login = RouteNames.login;
  static const String register = RouteNames.register;
  static const String home = RouteNames.home;
  static const String addTransaction = RouteNames.addTransaction;
  static const String transactionList = RouteNames.transactionList;
  static const String transactionDetail = RouteNames.transactionDetail;
  static const String report = RouteNames.report;
  static const String settings = RouteNames.settings;

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case RouteNames.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case RouteNames.lock:
        return MaterialPageRoute(builder: (_) => const LockScreen());

      case RouteNames.home:
        return MaterialPageRoute(builder: (_) => const MainNavigationScreen());

      case RouteNames.addTransaction:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => AddTransactionScreen(
            initialType: args?['type'],
          ),
        );

      case RouteNames.transactionList:
        return MaterialPageRoute(
          builder: (_) => const TransactionListScreen(),
        );

      case RouteNames.transactionDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Missing transaction information')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => TransactionDetailScreen(
            personalTransaction: args['personalTransaction'],
            communityTransaction: args['communityTransaction'],
            walletName: args['walletName'],
          ),
        );

      case RouteNames.categoryList:
        return MaterialPageRoute(
          builder: (_) => const CategoryListScreen(),
        );

      case RouteNames.addCategory:
        final categoryType = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => AddCategoryScreen(categoryType: categoryType),
        );

      case RouteNames.monthlyBudget:
        return MaterialPageRoute(builder: (_) => const MonthlyBudgetScreen());

      case RouteNames.report:
        return MaterialPageRoute(builder: (_) => const ReportScreen());

      case RouteNames.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      case RouteNames.changePassword:
        return MaterialPageRoute(builder: (_) => const ChangePasswordScreen());

      case RouteNames.pinSetup:
        return MaterialPageRoute(builder: (_) => const PinSetupScreen());

      case RouteNames.biometricSetup:
        return MaterialPageRoute(builder: (_) => const BiometricSetupScreen());

      case RouteNames.notificationSettings:
        return MaterialPageRoute(
            builder: (_) => const NotificationSettingsScreen());

      case RouteNames.aiInsights:
        return MaterialPageRoute(builder: (_) => const AIInsightsScreen());

      case RouteNames.aiSettings:
        return MaterialPageRoute(builder: (_) => const AISettingsScreen());

      case RouteNames.communityWallets:
        return MaterialPageRoute(
            builder: (_) => const CommunityWalletsScreen());

      case RouteNames.createCommunityWallet:
        return MaterialPageRoute(
            builder: (_) => const CreateCommunityWalletScreen());

      case RouteNames.communityWalletDetail:
        final walletId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => CommunityWalletDetailScreen(walletId: walletId),
        );

      case RouteNames.inviteMember:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Missing wallet information')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => InviteMemberScreen(
            walletId: args['walletId'] as String,
            walletName: args['walletName'] as String,
          ),
        );

      case RouteNames.memberDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Missing member information')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => MemberDetailScreen(
            memberId: args['memberId'] as String,
            walletId: args['walletId'] as String,
          ),
        );

      case '/notifications':
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());

      case '/enhanced-home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case RouteNames.uniqueIdentifierSetup:
        return MaterialPageRoute(
            builder: (_) => const UniqueIdentifierSetupScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
