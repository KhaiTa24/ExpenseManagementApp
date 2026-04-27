class RecurringTransaction {
  final String id;
  final String userId;
  final String categoryId;
  final double amount;
  final String type; // 'income' or 'expense'
  final String? description;
  final String frequency; // 'daily', 'weekly', 'monthly', 'yearly'
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? lastProcessedDate;
  final bool isActive;
  final DateTime createdAt;

  const RecurringTransaction({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.type,
    this.description,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.lastProcessedDate,
    this.isActive = true,
    required this.createdAt,
  });
  
  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
}
