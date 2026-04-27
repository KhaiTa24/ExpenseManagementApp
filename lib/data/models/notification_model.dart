import 'dart:convert';
import '../../domain/entities/notification.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.type,
    required super.title,
    required super.message,
    required super.data,
    required super.isRead,
    required super.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String, // Fix column name
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      data: json['data'] is String 
          ? jsonDecode(json['data'] as String) as Map<String, dynamic>
          : json['data'] as Map<String, dynamic>? ?? {},
      isRead: json['is_read'] == 1, // Fix column name
      createdAt: DateTime.parse(json['created_at'] as String), // Fix column name
    );
  }

  factory NotificationModel.fromFirestore(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>? ?? {},
      isRead: json['isRead'] as bool,
      createdAt: (json['createdAt'] as dynamic).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId, // Fix column name
      'type': type,
      'title': title,
      'message': message,
      'data': jsonEncode(data), // Convert Map to JSON string for SQLite
      'is_read': isRead ? 1 : 0, // Fix column name
      'created_at': createdAt.toIso8601String(), // Fix column name
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt,
    };
  }
}

class CommunityInvitationModel extends CommunityInvitationEntity {
  const CommunityInvitationModel({
    required super.id,
    required super.communityWalletId,
    required super.inviterId,
    required super.inviteeId,
    required super.status,
    required super.createdAt,
    super.respondedAt,
  });

  factory CommunityInvitationModel.fromJson(Map<String, dynamic> json) {
    return CommunityInvitationModel(
      id: json['id'] as String,
      communityWalletId: json['community_wallet_id'] as String,
      inviterId: json['inviter_id'] as String,
      inviteeId: json['invitee_id'] as String,
      status: json['status'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
      respondedAt: json['responded_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(json['responded_at'] as int)
          : null,
    );
  }

  factory CommunityInvitationModel.fromFirestore(Map<String, dynamic> json) {
    return CommunityInvitationModel(
      id: json['id'] as String,
      communityWalletId: json['communityWalletId'] as String,
      inviterId: json['inviterId'] as String,
      inviteeId: json['inviteeId'] as String,
      status: json['status'] as String,
      createdAt: (json['createdAt'] as dynamic).toDate(),
      respondedAt: json['respondedAt'] != null 
          ? (json['respondedAt'] as dynamic).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'community_wallet_id': communityWalletId,
      'inviter_id': inviterId,
      'invitee_id': inviteeId,
      'status': status,
      'created_at': createdAt.millisecondsSinceEpoch,
      'responded_at': respondedAt?.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'communityWalletId': communityWalletId,
      'inviterId': inviterId,
      'inviteeId': inviteeId,
      'status': status,
      'createdAt': createdAt,
      'respondedAt': respondedAt,
    };
  }
}