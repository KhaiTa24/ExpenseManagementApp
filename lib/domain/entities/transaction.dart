class Transaction {
  final String id;
  final String userId;
  final String categoryId;
  final double amount;
  final String type; // 'income' or 'expense'
  final String? description;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? walletId; // Ví cá nhân
  final String? communityWalletId; // Ví cộng đồng

  const Transaction({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.type,
    this.description,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.walletId,
    this.communityWalletId,
  });
  
  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
  bool get isCommunityTransaction => communityWalletId != null;
}
