import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/routes/route_names.dart';
import '../../providers/transaction_provider.dart';

class MonthlyBudgetCard extends StatefulWidget {
  const MonthlyBudgetCard({super.key});

  @override
  State<MonthlyBudgetCard> createState() => _MonthlyBudgetCardState();
}

class _MonthlyBudgetCardState extends State<MonthlyBudgetCard> {
  double? _monthlyBudget;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  Future<void> _loadBudget() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final key = 'monthly_budget_${now.month}_${now.year}';
    final budget = prefs.getDouble(key);

    if (mounted) {
      setState(() {
        _monthlyBudget = budget;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_monthlyBudget == null) {
      return Card(
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(context, RouteNames.monthlyBudget)
                .then((_) => _loadBudget());
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đặt ngân sách tháng',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Quản lý chi tiêu hiệu quả hơn',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      );
    }

    return Consumer<TransactionProvider>(
      builder: (context, provider, child) {
        final now = DateTime.now();
        final monthlyExpense = provider.transactions
            .where((t) =>
                t.type == 'expense' &&
                t.date.month == now.month &&
                t.date.year == now.year)
            .fold(0.0, (sum, t) => sum + t.amount);

        final percentage = (monthlyExpense / _monthlyBudget!) * 100;
        final remaining = _monthlyBudget! - monthlyExpense;

        return Card(
          color: percentage >= 100
              ? AppColors.error.withValues(alpha: 0.05)
              : null,
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(context, RouteNames.monthlyBudget)
                  .then((_) => _loadBudget());
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ngân sách tháng này',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: percentage >= 100
                              ? AppColors.error
                              : percentage >= 80
                                  ? AppColors.warning
                                  : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: percentage > 100 ? 1.0 : percentage / 100,
                    backgroundColor: AppColors.grey300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percentage >= 100
                          ? AppColors.error
                          : percentage >= 80
                              ? AppColors.warning
                              : AppColors.success,
                    ),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Đã chi',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(monthlyExpense),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            remaining >= 0 ? 'Còn lại' : 'Vượt',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(remaining.abs()),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: remaining >= 0
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (percentage >= 100)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber,
                              color: AppColors.error,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Bạn đã vượt ngân sách tháng này!',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
