import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/routes/route_names.dart';
import '../../providers/ai_provider.dart';
import '../../providers/ai_settings_provider.dart';

class AIInsightsScreen extends StatefulWidget {
  const AIInsightsScreen({super.key});

  @override
  State<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAIInsights();
    });
  }

  Future<void> _loadAIInsights() async {
    final aiProvider = context.read<AIProvider>();
    
    // Check server health first
    final isServerHealthy = await aiProvider.checkServerHealth();
    if (!isServerHealthy) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('AI Server không hoạt động. Vui lòng khởi động server trước.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    
    // Load comprehensive insights
    await aiProvider.loadComprehensiveInsights();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Insights'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, RouteNames.aiSettings);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAIInsights,
          ),
        ],
      ),
      body: Consumer<AIProvider>(
        builder: (context, aiProvider, child) {
          if (aiProvider.isLoadingComprehensive) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('AI đang phân tích dữ liệu...'),
                ],
              ),
            );
          }

          if (aiProvider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Lỗi AI Insights',
                      style: AppTextStyles.h2,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      aiProvider.errorMessage!,
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadAIInsights,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadAIInsights,
            child: Consumer<AISettingsProvider>(
              builder: (context, aiSettings, child) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Monthly Prediction Card - only if enabled
                    if (aiSettings.enablePredictions)
                      _buildMonthlyPredictionCard(aiProvider),
                    
                    // Budget Recommendations Card - only if enabled
                    if (aiSettings.enableBudgetRecommendations) ...[
                      if (aiSettings.enablePredictions) const SizedBox(height: 16),
                      _buildBudgetRecommendationsCard(aiProvider),
                    ],
                    
                    // Anomalies Card - only if enabled
                    if (aiSettings.enableAnomalyDetection) ...[
                      if (aiSettings.enablePredictions || aiSettings.enableBudgetRecommendations) 
                        const SizedBox(height: 16),
                      _buildAnomaliesCard(aiProvider),
                    ],
                    
                    // Saving Opportunities Card - only if enabled
                    if (aiSettings.enableSavingTips) ...[
                      if (aiSettings.enablePredictions || 
                          aiSettings.enableBudgetRecommendations || 
                          aiSettings.enableAnomalyDetection) 
                        const SizedBox(height: 16),
                      _buildSavingOpportunitiesCard(aiProvider),
                    ],

                    // Show message if no features are enabled
                    if (!aiSettings.enablePredictions && 
                        !aiSettings.enableBudgetRecommendations &&
                        !aiSettings.enableAnomalyDetection &&
                        !aiSettings.enableSavingTips) ...[
                      const SizedBox(height: 100),
                      Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.settings,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tất cả tính năng AI đã bị tắt',
                              style: AppTextStyles.h3.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Vào cài đặt để bật các tính năng AI',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthlyPredictionCard(AIProvider aiProvider) {
    final prediction = aiProvider.monthlyPrediction;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Dự đoán tháng tới', style: AppTextStyles.h3),
              ],
            ),
            const SizedBox(height: 12),
            
            if (prediction != null) ...[
              Text(
                CurrencyFormatter.formatSafe(prediction['predicted_amount']),
                style: AppTextStyles.h1.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.psychology,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Độ tin cậy: ${((prediction['confidence'] ?? 0) * 100).toInt()}%',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Xu hướng: ${_getTrendText(prediction['trend'])}',
                style: AppTextStyles.bodySmall,
              ),
              if (prediction['message'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  prediction['message'],
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ] else ...[
              const Text('Không có dữ liệu dự đoán'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetRecommendationsCard(AIProvider aiProvider) {
    final budget = aiProvider.budgetRecommendations;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('Gợi ý ngân sách', style: AppTextStyles.h3),
              ],
            ),
            const SizedBox(height: 12),
            
            if (budget != null && budget.isNotEmpty) ...[
              // Show monthly income first if available
              if (budget['monthly_income'] != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.trending_up, color: AppColors.success, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Thu nhập trung bình: ${CurrencyFormatter.formatSafe(budget['monthly_income'])}/tháng',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Gợi ý phân bổ chi tiêu:',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 8),
              ],
              
              // Show only expense categories
              ...budget.entries.where((entry) {
                // Filter out metadata and income categories
                if (entry.key.startsWith('_') || entry.key == 'monthly_income') return false;
                
                // Check if value is a Map
                if (entry.value is! Map<String, dynamic>) {
                  debugPrint('Budget entry ${entry.key} has non-Map value: ${entry.value} (${entry.value.runtimeType})');
                  return false;
                }
                
                final categoryData = entry.value as Map<String, dynamic>;
                
                // Only show expense categories
                final categoryType = categoryData['category_type'] as String?;
                return categoryType == null || categoryType == 'expense';
              }).take(5).map((entry) {
                final categoryData = entry.value as Map<String, dynamic>;
                final percentage = categoryData['percentage'] as num?;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      // Category icon or emoji
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            _getCategoryIcon(entry.key),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatCategoryName(entry.key),
                              style: AppTextStyles.bodyMedium,
                            ),
                            if (percentage != null)
                              Text(
                                '${percentage.toInt()}% thu nhập',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatSafe(categoryData['recommended_budget'] ?? 0),
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ] else ...[
              const Text('Không có gợi ý ngân sách'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnomaliesCard(AIProvider aiProvider) {
    final anomalies = aiProvider.anomalies;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Chi tiêu bất thường', style: AppTextStyles.h3),
              ],
            ),
            const SizedBox(height: 12),
            
            if (anomalies != null) ...[
              Text(
                'Phát hiện ${anomalies['anomalies_found'] ?? 0} giao dịch bất thường',
                style: AppTextStyles.bodyMedium,
              ),
              if ((anomalies['total_anomalous_amount'] ?? 0) > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Tổng số tiền: ${CurrencyFormatter.formatSafe(anomalies['total_anomalous_amount'])}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ],
            ] else ...[
              const Text('Không có dữ liệu phân tích bất thường'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSavingOpportunitiesCard(AIProvider aiProvider) {
    final savings = aiProvider.savingOpportunities;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Cơ hội tiết kiệm', style: AppTextStyles.h3),
              ],
            ),
            const SizedBox(height: 12),
            
            if (savings != null && savings.isNotEmpty) ...[
              // Filter only expense-related saving opportunities
              ...savings.where((opportunity) {
                final category = opportunity['category'] as String?;
                final type = opportunity['type'] as String?;
                
                // Only show expense categories or general saving tips
                return category != 'Lương' && 
                       category != 'Thu nhập khác' && 
                       type != 'income';
              }).take(3).map((opportunity) {
                final category = opportunity['category'] as String? ?? 'Tiết kiệm';
                final suggestion = opportunity['suggestion'] as String? ?? 
                                 opportunity['description'] as String? ?? 
                                 'Cơ hội tiết kiệm';
                final potentialSaving = opportunity['potential_saving'];
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  _getCategoryIcon(category),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Giảm chi tiêu ${_formatCategoryName(category)}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          suggestion,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (potentialSaving != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.savings,
                                size: 16,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Tiết kiệm: ${CurrencyFormatter.formatSafe(potentialSaving)}/tháng',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              
              // Show total potential savings if available
              if (savings.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.trending_up, color: AppColors.success),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tổng tiềm năng tiết kiệm',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatSafe(
                          savings.fold<double>(0, (sum, item) => 
                            sum + (item['potential_saving'] as num? ?? 0).toDouble()
                          )
                        ),
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ] else ...[
              const Text('Không tìm thấy cơ hội tiết kiệm'),
            ],
          ],
        ),
      ),
    );
  }

  String _getTrendText(String? trend) {
    switch (trend) {
      case 'increasing':
        return 'Đang tăng';
      case 'decreasing':
        return 'Đang giảm';
      case 'stable':
        return 'Ổn định';
      default:
        return 'Không xác định';
    }
  }

  String _formatCategoryName(String category) {
    // Format category names to be more readable
    switch (category.toLowerCase()) {
      case 'food':
      case 'ăn uống':
        return 'Ăn uống';
      case 'transport':
      case 'di chuyển':
        return 'Di chuyển';
      case 'education':
      case 'giáo dục':
        return 'Giáo dục';
      case 'entertainment':
      case 'giải trí':
        return 'Giải trí';
      case 'shopping':
      case 'mua sắm':
        return 'Mua sắm';
      case 'health':
      case 'sức khỏe':
        return 'Sức khỏe';
      case 'utilities':
      case 'tiện ích':
      case 'mạng':
        return 'Tiện ích';
      case 'housing':
      case 'nhà ở':
        return 'Nhà ở';
      default:
        return category;
    }
  }

  String _getCategoryIcon(String category) {
    // Return appropriate emoji for each category
    switch (category.toLowerCase()) {
      case 'food':
      case 'ăn uống':
        return '🍔';
      case 'transport':
      case 'di chuyển':
        return '🚗';
      case 'education':
      case 'giáo dục':
        return '📚';
      case 'entertainment':
      case 'giải trí':
        return '🎮';
      case 'shopping':
      case 'mua sắm':
        return '🛒';
      case 'health':
      case 'sức khỏe':
        return '🏥';
      case 'utilities':
      case 'tiện ích':
      case 'mạng':
        return '💡';
      case 'housing':
      case 'nhà ở':
        return '🏠';
      case 'salary':
      case 'lương':
        return '💰';
      default:
        return '📌';
    }
  }
}