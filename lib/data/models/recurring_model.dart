import '../../domain/entities/recurring_transaction.dart';

class RecurringModel extends RecurringTransaction {
  const RecurringModel({
    required super.id,
    required super.userId,
    required super.categoryId,
    required super.amount,
    required super.type,
    super.description,
    required super.frequency,
    required super.startDate,
    super.endDate,
    super.lastProcessedDate,
    super.isActive,
    required super.createdAt,
  });

  factory RecurringModel.fromJson(Map<String, dynamic> json) {
    return RecurringModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      categoryId: json['category_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      description: json['description'] as String?,
      frequency: json['frequency'] as String,
      startDate: DateTime.fromMillisecondsSinceEpoch(json['start_date'] as int),
      endDate: json['end_date'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['end_date'] as int)
          : null,
      lastProcessedDate: json['last_processed_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['last_processed_date'] as int)
          : null,
      isActive: (json['is_active'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'type': type,
      'description': description,
      'frequency': frequency,
      'start_date': startDate.millisecondsSinceEpoch,
      'end_date': endDate?.millisecondsSinceEpoch,
      'last_processed_date': lastProcessedDate?.millisecondsSinceEpoch,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory RecurringModel.fromEntity(RecurringTransaction recurring) {
    return RecurringModel(
      id: recurring.id,
      userId: recurring.userId,
      categoryId: recurring.categoryId,
      amount: recurring.amount,
      type: recurring.type,
      description: recurring.description,
      frequency: recurring.frequency,
      startDate: recurring.startDate,
      endDate: recurring.endDate,
      lastProcessedDate: recurring.lastProcessedDate,
      isActive: recurring.isActive,
      createdAt: recurring.createdAt,
    );
  }
}
