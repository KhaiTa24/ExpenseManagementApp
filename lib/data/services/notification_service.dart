import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../datasources/local/database_helper.dart';
import '../../core/constants/database_constants.dart';

class NotificationService {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Local database operations
  Future<void> insertNotification(NotificationModel notification) async {
    final db = await _databaseHelper.database;
    await db.insert(
      DatabaseConstants.notificationsTable,
      notification.toJson(),
    );
  }

  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    final db = await _databaseHelper.database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConstants.notificationsTable,
      where: '${DatabaseConstants.notificationUserId} = ?',
      whereArgs: [userId],
      orderBy: '${DatabaseConstants.notificationCreatedAt} DESC',
    );
    
    final notifications = List.generate(maps.length, (i) {
      return NotificationModel.fromJson(maps[i]);
    });
    
    return notifications;
  }

  Future<List<NotificationModel>> getUnreadNotifications(String userId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConstants.notificationsTable,
      where: '${DatabaseConstants.notificationUserId} = ? AND ${DatabaseConstants.notificationIsRead} = ?',
      whereArgs: [userId, 0],
      orderBy: '${DatabaseConstants.notificationCreatedAt} DESC',
    );

    return List.generate(maps.length, (i) {
      return NotificationModel.fromJson(maps[i]);
    });
  }

  Future<void> markAsRead(String notificationId) async {
    final db = await _databaseHelper.database;
    await db.update(
      DatabaseConstants.notificationsTable,
      {DatabaseConstants.notificationIsRead: 1},
      where: '${DatabaseConstants.notificationId} = ?',
      whereArgs: [notificationId],
    );
  }

  Future<void> markAllAsRead(String userId) async {
    final db = await _databaseHelper.database;
    await db.update(
      DatabaseConstants.notificationsTable,
      {DatabaseConstants.notificationIsRead: 1},
      where: '${DatabaseConstants.notificationUserId} = ?',
      whereArgs: [userId],
    );
  }

  // Firestore operations for real-time notifications
  Future<void> sendNotificationToFirestore(NotificationModel notification) async {
    await _firestore
        .collection('notifications')
        .doc(notification.id)
        .set(notification.toFirestore());
  }

  Stream<List<NotificationModel>> getUserNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return NotificationModel.fromFirestore(doc.data());
      }).toList();
    });
  }

  Future<void> deleteNotification(String notificationId) async {
    // Delete from local database
    final db = await _databaseHelper.database;
    await db.delete(
      DatabaseConstants.notificationsTable,
      where: '${DatabaseConstants.notificationId} = ?',
      whereArgs: [notificationId],
    );

    // Delete from Firestore
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  // Helper method to create community invitation notification
  Future<NotificationModel> createCommunityInvitationNotification({
    required String inviteeId,
    required String inviterName,
    required String communityWalletName,
    required String communityWalletId,
    required String invitationId,
  }) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: inviteeId,
      type: 'community_invitation',
      title: 'Lời mời tham gia ví cộng đồng',
      message: '$inviterName đã mời bạn tham gia ví cộng đồng "$communityWalletName"',
      data: {
        'communityWalletId': communityWalletId,
        'communityWalletName': communityWalletName,
        'inviterName': inviterName,
        'invitationId': invitationId,
      },
      isRead: false,
      createdAt: DateTime.now(),
    );

    // Save to local database
    try {
      await insertNotification(notification);
    } catch (e) {
      // Continue with Firestore save even if local fails
    }
    
    // Send to Firestore for real-time updates with consistent field names
    try {
      await _firestore.collection('notifications').doc(notification.id).set({
        'id': notification.id,
        'userId': notification.userId,
        'type': notification.type,
        'title': notification.title,
        'message': notification.message,
        'data': notification.data,
        'isRead': notification.isRead,
        'createdAt': Timestamp.fromDate(notification.createdAt),
      });
    } catch (e) {
      // Firestore error is not critical for local operation
    }

    return notification;
  }
}