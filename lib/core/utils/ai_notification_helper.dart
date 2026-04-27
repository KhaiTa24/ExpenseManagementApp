import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AINotificationHelper {
  static void showAIInsight(
    BuildContext context, {
    required String title,
    required String message,
    IconData icon = Icons.psychology,
    Color color = AppColors.primary,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static void showPredictionUpdate(
    BuildContext context, {
    required double predictedAmount,
    required int confidence,
    required String trend,
  }) {
    final trendEmoji = _getTrendEmoji(trend);
    showAIInsight(
      context,
      title: 'Dự đoán AI mới',
      message:
          'Tháng tới: ${_formatCurrency(predictedAmount)} $trendEmoji (${confidence}% tin cậy)',
      icon: Icons.trending_up,
      color: Colors.blue,
    );
  }

  static void showBudgetRecommendation(
    BuildContext context, {
    required String category,
    required double recommendedAmount,
  }) {
    showAIInsight(
      context,
      title: 'Gợi ý ngân sách',
      message: '$category: ${_formatCurrency(recommendedAmount)}',
      icon: Icons.account_balance_wallet,
      color: Colors.green,
    );
  }

  static void showAnomalyAlert(
    BuildContext context, {
    required int anomaliesCount,
    required double totalAmount,
  }) {
    showAIInsight(
      context,
      title: 'Phát hiện bất thường',
      message:
          '$anomaliesCount giao dịch bất thường (${_formatCurrency(totalAmount)})',
      icon: Icons.warning,
      color: Colors.orange,
    );
  }

  static void showSavingOpportunity(
    BuildContext context, {
    required String opportunity,
    required double potentialSaving,
  }) {
    showAIInsight(
      context,
      title: 'Cơ hội tiết kiệm',
      message: '$opportunity - Tiết kiệm: ${_formatCurrency(potentialSaving)}',
      icon: Icons.savings,
      color: Colors.green,
    );
  }

  static void showServerError(BuildContext context) {
    showAIInsight(
      context,
      title: 'AI Server lỗi',
      message: 'Không thể kết nối đến AI server. Vui lòng thử lại sau.',
      icon: Icons.error_outline,
      color: Colors.red,
    );
  }

  static void showServerReconnected(BuildContext context) {
    showAIInsight(
      context,
      title: 'AI Server đã kết nối',
      message: 'AI insights đã sẵn sàng!',
      icon: Icons.check_circle,
      color: Colors.green,
      duration: const Duration(seconds: 2),
    );
  }

  static String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  static String _getTrendEmoji(String trend) {
    switch (trend) {
      case 'increasing':
        return '📈';
      case 'decreasing':
        return '📉';
      case 'stable':
        return '➡️';
      default:
        return '❓';
    }
  }
}
