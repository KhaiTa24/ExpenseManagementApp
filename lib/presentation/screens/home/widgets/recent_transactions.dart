import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../providers/transaction_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../widgets/common/empty_state_widget.dart';

class RecentTransactions extends StatelessWidget {
  const RecentTransactions({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<TransactionProvider, CategoryProvider>(
      builder: (context, transactionProvider, categoryProvider, child) {
        final transactions = transactionProvider.transactions.take(10).toList();

        if (transactions.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.receipt_long_outlined,
            title: 'Chưa có giao dịch',
            message: 'Bắt đầu thêm giao dịch đầu tiên của bạn',
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            final category = categoryProvider.getCategoryById(
              transaction.categoryId,
            );

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: 8,
              ),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: transaction.isIncome
                      ? AppColors.income.withOpacity(0.1)
                      : AppColors.expense.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    category?.icon ?? '📌',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              title: Text(
                category?.name ?? 'Khác',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                DateFormatter.formatDate(transaction.date),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              trailing: Text(
                '${transaction.isIncome ? '+' : '-'}${CurrencyFormatter.format(transaction.amount)}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: transaction.isIncome
                      ? AppColors.income
                      : AppColors.expense,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                // TODO: Navigate to transaction detail
              },
            );
          },
        );
      },
    );
  }
}
