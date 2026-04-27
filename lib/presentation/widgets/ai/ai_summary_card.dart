import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/routes/route_names.dart';
import '../../providers/ai_provider.dart';

class AISummaryCard extends StatefulWidget {
  const AISummaryCard({super.key});

  @override
  State<AISummaryCard> createState() => _AISummaryCardState();
}

class _AISummaryCardState extends State<AISummaryCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadQuickInsights();
    });
  }

  Future<void> _loadQuickInsights() async {
    final aiProvider = context.read<AIProvider>();
    
    // Check if server is healthy before loading
    final isHealthy = await aiProvider.checkServerHealth();
    if (isHealthy && mounted) {
      await aiProvider.loadMonthlyPrediction();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AIProvider>(
      builder: (context, aiProvider, child) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(context, RouteNames.aiInsights);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    Colors.purple.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.psychology,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Insights',
                              style: AppTextStyles.h4.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              'Phân tích thông minh',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Content
                  if (aiProvider.isLoadingPrediction) ...[
                    _buildLoadingContent(),
                  ] else if (aiProvider.errorMessage != null) ...[
                    _buildErrorContent(),
                  ] else if (aiProvider.monthlyPrediction != null) ...[
                    _buildPredictionContent(aiProvider.monthlyPrediction!),
                  ] else ...[
                    _buildEmptyContent(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingContent() {
    return const Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: 12),
        Text('Đang phân tích...'),
      ],
    );
  }

  Widget _buildErrorContent() {
    return Row(
      children: [
        const Icon(
          Icons.warning_amber,
          color: Colors.orange,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'AI server chưa sẵn sàng',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.orange,
            ),
          ),
        ),
      ],
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
            const Icon(
              Icons.trending_up,
              color: Colors.blue,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Dự đoán tháng tới',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          CurrencyFormatter.formatSafe(predictedAmount),
          style: AppTextStyles.h3.copyWith(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildInfoChip(
              Icons.verified,
              '${(confidence * 100).toInt()}%',
              Colors.green,
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

  Widget _buildEmptyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.lightbulb_outline,
              color: Colors.amber,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Sẵn sàng phân tích',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Thêm giao dịch để nhận insights từ AI',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
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
        return Colors.red;
      case 'decreasing':
        return Colors.green;
      case 'stable':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}