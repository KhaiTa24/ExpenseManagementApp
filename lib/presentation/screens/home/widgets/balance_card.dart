import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/routes/route_names.dart';
import '../../../providers/transaction_provider.dart';
import '../../../providers/community_transaction_provider.dart';
import '../../../providers/firestore_community_provider.dart';
import '../../../providers/ai_provider.dart';

class BalanceCard extends StatefulWidget {
  const BalanceCard({super.key});

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  bool _showCommunityBalance = false;
  String? _selectedWalletId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAIInsights();
    });
  }

  Future<void> _loadAIInsights() async {
    if (!mounted) return;
    
    final aiProvider = context.read<AIProvider>();
    
    // Only load if not already loading
    if (!aiProvider.isLoadingPrediction) {
      // Check if server is healthy before loading
      final isHealthy = await aiProvider.checkServerHealth();
      if (isHealthy && mounted) {
        await aiProvider.loadMonthlyPrediction();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showCommunityBalance = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: !_showCommunityBalance 
                          ? AppColors.textWhite.withValues(alpha: 0.3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Số dư cá nhân',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textWhite.withValues(alpha: !_showCommunityBalance ? 1.0 : 0.7),
                        fontWeight: !_showCommunityBalance ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _showCommunityBalance = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: _showCommunityBalance 
                          ? AppColors.textWhite.withValues(alpha: 0.3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Số dư cộng đồng',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textWhite.withValues(alpha: _showCommunityBalance ? 1.0 : 0.7),
                        fontWeight: _showCommunityBalance ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Balance content
          if (!_showCommunityBalance) 
            _buildPersonalBalance()
          else 
            _buildCommunityBalance(),
        ],
      ),
    );
  }

  Widget _buildPersonalBalance() {
    return Consumer2<TransactionProvider, AIProvider>(
      builder: (context, provider, aiProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              CurrencyFormatter.format(provider.balance),
              style: AppTextStyles.h1.copyWith(
                color: AppColors.textWhite,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Thu nhập',
                    provider.totalIncome,
                    Icons.arrow_downward,
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Chi tiêu',
                    provider.totalExpense,
                    Icons.arrow_upward,
                    AppColors.error,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // AI Insights section
            _buildAIInsightsSection(aiProvider),
          ],
        );
      },
    );
  }

  Widget _buildCommunityBalance() {
    return Consumer3<FirestoreCommunityProvider, CommunityTransactionProvider, AIProvider>(
      builder: (context, communityProvider, transactionProvider, aiProvider, child) {
        final wallets = communityProvider.userWallets;
        
        if (wallets.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '0đ',
                style: AppTextStyles.h1.copyWith(
                  color: AppColors.textWhite,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Chưa có ví cộng đồng',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textWhite.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 16),
              // AI Insights section even when no community wallets
              _buildAIInsightsSection(aiProvider),
            ],
          );
        }

        // Auto-select first wallet if none selected
        if (_selectedWalletId == null && wallets.isNotEmpty) {
          _selectedWalletId = wallets.first.id;
        }

        // Find selected wallet
        final selectedWallet = wallets.where((w) => w.id == _selectedWalletId).firstOrNull;
        if (selectedWallet == null && wallets.isNotEmpty) {
          _selectedWalletId = wallets.first.id;
        }

        final walletId = _selectedWalletId ?? wallets.first.id;
        
        // Start listening to selected wallet
        transactionProvider.forceRefreshWalletTransactions(walletId);

        final income = transactionProvider.getWalletIncome(walletId);
        final expense = transactionProvider.getWalletExpense(walletId);
        final balance = transactionProvider.getWalletBalance(walletId);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance amount and wallet selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    CurrencyFormatter.format(balance),
                    style: AppTextStyles.h1.copyWith(
                      color: AppColors.textWhite,
                      fontSize: 32,
                    ),
                  ),
                ),
                // Wallet selector dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.textWhite.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.textWhite.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: walletId,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                        size: 20,
                      ),
                      dropdownColor: AppColors.primary,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      items: wallets.map((wallet) {
                        return DropdownMenuItem<String>(
                          value: wallet.id,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                wallet.icon ?? '👥',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                wallet.name.length > 8 
                                    ? '${wallet.name.substring(0, 8)}...'
                                    : wallet.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (newWalletId) {
                        if (newWalletId != null) {
                          setState(() {
                            _selectedWalletId = newWalletId;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Text(
              selectedWallet?.name ?? 'Ví cộng đồng',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textWhite.withValues(alpha: 0.8),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Thu nhập',
                    income,
                    Icons.arrow_downward,
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Chi tiêu',
                    expense,
                    Icons.arrow_upward,
                    AppColors.error,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // AI Insights section for community balance too
            _buildAIInsightsSection(aiProvider),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(
    String label,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.textWhite.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textWhite.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(amount),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsightsSection(AIProvider aiProvider) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, RouteNames.aiInsights);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.textWhite.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.textWhite.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Insights',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textWhite.withValues(alpha: 0.9),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: AppColors.textWhite.withValues(alpha: 0.7),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (aiProvider.isLoadingPrediction) ...[
              Row(
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textWhite.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Đang phân tích...',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textWhite.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ] else if (aiProvider.monthlyPrediction != null) ...[
              _buildPredictionContent(aiProvider.monthlyPrediction!),
            ] else if (aiProvider.errorMessage != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.orange.withValues(alpha: 0.8),
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI server chưa sẵn sàng',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.orange.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'Thêm giao dịch để nhận insights từ AI',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textWhite.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionContent(Map<String, dynamic> prediction) {
    final predictedAmount = prediction['predicted_amount'];
    final confidence = (prediction['confidence'] as num?)?.toDouble() ?? 0;
    final trend = prediction['trend'] ?? 'unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Dự đoán tháng tới: ',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textWhite.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
            Text(
              CurrencyFormatter.formatSafe(predictedAmount),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textWhite,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _buildInfoChip(
              Icons.verified,
              '${(confidence * 100).toInt()}%',
              Colors.green.shade600,
            ),
            const SizedBox(width: 8),
            _buildInfoChip(
              _getTrendIcon(trend),
              _getTrendText(trend),
              _getTrendColor(trend),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'increasing':
        return Icons.trending_up;
      case 'decreasing':
        return Icons.trending_down;
      case 'stable':
        return Icons.trending_flat;
      default:
        return Icons.help_outline;
    }
  }

  String _getTrendText(String trend) {
    switch (trend) {
      case 'increasing':
        return 'Tăng';
      case 'decreasing':
        return 'Giảm';
      case 'stable':
        return 'Ổn định';
      default:
        return 'Không rõ';
    }
  }

  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'increasing':
        return Colors.red.shade600;
      case 'decreasing':
        return Colors.green.shade600;
      case 'stable':
        return Colors.blue.shade600;
      default:
        return Colors.grey.shade600;
    }
  }
}
