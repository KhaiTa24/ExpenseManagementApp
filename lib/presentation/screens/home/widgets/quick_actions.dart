import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/route_names.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row 1: Thu nhập và Chi tiêu
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                'Thu nhập',
                Icons.add_circle_outline,
                AppColors.income,
                () {
                  Navigator.pushNamed(
                    context,
                    RouteNames.addTransaction,
                    arguments: {'type': 'income'},
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                'Chi tiêu',
                Icons.remove_circle_outline,
                AppColors.expense,
                () {
                  Navigator.pushNamed(
                    context,
                    RouteNames.addTransaction,
                    arguments: {'type': 'expense'},
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 2: Ví cộng đồng và Báo cáo
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                'Ví cộng đồng',
                Icons.group,
                AppColors.primary,
                () {
                  Navigator.pushNamed(context, RouteNames.communityWallets);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                'Báo cáo',
                Icons.pie_chart_outline,
                AppColors.secondary,
                () {
                  Navigator.pushNamed(context, RouteNames.report);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
