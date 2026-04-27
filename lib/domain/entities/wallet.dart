class Wallet {
  final String id;
  final String userId;
  final String name;
  final double balance;
  final String? icon;
  final String? color;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Wallet({
    required this.id,
    required this.userId,
    required this.name,
    required this.balance,
    this.icon,
    this.color,
    required this.createdAt,
    required this.updatedAt,
  });
}
