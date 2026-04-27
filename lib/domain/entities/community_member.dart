class CommunityMember {
  final String id;
  final String communityWalletId;
  final String userId;
  final String role; // 'owner', 'admin', 'member'
  final DateTime joinedAt;
  final bool isActive;

  const CommunityMember({
    required this.id,
    required this.communityWalletId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.isActive = true,
  });

  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';
  bool get canManage => isOwner || isAdmin;
}