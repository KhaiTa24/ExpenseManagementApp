import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/entities/community_transaction.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/community_transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';

class TransactionDetailScreen extends StatelessWidget {
  final Transaction? personalTransaction;
  final CommunityTransaction? communityTransaction;
  final String? walletName;

  const TransactionDetailScreen({
    super.key,
    this.personalTransaction,
    this.communityTransaction,
    this.walletName,
  });

  bool get isPersonalTransaction => personalTransaction != null;
  bool get isCommunityTransaction => communityTransaction != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isPersonalTransaction
            ? 'Chi tiết giao dịch'
            : 'Chi tiết giao dịch cộng đồng'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTransactionCard(context),
            const SizedBox(height: 20),
            _buildDetailsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context) {
    final amount = isPersonalTransaction
        ? personalTransaction!.amount
        : communityTransaction!.amount;
    final isIncome = isPersonalTransaction
        ? personalTransaction!.type == 'income'
        : communityTransaction!.isIncome;
    final description = isPersonalTransaction
        ? personalTransaction!.description
        : communityTransaction!.description;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(
              isIncome ? Icons.trending_up : Icons.trending_down,
              size: 48,
              color: isIncome ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 12),
            Text(
              CurrencyFormatter.format(amount),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: isIncome ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isIncome ? 'Thu nhập' : 'Chi tiêu',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            if (description?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                description ?? '',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thông tin chi tiết',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              'Ngày giao dịch',
              DateFormatter.formatDate(isPersonalTransaction
                  ? personalTransaction!.date
                  : communityTransaction!.date),
              Icons.calendar_today,
            ),
            const Divider(),
            _buildDetailRow(
              context,
              'Danh mục',
              _getCategoryName(context),
              Icons.category,
            ),
            const Divider(),
            _buildDetailRow(
              context,
              'Loại giao dịch',
              isPersonalTransaction
                  ? (personalTransaction!.type == 'income'
                      ? 'Thu nhập'
                      : 'Chi tiêu')
                  : (communityTransaction!.isIncome ? 'Thu nhập' : 'Chi tiêu'),
              isPersonalTransaction
                  ? (personalTransaction!.type == 'income'
                      ? Icons.add_circle
                      : Icons.remove_circle)
                  : (communityTransaction!.isIncome
                      ? Icons.add_circle
                      : Icons.remove_circle),
            ),
            const Divider(),
            _buildDetailRow(
              context,
              'Nguồn',
              isPersonalTransaction ? 'Cá nhân' : 'Cộng đồng',
              isPersonalTransaction ? Icons.person : Icons.group,
            ),
            if (isCommunityTransaction) ...[
              const Divider(),
              _buildDetailRow(
                context,
                'Ví cộng đồng',
                walletName ?? 'Không xác định',
                Icons.account_balance_wallet,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(BuildContext context) {
    if (isPersonalTransaction) {
      final categoryProvider =
          Provider.of<CategoryProvider>(context, listen: false);
      final category = categoryProvider.categories
          .where((c) => c.id == personalTransaction!.categoryId)
          .firstOrNull;
      return category?.name ?? 'Không xác định';
    } else {
      return communityTransaction!.categoryName;
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text(isPersonalTransaction
              ? 'Bạn có chắc chắn muốn xóa giao dịch này không?'
              : 'Bạn có chắc chắn muốn xóa giao dịch cộng đồng này không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteTransaction(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );
  }

  void _deleteTransaction(BuildContext context) async {
    try {
      if (isPersonalTransaction) {
        await _deletePersonalTransaction(context);
      } else {
        await _deleteCommunityTransaction(context);
      }

      // Success
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa giao dịch thành công'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop(); // Go back to previous screen
      }
    } catch (e) {
      // Error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa giao dịch: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _deletePersonalTransaction(BuildContext context) async {
    final transactionProvider =
        Provider.of<TransactionProvider>(context, listen: false);
    await transactionProvider.deleteTransaction(personalTransaction!.id);
  }

  Future<void> _deleteCommunityTransaction(BuildContext context) async {
    final communityTransactionProvider =
        Provider.of<CommunityTransactionProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check if user is the owner of the transaction
    if (communityTransaction!.userId != authProvider.currentUser?.id) {
      throw Exception('Bạn chỉ có thể xóa giao dịch do mình tạo');
    }

    await communityTransactionProvider.deleteTransaction(
      communityTransaction!.communityWalletId,
      communityTransaction!.id,
    );
  }
}
