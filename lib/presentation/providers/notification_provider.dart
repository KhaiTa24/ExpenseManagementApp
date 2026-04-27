import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/community_invitation_service.dart';
import '../../data/datasources/local/database_helper.dart';
import '../../core/constants/database_constants.dart';
import '../../core/utils/global_refresh_manager.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final CommunityInvitationService _invitationService =
      CommunityInvitationService();

  List<NotificationModel> _notifications = [];
  List<CommunityInvitationModel> _pendingInvitations = [];
  bool _isLoading = false;
  String? _error;

  List<NotificationModel> get notifications => _notifications;
  List<CommunityInvitationModel> get pendingInvitations => _pendingInvitations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount {
    // Force recalculate unread count to ensure accuracy
    final count = _notifications.where((n) => !n.isRead).length;
    return count;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Load notifications for user
  Future<void> loadNotifications(String userId) async {
    try {
      _setLoading(true);
      _setError(null);

      // Fix pending invitations for existing members first
      await _invitationService.fixPendingInvitationsForExistingMembers(userId);

      // Load from local database first
      final freshNotifications =
          await _notificationService.getUserNotifications(userId);
      
      _notifications = freshNotifications;

      // Sync from Firestore and create invitations from notifications FIRST
      await _syncInvitationsFromFirestore(userId);

      // THEN load pending invitations (after creating from notifications)
      final freshInvitations =
          await _invitationService.getPendingInvitations(userId);
      _pendingInvitations = freshInvitations;

      notifyListeners();
    } catch (e) {
      _setError('Không thể tải thông báo: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Sync invitations from Firestore to local database
  Future<void> _syncInvitationsFromFirestore(String userId) async {
    try {
      // Get invitations from Firestore
      final firestoreInvitations =
          await _invitationService.getInvitationsFromFirestore(userId);

      // Sync each invitation to local database
      for (final invitation in firestoreInvitations) {
        try {
          await _invitationService.syncInvitationToLocal(invitation);
        } catch (e) {
          // Skip invalid invitations
        }
      }

      // GIẢI PHÁP TẠM THỜI: Tạo invitations từ notifications
      await _createInvitationsFromNotifications(userId);

      // Reload local invitations after sync
      final updatedInvitations =
          await _invitationService.getPendingInvitations(userId);
      _pendingInvitations = updatedInvitations;
    } catch (e) {
      // Error is not critical for this operation
    }
  }

  // Tạo invitations từ notifications (giải pháp tạm thời)
  Future<void> _createInvitationsFromNotifications(String userId) async {
    try {
      // Lấy tất cả notifications type community_invitation
      final communityNotifications = _notifications
          .where((notification) =>
              notification.type == 'community_invitation' &&
              notification.data.isNotEmpty)
          .toList();

      // Xử lý tất cả community notifications (không giới hạn thời gian)
      for (final notification in communityNotifications) {
        try {
          final data = notification.data;
          final communityWalletId = data['communityWalletId'] as String?;
          final invitationId = data['invitationId'] as String?;

          if (communityWalletId != null && invitationId != null) {
            // Kiểm tra xem invitation đã tồn tại chưa
            final allInvitations = await _invitationService.getAllInvitations(userId);
            final existingInvitation = allInvitations.where((inv) => inv.id == invitationId).isNotEmpty 
                ? allInvitations.firstWhere((inv) => inv.id == invitationId)
                : null;

            if (existingInvitation == null) {
              // Tạo invitation mới từ notification data
              final invitation = CommunityInvitationModel(
                id: invitationId,
                communityWalletId: communityWalletId,
                inviterId: 'system', // Đánh dấu là từ notification
                inviteeId: userId,
                status: 'pending',
                createdAt: notification.createdAt,
                respondedAt: null,
              );

              // Insert vào database
              final db = await DatabaseHelper.instance.database;
              try {
                await db.insert(
                  DatabaseConstants.communityInvitationsTable,
                  invitation.toJson(),
                );
              } catch (e) {
                // Nếu đã tồn tại, bỏ qua
                if (!e.toString().contains('UNIQUE constraint failed')) {
                  rethrow;
                }
              }
            } else if (existingInvitation.status == 'accepted' || existingInvitation.status == 'rejected') {
              // Nếu invitation đã được xử lý, bỏ qua
              continue;
            }
          }
        } catch (e) {
          // Skip invalid notification data
        }
      }
    } catch (e) {
      // Error is not critical for this operation
    }
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          userId: _notifications[index].userId,
          type: _notifications[index].type,
          title: _notifications[index].title,
          message: _notifications[index].message,
          data: _notifications[index].data,
          isRead: true,
          createdAt: _notifications[index].createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      _setError('Không thể đánh dấu đã đọc: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await _notificationService.markAllAsRead(userId);

      // Update local state - ensure all notifications are marked as read
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i] = NotificationModel(
          id: _notifications[i].id,
          userId: _notifications[i].userId,
          type: _notifications[i].type,
          title: _notifications[i].title,
          message: _notifications[i].message,
          data: _notifications[i].data,
          isRead: true, // Force all to be read
          createdAt: _notifications[i].createdAt,
        );
      }
      
      // Force notify listeners to update UI immediately
      notifyListeners();
      
      // Double check - reload notifications from database to ensure sync
      await Future.delayed(const Duration(milliseconds: 100));
      final freshNotifications = await _notificationService.getUserNotifications(userId);
      _notifications = freshNotifications;
      notifyListeners();
      
    } catch (e) {
      _setError('Không thể đánh dấu tất cả đã đọc: $e');
    }
  }

  // Accept community invitation
  Future<void> acceptInvitation(String invitationId, String userId) async {
    try {
      _setLoading(true);
      _setError(null);

      await _invitationService.acceptInvitation(invitationId, userId);

      // Remove from pending invitations immediately
      _pendingInvitations.removeWhere((inv) => inv.id == invitationId);

      // Reload notifications and invitations to update UI
      await loadNotifications(userId);

      // Also refresh pending invitations specifically
      final freshInvitations = await _invitationService.getPendingInvitations(userId);
      _pendingInvitations = freshInvitations;

      // Notify that members might have changed (for other providers to listen)
      _notifyMembersChanged();

      // Auto refresh community wallets after accepting invitation
      _scheduleAutoRefresh();

      // IMPORTANT: Trigger refresh of community wallets list
      _triggerCommunityWalletsRefresh();

      // CRITICAL: Also trigger reload of user's community wallets
      // This ensures the newly joined wallet appears in the list
      _triggerUserWalletsReload(userId);

      // FORCE: Directly reload community wallets for immediate effect
      await _forceReloadCommunityWallets(userId);

      notifyListeners();
    } catch (e) {
      _setError('Không thể chấp nhận lời mời: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Trigger refresh of community wallets list
  void _triggerCommunityWalletsRefresh() {
    // Trigger global refresh for community wallets
    GlobalRefreshManager.triggerRefresh('community_wallets');
  }

  // Trigger reload of user's community wallets
  void _triggerUserWalletsReload(String userId) {
    // This will trigger the CommunityWalletProvider to reload user's wallets
    GlobalRefreshManager.triggerRefresh('user_wallets_$userId');
  }

  // Force reload community wallets immediately
  Future<void> _forceReloadCommunityWallets(String userId) async {
    try {
      // Get CommunityWalletProvider and force reload
      // This is a direct approach to ensure wallets are reloaded
      
      // Trigger multiple refresh events to ensure it works
      GlobalRefreshManager.triggerRefresh('all');
      GlobalRefreshManager.triggerRefresh('community_wallets');
      GlobalRefreshManager.triggerRefresh('user_wallets_$userId');
      
      // Add a small delay to ensure events are processed
      await Future.delayed(const Duration(milliseconds: 500));
      
    } catch (e) {
      // Error force reloading community wallets
    }
  }

  // Schedule auto refresh for community wallets
  void _scheduleAutoRefresh() {
    // Delay a bit to ensure Firestore sync is complete
    Timer(const Duration(seconds: 2), () {
      _notifyMembersChanged();
    });
    
    // Another refresh after 5 seconds
    Timer(const Duration(seconds: 5), () {
      _notifyMembersChanged();
    });
  }

  // Notify that members might have changed (for other providers to listen)
  void _notifyMembersChanged() {
    // Trigger a global refresh event
    _triggerGlobalRefresh();
  }

  // Trigger global refresh for all community wallet screens
  void _triggerGlobalRefresh() {
    // This is a simple implementation - in a real app you might use EventBus
    // For now, we'll use a static callback approach
    GlobalRefreshManager.triggerRefresh();
  }

  // Reject community invitation
  Future<void> rejectInvitation(String invitationId, String userId) async {
    try {
      _setLoading(true);
      _setError(null);

      await _invitationService.rejectInvitation(invitationId);

      // Remove from pending invitations
      _pendingInvitations.removeWhere((inv) => inv.id == invitationId);

      notifyListeners();
    } catch (e) {
      _setError('Không thể từ chối lời mời: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);

      // Remove from local state
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      _setError('Không thể xóa thông báo: $e');
    }
  }

  // Listen to real-time notifications
  void listenToNotifications(String userId) {
    _notificationService.getUserNotificationsStream(userId).listen(
      (firestoreNotifications) async {
        // Sync Firestore notifications to local database
        for (final notification in firestoreNotifications) {
          try {
            await _notificationService.insertNotification(notification);
          } catch (e) {
            // Notification might already exist
          }
        }

        // Reload from local database to get the merged data
        await loadNotifications(userId);
      },
      onError: (error) {
        _setError('Lỗi khi nhận thông báo: $error');
      },
    );

    _invitationService.getPendingInvitationsStream(userId).listen(
      (firestoreInvitations) async {
        // Sync Firestore invitations to local database
        for (final invitation in firestoreInvitations) {
          try {
            await _invitationService.syncInvitationToLocal(invitation);
          } catch (e) {
            // Invitation might already exist
          }
        }

        // Reload from local database to get the merged data
        await loadNotifications(userId);
      },
      onError: (error) {
        _setError('Lỗi khi nhận lời mời: $error');
      },
    );
  }

  void clearError() {
    _setError(null);
  }
}
