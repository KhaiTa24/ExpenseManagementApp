import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../providers/ai_settings_provider.dart';

class AISettingsScreen extends StatefulWidget {
  const AISettingsScreen({super.key});

  @override
  State<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Load settings when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AISettingsProvider>().loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt AI'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
      ),
      body: Consumer<AISettingsProvider>(
        builder: (context, aiSettings, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // AI Features - Functional toggles
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      _buildSettingTile(
                        title: 'Dự đoán chi tiêu',
                        subtitle: 'Dự đoán chi tiêu tháng tới dựa trên lịch sử',
                        icon: Icons.trending_up,
                        value: aiSettings.enablePredictions,
                        onChanged: (value) =>
                            aiSettings.setEnablePredictions(value),
                      ),

                      _buildSettingTile(
                        title: 'Gợi ý ngân sách',
                        subtitle: 'Đề xuất ngân sách cho từng danh mục',
                        icon: Icons.account_balance_wallet,
                        value: aiSettings.enableBudgetRecommendations,
                        onChanged: (value) =>
                            aiSettings.setEnableBudgetRecommendations(value),
                      ),

                      _buildSettingTile(
                        title: 'Phát hiện bất thường',
                        subtitle: 'Cảnh báo giao dịch bất thường',
                        icon: Icons.warning_amber,
                        value: aiSettings.enableAnomalyDetection,
                        onChanged: (value) =>
                            aiSettings.setEnableAnomalyDetection(value),
                      ),

                      _buildSettingTile(
                        title: 'Lời khuyên tiết kiệm',
                        subtitle: 'Gợi ý cách tiết kiệm tiền hiệu quả',
                        icon: Icons.savings,
                        value: aiSettings.enableSavingTips,
                        onChanged: (value) =>
                            aiSettings.setEnableSavingTips(value),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
        )
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
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
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}