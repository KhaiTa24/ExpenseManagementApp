import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Pure Firestore real-time notification provider
class FirestoreNotificationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _pendingInvitations = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Map<String, dynamic>> get notifications => _notifications;
  List<Map<String, dynamic>> get pendingInvitations => _pendingInvitations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Real-time listeners
  StreamSubscription? _notificationsListener;
  StreamSubscription? _invitationsListener;

  /// Start listening to user's notifications in real-time
  void startListeningToNotifications(String userId) {
    _notificationsListener?.cancel();
    
    // Try both field names for compatibility
    _notificationsListener = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId) // Changed from 'user_id' to 'userId'
        .snapshots()
        .listen((snapshot) {
      try {
        // Sort manually in code instead of Firestore
        final notifications = snapshot.docs.map((doc) {
          final data = doc.data();
          
          // Ensure consistent field names for UI
          return {
            'id': data['id'] ?? doc.id,
            'user_id': data['userId'] ?? data['user_id'],
            'type': data['type'],
            'title': data['title'],
            'message': data['message'],
            'is_read': data['isRead'] ?? data['is_read'] ?? false,
            'created_at': data['createdAt'] ?? data['created_at'],
            'data': data['data'],
          };
        }).toList();
        
        notifications.sort((a, b) {
          final aTime = (a['created_at'] as Timestamp?)?.toDate() ?? DateTime.now();
          final bTime = (b['created_at'] as Timestamp?)?.toDate() ?? DateTime.now();
          return bTime.compareTo(aTime); // Descending order
        });
        
        _notifications = notifications;
        _error = null;
        notifyListeners();
      } catch (e) {
        _error = e.toString();
        notifyListeners();
      }
    }, onError: (error) {
      _error = error.toString();
      notifyListeners();
    });
  }

  /// Start listening to user's pending invitations in real-time
  void startListeningToPendingInvitations(String userId) {
    _invitationsListener?.cancel();
    
    _invitationsListener = _firestore
        .collection('community_invitations')
        .where('inviteeId', isEqualTo: userId) // Changed from 'invitee_id' to 'inviteeId'
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) async {
      try {
        final invitations = <Map<String, dynamic>>[];
        
        for (final doc in snapshot.docs) {
          final invitationData = doc.data();
          
          // Handle both field name formats
          final walletId = invitationData['communityWalletId'] ?? invitationData['community_wallet_id'];
          final inviterId = invitationData['inviterId'] ?? invitationData['inviter_id'];
          
          if (walletId == null || inviterId == null) {
            continue;
          }
          
          // Get wallet details
          final walletDoc = await _firestore
              .collection('community_wallets')
              .doc(walletId)
              .get();
              
          if (walletDoc.exists) {
            final walletData = walletDoc.data()!;
            
            // Get inviter details
            final inviterDoc = await _firestore
                .collection('users')
                .doc(inviterId)
                .get();
                
            final inviterData = inviterDoc.exists ? inviterDoc.data()! : {};
            
            invitations.add({
              'id': invitationData['id'] ?? doc.id,
              'community_wallet_id': walletId,
              'inviter_id': inviterId,
              'invitee_id': invitationData['inviteeId'] ?? invitationData['invitee_id'],
              'status': invitationData['status'],
              'created_at': invitationData['createdAt'] ?? invitationData['created_at'],
              'wallet_name': walletData['name'],
              'wallet_description': walletData['description'],
              'inviter_name': inviterData['displayName'] ?? inviterData['display_name'] ?? inviterData['email'] ?? 'Unknown',
            });
          }
        }
        
        // Sort manually by created_at
        invitations.sort((a, b) {
          final aTime = (a['created_at'] as Timestamp?)?.toDate() ?? DateTime.now();
          final bTime = (b['created_at'] as Timestamp?)?.toDate() ?? DateTime.now();
          return bTime.compareTo(aTime); // Descending order
        });
        
        _pendingInvitations = invitations;
        _error = null;
        notifyListeners();
      } catch (e) {
        _error = e.toString();
        notifyListeners();
      }
    }, onError: (error) {
      _error = error.toString();
      notifyListeners();
    });
  }

  /// Accept invitation - direct to Firestore
  Future<bool> acceptInvitation(String invitationId, String userId) async {
    try {
      _setLoading(true);
      
      // Get invitation details
      final invitationDoc = await _firestore
          .collection('community_invitations')
          .doc(invitationId)
          .get();

      if (!invitationDoc.exists) {
        _error = 'Lời mời không tồn tại';
        return false;
      }

      final invitationData = invitationDoc.data()!;
      final walletId = invitationData['communityWalletId'] ?? invitationData['community_wallet_id'];

      if (walletId == null) {
        _error = 'Dữ liệu lời mời không hợp lệ';
        return false;
      }

      // Check if user is already a member
      final existingMember = await _firestore
          .collection('community_members')
          .where('communityWalletId', isEqualTo: walletId)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      if (existingMember.docs.isNotEmpty) {
        // User is already a member, just update invitation status
        await _firestore.collection('community_invitations').doc(invitationId).update({
          'status': 'accepted',
          'respondedAt': Timestamp.now(),
        });
        
        _error = null;
        return true;
      }

      // Create member record with consistent field names
      final memberId = DateTime.now().millisecondsSinceEpoch.toString();
      await _firestore.collection('community_members').doc(memberId).set({
        'id': memberId,
        'communityWalletId': walletId,
        'userId': userId,
        'role': 'member',
        'joinedAt': Timestamp.now(),
        'isActive': true,
      });

      // Update invitation status with consistent field names
      await _firestore.collection('community_invitations').doc(invitationId).update({
        'status': 'accepted',
        'respondedAt': Timestamp.now(),
      });

      // Create a success notification for the user
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'community_joined',
        'title': 'Đã tham gia ví cộng đồng',
        'message': 'Bạn đã tham gia thành công vào ví cộng đồng',
        'isRead': false,
        'createdAt': Timestamp.now(),
        'data': {
          'communityWalletId': walletId,
        },
      });

      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Reject invitation - direct to Firestore
  Future<bool> rejectInvitation(String invitationId) async {
    try {
      await _firestore.collection('community_invitations').doc(invitationId).update({
        'status': 'rejected',
        'respondedAt': Timestamp.now(), // Changed from 'responded_at' to 'respondedAt'
      });

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  /// Mark notification as read - direct to Firestore
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true, // Changed from 'is_read' to 'isRead'
      });

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  /// Mark all notifications as read - direct to Firestore
  Future<bool> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      
      final unreadNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId) // Changed from 'user_id' to 'userId'
          .where('isRead', isEqualTo: false) // Changed from 'is_read' to 'isRead'
          .get();

      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true}); // Changed from 'is_read' to 'isRead'
      }

      await batch.commit();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  /// Stop all listeners
  void stopListeners() {
    _notificationsListener?.cancel();
    _invitationsListener?.cancel();
    _notificationsListener = null;
    _invitationsListener = null;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    stopListeners();
    super.dispose();
  }
}