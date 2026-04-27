import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/community_member.dart';

class CommunityMemberModel extends CommunityMember {
  const CommunityMemberModel({
    required super.id,
    required super.communityWalletId,
    required super.userId,
    required super.role,
    required super.joinedAt,
    super.isActive,
  });

  factory CommunityMemberModel.fromJson(Map<String, dynamic> json) {
    return CommunityMemberModel(
      id: json['id'] as String,
      communityWalletId: json['community_wallet_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      joinedAt: DateTime.fromMillisecondsSinceEpoch(json['joined_at'] as int),
      isActive: (json['is_active'] as int?) == 1,
    );
  }

  // Convert from Firestore document
  factory CommunityMemberModel.fromFirestore(Map<String, dynamic> data) {
    return CommunityMemberModel(
      id: data['id'] ?? '',
      communityWalletId: data['communityWalletId'] ?? '',
      userId: data['userId'] ?? '',
      role: data['role'] ?? 'member',
      joinedAt: data['joinedAt'] is Timestamp 
          ? (data['joinedAt'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(data['joinedAt'] ?? DateTime.now().millisecondsSinceEpoch),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'community_wallet_id': communityWalletId,
      'user_id': userId,
      'role': role,
      'joined_at': joinedAt.millisecondsSinceEpoch,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory CommunityMemberModel.fromEntity(CommunityMember member) {
    return CommunityMemberModel(
      id: member.id,
      communityWalletId: member.communityWalletId,
      userId: member.userId,
      role: member.role,
      joinedAt: member.joinedAt,
      isActive: member.isActive,
    );
  }
}