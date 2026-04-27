class MonthlyBudget {
  final String id;
  final String userId;
  final double amount;
  final int month;
  final int year;
  final DateTime createdAt;
  final DateTime? updatedAt;

  MonthlyBudget({
    required this.id,
    required this.userId,
    required this.amount,
    required this.month,
    required this.year,
    required this.createdAt,
    this.updatedAt,
  });

  bool isCurrentMonth() {
    final now = DateTime.now();
    return month == now.month && year == now.year;
  }

  String get monthYearString {
    return '$month/$year';
  }
}
