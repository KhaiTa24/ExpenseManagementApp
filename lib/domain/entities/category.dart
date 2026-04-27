class Category {
  final String id;
  final String userId;
  final String name;
  final String icon;
  final String color;
  final String type; // 'income' or 'expense'
  final bool isDefault;
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.userId,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.isDefault = false,
    required this.createdAt,
  });
  
  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
}
