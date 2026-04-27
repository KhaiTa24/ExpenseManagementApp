import '../../domain/entities/budget.dart';

class BudgetModel extends Budget {
  const BudgetModel({
    required super.id,
    required super.userId,
    required super.categoryId,
    required super.amount,
    required super.period,
    required super.month,
    required super.year,
    required super.createdAt,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      period: json['period'] as String,
      month: json['month'] as int,
      year: json['year'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'period': period,
      'month': month,
      'year': year,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory BudgetModel.fromEntity(Budget budget) {
    return BudgetModel(
      id: budget.id,
      userId: budget.userId,
      categoryId: budget.categoryId,
      amount: budget.amount,
      period: budget.period,
      month: budget.month,
      year: budget.year,
      createdAt: budget.createdAt,
    );
  }
}
