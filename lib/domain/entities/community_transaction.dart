import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityTransaction {
  final String id;
  final String communityWalletId;
  final String userId; // Người tạo giao dịch
  final String userName; // Tên người tạo
  final String type; // 'income' hoặc 'expense'
  final double amount;
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final String description;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CommunityTransaction({
    required this.id,
    required this.communityWalletId,
    required this.userId,
    required this.userName,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.description,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'community_wallet_id': communityWalletId,
      'user_id': userId,
      'user_name': userName,
      'type': type,
      'amount': amount,
      'category_id': categoryId,
      'category_name': categoryName,
      'category_icon': categoryIcon,
      'description': description,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory CommunityTransaction.fromMap(Map<String, dynamic> map) {
    return CommunityTransaction(
      id: map['id'] ?? '',
      communityWalletId: map['community_wallet_id'] ?? '',
      userId: map['user_id'] ?? '',
      userName: map['user_name'] ?? '',
      type: map['type'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      categoryId: map['category_id'] ?? '',
      categoryName: map['category_name'] ?? '',
      categoryIcon: map['category_icon'] ?? '',
      description: map['description'] ?? '',
      date: _parseDateTime(map['date']),
      createdAt: _parseDateTime(map['created_at']),
      updatedAt: _parseDateTime(map['updated_at']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    
    if (value is Timestamp) {
      return value.toDate();
    }
    
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    
    return DateTime.now();
  }

  CommunityTransaction copyWith({
    String? id,
    String? communityWalletId,
    String? userId,
    String? userName,
    String? type,
    double? amount,
    String? categoryId,
    String? categoryName,
    String? categoryIcon,
    String? description,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommunityTransaction(
      id: id ?? this.id,
      communityWalletId: communityWalletId ?? this.communityWalletId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}