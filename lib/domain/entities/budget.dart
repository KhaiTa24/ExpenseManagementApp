class Budget {
  final String id;
  final String userId;
  final String categoryId;
  final double amount;
  final String period; // 'monthly' or 'yearly'
  final int month;
  final int year;
  final DateTime createdAt;

  const Budget({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.period,
    required this.month,
    required this.year,
    required this.createdAt,
  });
  
  bool get isMonthly => period == 'monthly';
  bool get isYearly => period == 'yearly';
}
