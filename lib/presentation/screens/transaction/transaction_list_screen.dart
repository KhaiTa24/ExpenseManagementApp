import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/routes/route_names.dart';
import '../../../domain/entities/transaction_filter.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/entities/community_transaction.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/community_transaction_provider.dart';
import '../../providers/firestore_community_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/common/empty_state_widget.dart';
import '../../widgets/common/loading_indicator.dart';
import 'transaction_filter_screen.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  String? _filterType;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;

    if (userId != null) {
      // Load categories first, then transactions
      await context.read<CategoryProvider>().loadCategories(userId: userId);
      await context.read<TransactionProvider>().loadTransactions(
            userId: userId,
            type: _filterType,
          );
      
      // Load community wallets and transactions
      final communityProvider = context.read<FirestoreCommunityProvider>();
      final communityTransactionProvider = context.read<CommunityTransactionProvider>();
      
      // Start listening to user's community wallets
      communityProvider.startListeningToUserWallets(userId);
      
      // Load transactions for all community wallets (only user's transactions)
      for (final wallet in communityProvider.userWallets) {
        communityTransactionProvider.startListeningToWalletTransactions(wallet.id);
      }
    }
  }

  Future<void> _showFilterScreen() async {
    final transactionProvider = context.read<TransactionProvider>();
    
    final result = await Navigator.push<TransactionFilter>(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionFilterScreen(
          currentFilter: transactionProvider.currentFilter,
        ),
      ),
    );

    if (result != null && mounted) {
      context.read<TransactionProvider>().setFilter(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giao dịch'),
        actions: [
          Consumer<TransactionProvider>(
            builder: (context, provider, child) {
              final hasFilter = provider.currentFilter?.hasFilter ?? false;
              
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () => _showFilterScreen(),
                  ),
                  if (hasFilter)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
        child: Consumer4<TransactionProvider, CategoryProvider, CommunityTransactionProvider, FirestoreCommunityProvider>(
          builder: (context, transactionProvider, categoryProvider, communityTransactionProvider, communityProvider, child) {
            if (transactionProvider.state == TransactionLoadingState.loading) {
              return const LoadingIndicator();
            }

            final currentUserId = context.read<AuthProvider>().currentUser?.id;
            final filter = transactionProvider.currentFilter;
            final personalTransactions = transactionProvider.transactions;
            
            // Get community transactions created by current user
            final userCommunityTransactions = <CommunityTransaction>[];
            for (final wallet in communityProvider.userWallets) {
              final walletTransactions = communityTransactionProvider.getTransactionsForWallet(wallet.id);
              // Only add transactions created by current user
              userCommunityTransactions.addAll(
                walletTransactions.where((t) => t.userId == currentUserId)
              );
            }
            
            // Combine all transactions based on source filter
            final allTransactions = <Map<String, dynamic>>[];
            
            // Add personal transactions if not filtered out
            if (filter?.source == null || filter?.source == 'personal') {
              for (final transaction in personalTransactions) {
                allTransactions.add({
                  'type': 'personal',
                  'transaction': transaction,
                  'date': transaction.date,
                });
              }
            }
            
            // Add community transactions if not filtered out
            if (filter?.source == null || filter?.source == 'community') {
              for (final transaction in userCommunityTransactions) {
                // Apply type filter if set
                if (filter?.type != null) {
                  if ((filter!.type == 'income' && !transaction.isIncome) ||
                      (filter.type == 'expense' && !transaction.isExpense)) {
                    continue;
                  }
                }
                
                // Apply date filter if set
                if (filter?.startDate != null && transaction.date.isBefore(filter!.startDate!)) {
                  continue;
                }
                
                if (filter?.endDate != null && transaction.date.isAfter(filter!.endDate!)) {
                  continue;
                }
                
                allTransactions.add({
                  'type': 'community',
                  'transaction': transaction,
                  'date': transaction.date,
                  'wallet': communityProvider.userWallets
                      .where((w) => w.id == transaction.communityWalletId)
                      .firstOrNull,
                });
              }
            }
            
            // Sort all transactions by date (newest first)
            allTransactions.sort((a, b) => b['date'].compareTo(a['date']));

            if (allTransactions.isEmpty) {
              return const EmptyStateWidget(
                icon: Icons.receipt_long_outlined,
                title: 'Chưa có giao dịch',
                message: 'Bắt đầu thêm giao dịch đầu tiên của bạn',
              );
            }

            // Group transactions by date
            final groupedTransactions = <String, List<Map<String, dynamic>>>{};
            for (var item in allTransactions) {
              final dateKey = DateFormatter.formatDate(item['date']);
              groupedTransactions.putIfAbsent(dateKey, () => []);
              groupedTransactions[dateKey]!.add(item);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupedTransactions.length,
              itemBuilder: (context, index) {
                final dateKey = groupedTransactions.keys.elementAt(index);
                final dayTransactions = groupedTransactions[dateKey]!;

                // Calculate day total
                double dayTotal = 0;
                for (var item in dayTransactions) {
                  final isPersonal = item['type'] == 'personal';
                  if (isPersonal) {
                    final transaction = item['transaction'] as Transaction;
                    dayTotal += transaction.isIncome ? transaction.amount : -transaction.amount;
                  } else {
                    final transaction = item['transaction'] as CommunityTransaction;
                    dayTotal += transaction.isIncome ? transaction.amount : -transaction.amount;
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date header
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateKey,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(dayTotal.abs()),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: dayTotal >= 0
                                  ? AppColors.income
                                  : AppColors.expense,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Transactions for this day
                    ...dayTransactions.map((item) {
                      final isPersonal = item['type'] == 'personal';
                      
                      if (isPersonal) {
                        return _buildPersonalTransactionCard(
                          item['transaction'] as Transaction,
                          categoryProvider,
                        );
                      } else {
                        return _buildCommunityTransactionCard(
                          item['transaction'] as CommunityTransaction,
                          item['wallet'],
                        );
                      }
                    }),

                    const SizedBox(height: 16),
                  ],
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'transaction_fab',
        onPressed: () {
          Navigator.pushNamed(context, RouteNames.addTransaction);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPersonalTransactionCard(Transaction transaction, CategoryProvider categoryProvider) {
    final category = categoryProvider.getCategoryById(transaction.categoryId);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: transaction.isIncome
                ? AppColors.income.withValues(alpha: 0.1)
                : AppColors.expense.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              category?.icon ?? '📌',
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                category?.name ?? 'Khác',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Cá nhân',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        subtitle: transaction.description != null
            ? Text(
                transaction.description!,
                style: AppTextStyles.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
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
          Navigator.pushNamed(
            context,
            RouteNames.transactionDetail,
            arguments: {
              'personalTransaction': transaction,
              'communityTransaction': null,
              'walletName': null,
            },
          );
        },
      ),
    );
  }

  Widget _buildCommunityTransactionCard(CommunityTransaction transaction, wallet) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: transaction.isIncome
                ? AppColors.income.withValues(alpha: 0.1)
                : AppColors.expense.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              transaction.categoryIcon,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                transaction.categoryName,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Cộng đồng',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.orange[700],
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (wallet != null)
              Row(
                children: [
                  Text(
                    wallet.icon ?? '👥',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    wallet.name,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            if (transaction.description.isNotEmpty)
              Text(
                transaction.description,
                style: AppTextStyles.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
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
          Navigator.pushNamed(
            context,
            RouteNames.transactionDetail,
            arguments: {
              'personalTransaction': null,
              'communityTransaction': transaction,
              'walletName': wallet?.name,
            },
          );
        },
      ),
    );
  }
}
