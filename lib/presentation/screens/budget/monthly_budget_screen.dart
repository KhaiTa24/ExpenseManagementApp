import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/common/custom_button.dart';

class MonthlyBudgetScreen extends StatefulWidget {
  const MonthlyBudgetScreen({super.key});

  @override
  State<MonthlyBudgetScreen> createState() => _MonthlyBudgetScreenState();
}

class _MonthlyBudgetScreenState extends State<MonthlyBudgetScreen> {
  final _amountController = TextEditingController();
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isLoading = true;
  double? _currentBudget;
  double _currentSpending = 0;

  @override
  void initState() {
    super.initState();
    _loadBudget();
    _loadCurrentSpending();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadBudget() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'monthly_budget_${_selectedMonth}_$_selectedYear';
    final budget = prefs.getDouble(key);

    setState(() {
      _currentBudget = budget;
      if (budget != null) {
        _amountController.text = budget.toStringAsFixed(0);
      }
      _isLoading = false;
    });
  }

  Future<void> _loadCurrentSpending() async {
    final transactionProvider = context.read<TransactionProvider>();
    final transactions = transactionProvider.transactions;

    double spending = 0;
    for (var transaction in transactions) {
      if (transaction.type == 'expense' &&
          transaction.date.month == _selectedMonth &&
          transaction.date.year == _selectedYear) {
        spending += transaction.amount;
      }
    }

    setState(() {
      _currentSpending = spending;
    });
  }

  Future<void> _saveBudget() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số tiền'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số tiền không hợp lệ'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final key = 'monthly_budget_${_selectedMonth}_$_selectedYear';
    await prefs.setDouble(key, amount);

    setState(() {
      _currentBudget = amount;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu ngân sách tháng'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _deleteBudget() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa ngân sách'),
        content: const Text('Bạn có chắc muốn xóa ngân sách tháng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      final key = 'monthly_budget_${_selectedMonth}_$_selectedYear';
      await prefs.remove(key);

      setState(() {
        _currentBudget = null;
        _amountController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa ngân sách tháng')),
        );
      }
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth += delta;
      if (_selectedMonth > 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else if (_selectedMonth < 1) {
        _selectedMonth = 12;
        _selectedYear--;
      }
    });
    _loadBudget();
    _loadCurrentSpending();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final percentage = _currentBudget != null && _currentBudget! > 0
        ? (_currentSpending / _currentBudget!) * 100
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ngân sách tháng'),
        actions: [
          if (_currentBudget != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteBudget,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Month/Year selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => _changeMonth(-1),
                    ),
                    Text(
                      DateFormat('MMMM yyyy', 'vi')
                          .format(DateTime(_selectedYear, _selectedMonth)),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => _changeMonth(1),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Budget input
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Hạn mức chi tiêu',
                prefixText: '₫ ',
                border: OutlineInputBorder(),
                helperText: 'Nhập tổng số tiền bạn muốn chi tiêu trong tháng',
              ),
            ),

            const SizedBox(height: 24),

            // Current spending
            if (_currentBudget != null) ...[
              Card(
                color: percentage >= 100
                    ? AppColors.error.withValues(alpha: 0.1)
                    : percentage >= 80
                        ? AppColors.warning.withValues(alpha: 0.1)
                        : AppColors.success.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Chi tiêu hiện tại',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: percentage >= 100
                                  ? AppColors.error
                                  : percentage >= 80
                                      ? AppColors.warning
                                      : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: AppColors.grey300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          percentage >= 100
                              ? AppColors.error
                              : percentage >= 80
                                  ? AppColors.warning
                                  : AppColors.success,
                        ),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Đã chi',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(_currentSpending),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Còn lại',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(
                                    _currentBudget! - _currentSpending),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _currentSpending > _currentBudget!
                                      ? AppColors.error
                                      : AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (percentage >= 100)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber,
                                color: AppColors.error,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Bạn đã vượt ngân sách ${CurrencyFormatter.format(_currentSpending - _currentBudget!)}',
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Save button
            CustomButton(
              text: _currentBudget != null ? 'Cập nhật' : 'Lưu ngân sách',
              onPressed: _saveBudget,
            ),
          ],
        ),
      ),
    );
  }
}
