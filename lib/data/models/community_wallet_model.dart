import '../../domain/entities/community_wallet.dart';

class CommunityWalletModel extends CommunityWallet {
  const CommunityWalletModel({
    required super.id,
    required super.name,
    required super.description,
    required super.balance,
    required super.ownerId,
    super.icon,
    super.color,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CommunityWalletModel.fromJson(Map<String, dynamic> json) {
    return CommunityWalletModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      ownerId: json['owner_id'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['updated_at'] as int)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'balance': balance,
      'owner_id': ownerId,
      'icon': icon,
      'color': color,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory CommunityWalletModel.fromEntity(CommunityWallet wallet) {
    return CommunityWalletModel(
      id: wallet.id,
      name: wallet.name,
      description: wallet.description,
      balance: wallet.balance,
      ownerId: wallet.ownerId,
      icon: wallet.icon,
      color: wallet.color,
      createdAt: wallet.createdAt,
      updatedAt: wallet.updatedAt,
    );
  }
}