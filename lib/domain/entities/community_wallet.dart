class CommunityWallet {
  final String id;
  final String name;
  final String description;
  final double balance;
  final String ownerId; // Người tạo ví
  final String? icon;
  final String? color;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CommunityWallet({
    required this.id,
    required this.name,
    required this.description,
    required this.balance,
    required this.ownerId,
    this.icon,
    this.color,
    required this.createdAt,
    required this.updatedAt,
  });
}