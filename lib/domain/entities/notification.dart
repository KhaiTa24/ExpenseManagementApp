class NotificationEntity {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  NotificationEntity copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class CommunityInvitationEntity {
  final String id;
  final String communityWalletId;
  final String inviterId;
  final String inviteeId;
  final String status; // pending, accepted, rejected
  final DateTime createdAt;
  final DateTime? respondedAt;

  const CommunityInvitationEntity({
    required this.id,
    required this.communityWalletId,
    required this.inviterId,
    required this.inviteeId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  CommunityInvitationEntity copyWith({
    String? id,
    String? communityWalletId,
    String? inviterId,
    String? inviteeId,
    String? status,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return CommunityInvitationEntity(
      id: id ?? this.id,
      communityWalletId: communityWalletId ?? this.communityWalletId,
      inviterId: inviterId ?? this.inviterId,
      inviteeId: inviteeId ?? this.inviteeId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}