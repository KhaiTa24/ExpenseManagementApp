import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';

class CategoryPieChart extends StatelessWidget {
  final Map<String, CategoryChartData> categoryData;

  const CategoryPieChart({super.key, required this.categoryData});

  @override
  Widget build(BuildContext context) {
    if (categoryData.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có dữ liệu',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final total = categoryData.values.fold(0.0, (sum, data) => sum + data.amount);

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: PieChart(
            PieChartData(
              sections: _buildSections(total),
              centerSpaceRadius: 50,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {},
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLegend(),
      ],
    );
  }

  List<PieChartSectionData> _buildSections(double total) {
    final colors = [
      AppColors.primary,
      AppColors.expense,
      AppColors.warning,
      AppColors.success,
      AppColors.secondary,
      const Color(0xFF9C27B0),
      const Color(0xFF00BCD4),
      const Color(0xFFFF9800),
    ];

    int index = 0;
    return categoryData.entries.map((entry) {
      final percentage = (entry.value.amount / total * 100);
      final color = colors[index % colors.length];
      index++;

      return PieChartSectionData(
        value: entry.value.amount,
        title: '${percentage.toStringAsFixed(1)}%',
        color: color,
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend() {
    final colors = [
      AppColors.primary,
      AppColors.expense,
      AppColors.warning,
      AppColors.success,
      AppColors.secondary,
      const Color(0xFF9C27B0),
      const Color(0xFF00BCD4),
      const Color(0xFFFF9800),
    ];

    int index = 0;
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: categoryData.entries.map((entry) {
        final color = colors[index % colors.length];
        index++;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${entry.value.icon} ${entry.key}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 4),
            Text(
              CurrencyFormatter.format(entry.value.amount),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class CategoryChartData {
  final double amount;
  final String icon;
  final int transactionCount;

  CategoryChartData({
    required this.amount,
    required this.icon,
    required this.transactionCount,
  });
}
