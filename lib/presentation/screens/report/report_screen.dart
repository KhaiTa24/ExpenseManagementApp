import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/community_transaction_provider.dart';
import '../../providers/firestore_community_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/charts/category_pie_chart.dart';
import '../../widgets/charts/daily_bar_chart.dart';
import '../../widgets/charts/monthly_line_chart.dart';
import '../../widgets/report/top_categories_widget.dart';
import '../../../domain/entities/community_transaction.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo & Thống kê'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tổng quan'),
            Tab(text: 'Biểu đồ'),
            Tab(text: 'Thống kê'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildChartsTab(),
          _buildStatisticsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer5<TransactionProvider, CategoryProvider, CommunityTransactionProvider, FirestoreCommunityProvider, AuthProvider>(
      builder: (context, transactionProvider, categoryProvider, communityTransactionProvider, communityProvider, authProvider, child) {
        final personalTransactions = transactionProvider.transactions;
        final userId = authProvider.currentUser?.id;
        final now = DateTime.now();

        // Get community transactions created by current user
        final userCommunityTransactions = <CommunityTransaction>[];
        if (userId != null) {
          for (final wallet in communityProvider.userWallets) {
            final walletTransactions = communityTransactionProvider.getTransactionsForWallet(wallet.id);
            userCommunityTransactions.addAll(
              walletTransactions.where((t) => t.userId == userId)
            );
          }
        }

        // Combine all transactions
        // final allTransactions = [...personalTransactions];

        // Calculate monthly totals from both sources
        final monthlyIncome = personalTransactions
            .where((t) =>
                t.type == 'income' &&
                t.date.month == now.month &&
                t.date.year == now.year)
            .fold(0.0, (sum, t) => sum + t.amount) +
            userCommunityTransactions
            .where((t) =>
                t.isIncome &&
                t.date.month == now.month &&
                t.date.year == now.year)
            .fold(0.0, (sum, t) => sum + t.amount);

        final monthlyExpense = personalTransactions
            .where((t) =>
                t.type == 'expense' &&
                t.date.month == now.month &&
                t.date.year == now.year)
            .fold(0.0, (sum, t) => sum + t.amount) +
            userCommunityTransactions
            .where((t) =>
                t.isExpense &&
                t.date.month == now.month &&
                t.date.year == now.year)
            .fold(0.0, (sum, t) => sum + t.amount);

        // Category data for pie chart (combine personal and community)
        final categoryData = <String, CategoryChartData>{};
        
        // Personal transactions
        for (var transaction in personalTransactions) {
          if (transaction.type == 'expense' &&
              transaction.date.month == now.month &&
              transaction.date.year == now.year) {
            final category =
                categoryProvider.getCategoryById(transaction.categoryId);
            if (category != null) {
              final key = '${category.name} (Cá nhân)';
              if (categoryData.containsKey(key)) {
                categoryData[key] = CategoryChartData(
                  amount: categoryData[key]!.amount + transaction.amount,
                  icon: category.icon,
                  transactionCount:
                      categoryData[key]!.transactionCount + 1,
                );
              } else {
                categoryData[key] = CategoryChartData(
                  amount: transaction.amount,
                  icon: category.icon,
                  transactionCount: 1,
                );
              }
            }
          }
        }

        // Community transactions
        for (var transaction in userCommunityTransactions) {
          if (transaction.isExpense &&
              transaction.date.month == now.month &&
              transaction.date.year == now.year) {
            final key = '${transaction.categoryName} (Cộng đồng)';
            if (categoryData.containsKey(key)) {
              categoryData[key] = CategoryChartData(
                amount: categoryData[key]!.amount + transaction.amount,
                icon: transaction.categoryIcon,
                transactionCount: categoryData[key]!.transactionCount + 1,
              );
            } else {
              categoryData[key] = CategoryChartData(
                amount: transaction.amount,
                icon: transaction.categoryIcon,
                transactionCount: 1,
              );
            }
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month summary card
              _buildMonthSummaryCard(monthlyIncome, monthlyExpense),

              const SizedBox(height: 24),

              // Transaction source summary
              _buildTransactionSourceSummary(personalTransactions, userCommunityTransactions, now),

              const SizedBox(height: 24),

              // Category pie chart
              const Text(
                'Chi tiêu theo danh mục',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              CategoryPieChart(categoryData: categoryData),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChartsTab() {
    return Consumer5<TransactionProvider, CategoryProvider, CommunityTransactionProvider, FirestoreCommunityProvider, AuthProvider>(
      builder: (context, transactionProvider, categoryProvider, communityTransactionProvider, communityProvider, authProvider, child) {
        final personalTransactions = transactionProvider.transactions;
        final userId = authProvider.currentUser?.id;

        // Get community transactions created by current user
        final userCommunityTransactions = <CommunityTransaction>[];
        if (userId != null) {
          for (final wallet in communityProvider.userWallets) {
            final walletTransactions = communityTransactionProvider.getTransactionsForWallet(wallet.id);
            userCommunityTransactions.addAll(
              walletTransactions.where((t) => t.userId == userId)
            );
          }
        }

        // Daily data for last 7 days (combine personal and community)
        final dailyExpense = <DateTime, double>{};
        final now = DateTime.now();
        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final dateKey = DateTime(date.year, date.month, date.day);
          
          // Personal transactions
          final personalDaily = personalTransactions
              .where((t) =>
                  t.type == 'expense' &&
                  t.date.year == date.year &&
                  t.date.month == date.month &&
                  t.date.day == date.day)
              .fold(0.0, (sum, t) => sum + t.amount);

          // Community transactions
          final communityDaily = userCommunityTransactions
              .where((t) =>
                  t.isExpense &&
                  t.date.year == date.year &&
                  t.date.month == date.month &&
                  t.date.day == date.day)
              .fold(0.0, (sum, t) => sum + t.amount);

          dailyExpense[dateKey] = personalDaily + communityDaily;
        }

        // Monthly data for last 6 months (combine personal and community)
        final monthlyExpense = <int, double>{};
        final monthlyIncome = <int, double>{};
        for (int i = 5; i >= 0; i--) {
          final month = now.month - i;
          final year = now.year + (month <= 0 ? -1 : 0);
          final adjustedMonth = month <= 0 ? month + 12 : month;

          // Personal transactions
          final personalExpense = personalTransactions
              .where((t) =>
                  t.type == 'expense' &&
                  t.date.month == adjustedMonth &&
                  t.date.year == year)
              .fold(0.0, (sum, t) => sum + t.amount);

          final personalIncome = personalTransactions
              .where((t) =>
                  t.type == 'income' &&
                  t.date.month == adjustedMonth &&
                  t.date.year == year)
              .fold(0.0, (sum, t) => sum + t.amount);

          // Community transactions
          final communityExpense = userCommunityTransactions
              .where((t) =>
                  t.isExpense &&
                  t.date.month == adjustedMonth &&
                  t.date.year == year)
              .fold(0.0, (sum, t) => sum + t.amount);

          final communityIncome = userCommunityTransactions
              .where((t) =>
                  t.isIncome &&
                  t.date.month == adjustedMonth &&
                  t.date.year == year)
              .fold(0.0, (sum, t) => sum + t.amount);

          monthlyExpense[adjustedMonth] = personalExpense + communityExpense;
          monthlyIncome[adjustedMonth] = personalIncome + communityIncome;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Daily bar chart
              const Text(
                'Chi tiêu 7 ngày qua',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              DailyBarChart(dailyData: dailyExpense),

              const SizedBox(height: 32),

              // Monthly line chart
              const Text(
                'Xu hướng thu chi 6 tháng',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              MonthlyLineChart(
                monthlyExpense: monthlyExpense,
                monthlyIncome: monthlyIncome,
              ),

              const SizedBox(height: 16),

              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem('Chi tiêu', AppColors.expense),
                  const SizedBox(width: 24),
                  _buildLegendItem('Thu nhập', AppColors.income),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatisticsTab() {
    return Consumer5<TransactionProvider, CategoryProvider, CommunityTransactionProvider, FirestoreCommunityProvider, AuthProvider>(
      builder: (context, transactionProvider, categoryProvider, communityTransactionProvider, communityProvider, authProvider, child) {
        final personalTransactions = transactionProvider.transactions;
        final userId = authProvider.currentUser?.id;
        final now = DateTime.now();

        // Get community transactions created by current user
        final userCommunityTransactions = <CommunityTransaction>[];
        if (userId != null) {
          for (final wallet in communityProvider.userWallets) {
            final walletTransactions = communityTransactionProvider.getTransactionsForWallet(wallet.id);
            userCommunityTransactions.addAll(
              walletTransactions.where((t) => t.userId == userId)
            );
          }
        }

        // Calculate top categories (combine personal and community)
        final categoryStats = <String, CategorySpending>{};
        
        // Personal transactions
        for (var transaction in personalTransactions) {
          if (transaction.type == 'expense' &&
              transaction.date.month == now.month &&
              transaction.date.year == now.year) {
            final category =
                categoryProvider.getCategoryById(transaction.categoryId);
            if (category != null) {
              final key = '${category.name} (Cá nhân)';
              if (categoryStats.containsKey(key)) {
                categoryStats[key] = CategorySpending(
                  name: key,
                  icon: category.icon,
                  totalAmount: categoryStats[key]!.totalAmount +
                      transaction.amount,
                  transactionCount:
                      categoryStats[key]!.transactionCount + 1,
                );
              } else {
                categoryStats[key] = CategorySpending(
                  name: key,
                  icon: category.icon,
                  totalAmount: transaction.amount,
                  transactionCount: 1,
                );
              }
            }
          }
        }

        // Community transactions
        for (var transaction in userCommunityTransactions) {
          if (transaction.isExpense &&
              transaction.date.month == now.month &&
              transaction.date.year == now.year) {
            final key = '${transaction.categoryName} (Cộng đồng)';
            if (categoryStats.containsKey(key)) {
              categoryStats[key] = CategorySpending(
                name: key,
                icon: transaction.categoryIcon,
                totalAmount: categoryStats[key]!.totalAmount + transaction.amount,
                transactionCount: categoryStats[key]!.transactionCount + 1,
              );
            } else {
              categoryStats[key] = CategorySpending(
                name: key,
                icon: transaction.categoryIcon,
                totalAmount: transaction.amount,
                transactionCount: 1,
              );
            }
          }
        }

        final topCategories = categoryStats.values.toList()
          ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

        final topCategoriesList = topCategories.take(5).toList();

        // Calculate statistics (combine personal and community)
        final monthlyExpense = personalTransactions
            .where((t) =>
                t.type == 'expense' &&
                t.date.month == now.month &&
                t.date.year == now.year)
            .fold(0.0, (sum, t) => sum + t.amount) +
            userCommunityTransactions
            .where((t) =>
                t.isExpense &&
                t.date.month == now.month &&
                t.date.year == now.year)
            .fold(0.0, (sum, t) => sum + t.amount);

        final expenseCount = personalTransactions
            .where((t) =>
                t.type == 'expense' &&
                t.date.month == now.month &&
                t.date.year == now.year)
            .length +
            userCommunityTransactions
            .where((t) =>
                t.isExpense &&
                t.date.month == now.month &&
                t.date.year == now.year)
            .length;

        final avgExpense = expenseCount > 0 ? monthlyExpense / expenseCount : 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistics cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Trung bình/giao dịch',
                      CurrencyFormatter.format(avgExpense),
                      Icons.trending_up,
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Số giao dịch',
                      expenseCount.toString(),
                      Icons.receipt_long,
                      AppColors.secondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Top categories
              TopCategoriesWidget(topCategories: topCategoriesList),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthSummaryCard(double income, double expense) {
    final balance = income - expense;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            DateFormat('MMMM yyyy', 'vi').format(_selectedMonth),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem('Thu nhập', income, Icons.arrow_downward,
                    AppColors.success),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              Expanded(
                child: _buildSummaryItem(
                    'Chi tiêu', expense, Icons.arrow_upward, AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chênh lệch',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(balance),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      String label, double amount, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.format(amount),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Widget _buildTransactionSourceSummary(
    List personalTransactions,
    List<CommunityTransaction> communityTransactions,
    DateTime now,
  ) {
    // Filter by current month
    final monthlyPersonal = personalTransactions.where((t) =>
        t.date.month == now.month && t.date.year == now.year).length;

    final monthlyCommunity = communityTransactions.where((t) =>
        t.date.month == now.month && t.date.year == now.year).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nguồn giao dịch tháng này',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSourceCard(
                    'Cá nhân',
                    monthlyPersonal,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSourceCard(
                    'Cộng đồng',
                    monthlyCommunity,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$count giao dịch',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
