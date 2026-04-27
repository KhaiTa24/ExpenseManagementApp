import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/transaction_filter.dart';
import '../../providers/category_provider.dart';
import '../../providers/auth_provider.dart';

class TransactionFilterScreen extends StatefulWidget {
  final TransactionFilter? currentFilter;

  const TransactionFilterScreen({super.key, this.currentFilter});

  @override
  State<TransactionFilterScreen> createState() =>
      _TransactionFilterScreenState();
}

class _TransactionFilterScreenState extends State<TransactionFilterScreen> {
  String? _selectedType;
  String? _selectedSource; // personal, community, all
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCategoryId;
  FilterPeriod? _selectedPeriod;

  @override
  void initState() {
    super.initState();
    if (widget.currentFilter != null) {
      _selectedType = widget.currentFilter!.type;
      _selectedSource = widget.currentFilter!.source;
      _startDate = widget.currentFilter!.startDate;
      _endDate = widget.currentFilter!.endDate;
      _selectedCategoryId = widget.currentFilter!.categoryId;
      _selectedPeriod = widget.currentFilter!.period;
    }
  }

  void _clearFilter() {
    setState(() {
      _selectedType = null;
      _selectedSource = null;
      _startDate = null;
      _endDate = null;
      _selectedCategoryId = null;
      _selectedPeriod = null;
    });
  }

  void _applyFilter() {
    final filter = TransactionFilter(
      type: _selectedType,
      source: _selectedSource,
      startDate: _startDate,
      endDate: _endDate,
      categoryId: _selectedCategoryId,
      period: _selectedPeriod,
    );
    Navigator.pop(context, filter);
  }

  void _selectPeriod(FilterPeriod period) {
    setState(() {
      _selectedPeriod = period;
      final now = DateTime.now();

      switch (period) {
        case FilterPeriod.today:
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case FilterPeriod.yesterday:
          final yesterday = now.subtract(const Duration(days: 1));
          _startDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
          _endDate =
              DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
          break;
        case FilterPeriod.thisWeek:
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          _startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case FilterPeriod.thisMonth:
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          break;
        case FilterPeriod.lastMonth:
          _startDate = DateTime(now.year, now.month - 1, 1);
          _endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
          break;
        case FilterPeriod.custom:
          // User will select custom dates
          break;
      }
    });
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
        _selectedPeriod = FilterPeriod.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lọc giao dịch'),
        actions: [
          TextButton(
            onPressed: _clearFilter,
            child: const Text('Xóa lọc'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTypeFilter(),
          const SizedBox(height: 24),
          _buildSourceFilter(),
          const SizedBox(height: 24),
          _buildPeriodFilter(),
          const SizedBox(height: 24),
          _buildDateFilter(),
          const SizedBox(height: 24),
          _buildCategoryFilter(),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _applyFilter,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Áp dụng lọc'),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Loại giao dịch',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: [
            ChoiceChip(
              label: const Text('Tất cả'),
              selected: _selectedType == null,
              onSelected: (selected) {
                setState(() {
                  _selectedType = null;
                });
              },
            ),
            ChoiceChip(
              label: const Text('Thu nhập'),
              selected: _selectedType == 'income',
              selectedColor: AppColors.income.withValues(alpha: 0.3),
              onSelected: (selected) {
                setState(() {
                  _selectedType = selected ? 'income' : null;
                });
              },
            ),
            ChoiceChip(
              label: const Text('Chi tiêu'),
              selected: _selectedType == 'expense',
              selectedColor: AppColors.expense.withValues(alpha: 0.3),
              onSelected: (selected) {
                setState(() {
                  _selectedType = selected ? 'expense' : null;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSourceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nguồn giao dịch',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          children: [
            ChoiceChip(
              label: const Text('Tất cả'),
              selected: _selectedSource == null,
              onSelected: (selected) {
                setState(() {
                  _selectedSource = null;
                });
              },
            ),
            ChoiceChip(
              label: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('💼'),
                  SizedBox(width: 4),
                  Text('Cá nhân'),
                ],
              ),
              selected: _selectedSource == 'personal',
              selectedColor: AppColors.primary.withValues(alpha: 0.3),
              onSelected: (selected) {
                setState(() {
                  _selectedSource = selected ? 'personal' : null;
                });
              },
            ),
            ChoiceChip(
              label: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('👥'),
                  SizedBox(width: 4),
                  Text('Cộng đồng'),
                ],
              ),
              selected: _selectedSource == 'community',
              selectedColor: Colors.orange.withValues(alpha: 0.3),
              onSelected: (selected) {
                setState(() {
                  _selectedSource = selected ? 'community' : null;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Khoảng thời gian',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildPeriodChip('Hôm nay', FilterPeriod.today),
            _buildPeriodChip('Hôm qua', FilterPeriod.yesterday),
            _buildPeriodChip('Tuần này', FilterPeriod.thisWeek),
            _buildPeriodChip('Tháng này', FilterPeriod.thisMonth),
            _buildPeriodChip('Tháng trước', FilterPeriod.lastMonth),
            _buildPeriodChip('Tùy chỉnh', FilterPeriod.custom),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodChip(String label, FilterPeriod period) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedPeriod == period,
      onSelected: (selected) {
        if (selected) {
          _selectPeriod(period);
        }
      },
    );
  }

  Widget _buildDateFilter() {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn ngày cụ thể',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(true),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Từ ngày',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _startDate != null
                        ? dateFormat.format(_startDate!)
                        : 'Chọn ngày',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(false),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Đến ngày',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _endDate != null
                        ? dateFormat.format(_endDate!)
                        : 'Chọn ngày',
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    final authProvider = context.watch<AuthProvider>();
    final userId = authProvider.currentUser?.id;

    if (userId == null) return const SizedBox.shrink();

    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        final categories = _selectedType == 'income'
            ? categoryProvider.incomeCategories
            : _selectedType == 'expense'
                ? categoryProvider.expenseCategories
                : categoryProvider.categories;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Danh mục',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Tất cả'),
                  selected: _selectedCategoryId == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategoryId = null;
                    });
                  },
                ),
                ...categories.map((category) {
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(category.icon),
                        const SizedBox(width: 4),
                        Text(category.name),
                      ],
                    ),
                    selected: _selectedCategoryId == category.id,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategoryId = selected ? category.id : null;
                      });
                    },
                  );
                }),
              ],
            ),
          ],
        );
      },
    );
  }
}
