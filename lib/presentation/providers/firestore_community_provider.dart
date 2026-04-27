import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/community_wallet.dart';
import '../../domain/entities/community_member.dart';

/// Pure Firestore real-time provider for Community Wallets
/// No local database sync - everything is real-time from Firestore
class FirestoreCommunityProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  List<CommunityWallet> _userWallets = [];
  List<CommunityMember> _currentWalletMembers = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<CommunityWallet> get userWallets => _userWallets;
  List<CommunityMember> get currentWalletMembers => _currentWalletMembers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Real-time listeners
  StreamSubscription? _userWalletsListener;
  StreamSubscription? _membersListener;

  /// Start listening to user's community wallets in real-time
  void startListeningToUserWallets(String userId) {
    _userWalletsListener?.cancel();
    _userWalletsListener = _firestore
        .collection('community_members')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((memberSnapshot) async {
      try {
        final walletIds = memberSnapshot.docs
            .map((doc) => doc.data()['communityWalletId'] as String)
            .toList();

        if (walletIds.isEmpty) {
          _userWallets = [];
          notifyListeners();
          return;
        }

        // Get wallets data
        final walletsQuery = await _firestore
            .collection('community_wallets')
            .where(FieldPath.documentId, whereIn: walletIds)
            .get();

        _userWallets = walletsQuery.docs.map((doc) {
          final data = doc.data();
          return CommunityWallet(
            id: data['id'],
            name: data['name'],
            description: data['description'] ?? '',
            balance: (data['balance'] ?? 0.0).toDouble(),
            ownerId: data['owner_id'],
            icon: data['icon'],
            color: data['color'],
            createdAt: _parseDateTime(data['created_at']),
            updatedAt: _parseDateTime(data['updated_at']),
          );
        }).toList();

        notifyListeners();
      } catch (e) {
        _error = e.toString();
        notifyListeners();
      }
    });
  }

  /// Start listening to wallet members in real-time
  void startListeningToWalletMembers(String walletId) {
    print('DEBUG: Starting real-time listener for wallet members: $walletId');
    
    _membersListener?.cancel();
    _membersListener = _firestore
        .collection('community_members')
        .where('communityWalletId', isEqualTo: walletId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      try {
        _currentWalletMembers = snapshot.docs.map((doc) {
          final data = doc.data();
          return CommunityMember(
            id: data['id'],
            communityWalletId: data['communityWalletId'],
            userId: data['userId'],
            role: data['role'],
            joinedAt: _parseDateTime(data['joinedAt']),
            isActive: data['isActive'] ?? true,
          );
        }).toList();

        print('DEBUG: Wallet members updated: ${_currentWalletMembers.length} members');
        notifyListeners();
      } catch (e) {
        print('DEBUG: Error in members listener: $e');
        _error = e.toString();
        notifyListeners();
      }
    });
  }

  /// Create community wallet - direct to Firestore
  Future<bool> createCommunityWallet({
    required String name,
    required String description,
    required String ownerId,
    String? icon,
    String? color,
  }) async {
    try {
      _setLoading(true);
      
      final walletId = _uuid.v4();
      final now = Timestamp.now();

      // 1. Create wallet in Firestore
      await _firestore.collection('community_wallets').doc(walletId).set({
        'id': walletId,
        'name': name,
        'description': description,
        'owner_id': ownerId,
        'balance': 0.0,
        'icon': icon ?? '💰',
        'color': color ?? '#4CAF50',
        'created_at': now,
        'updated_at': now,
      });

      // 2. Create owner member in Firestore
      final memberId = _uuid.v4();
      await _firestore.collection('community_members').doc(memberId).set({
        'id': memberId,
        'communityWalletId': walletId,
        'userId': ownerId,
        'role': 'owner',
        'joinedAt': now,
        'isActive': true,
      });

      print('DEBUG: Community wallet created successfully: $walletId');
      _error = null;
      return true;
    } catch (e) {
      print('DEBUG: Error creating community wallet: $e');
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update member role - direct to Firestore
  Future<bool> updateMemberRole(String memberId, String role) async {
    try {
      await _firestore.collection('community_members').doc(memberId).update({
        'role': role,
        'updated_at': Timestamp.now(),
      });

      print('DEBUG: Member role updated: $memberId -> $role');
      return true;
    } catch (e) {
      print('DEBUG: Error updating member role: $e');
      _error = e.toString();
      return false;
    }
  }

  /// Suspend member - direct to Firestore
  Future<bool> suspendMember(String memberId) async {
    try {
      await _firestore.collection('community_members').doc(memberId).update({
        'isActive': false,
        'updated_at': Timestamp.now(),
      });

      print('DEBUG: Member suspended: $memberId');
      return true;
    } catch (e) {
      print('DEBUG: Error suspending member: $e');
      _error = e.toString();
      return false;
    }
  }

  /// Activate member - direct to Firestore
  Future<bool> activateMember(String memberId) async {
    try {
      await _firestore.collection('community_members').doc(memberId).update({
        'isActive': true,
        'updated_at': Timestamp.now(),
      });

      print('DEBUG: Member activated: $memberId');
      return true;
    } catch (e) {
      print('DEBUG: Error activating member: $e');
      _error = e.toString();
      return false;
    }
  }

  /// Remove member (kick) - direct to Firestore
  Future<bool> removeMember(String memberId) async {
    try {
      // Simply delete the member document
      await _firestore.collection('community_members').doc(memberId).delete();

      print('DEBUG: Member removed: $memberId');
      return true;
    } catch (e) {
      print('DEBUG: Error removing member: $e');
      _error = e.toString();
      return false;
    }
  }

  /// Send invitation - direct to Firestore
  Future<bool> sendInvitation({
    required String walletId,
    required String walletName,
    required String inviterId,
    required String inviteeId,
    required String inviterName,
  }) async {
    try {
      final invitationId = _uuid.v4();
      
      // Create invitation in Firestore
      await _firestore.collection('community_invitations').doc(invitationId).set({
        'id': invitationId,
        'community_wallet_id': walletId,
        'inviter_id': inviterId,
        'invitee_id': inviteeId,
        'status': 'pending',
        'created_at': Timestamp.now(),
        'responded_at': null,
      });

      // Create notification for invitee
      final notificationId = _uuid.v4();
      await _firestore.collection('notifications').doc(notificationId).set({
        'id': notificationId,
        'user_id': inviteeId,
        'type': 'community_invitation',
        'title': 'Lời mời tham gia ví cộng đồng',
        'message': '$inviterName đã mời bạn tham gia ví "$walletName"',
        'data': {
          'invitation_id': invitationId,
          'wallet_id': walletId,
          'wallet_name': walletName,
          'inviter_name': inviterName,
        },
        'is_read': false,
        'created_at': Timestamp.now(),
      });

      print('DEBUG: Invitation sent successfully: $invitationId');
      return true;
    } catch (e) {
      print('DEBUG: Error sending invitation: $e');
      _error = e.toString();
      return false;
    }
  }

  /// Accept invitation - direct to Firestore
  Future<bool> acceptInvitation(String invitationId, String userId) async {
    try {
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
      final walletId = invitationData['community_wallet_id'];

      // Create member record
      final memberId = _uuid.v4();
      await _firestore.collection('community_members').doc(memberId).set({
        'id': memberId,
        'communityWalletId': walletId,
        'userId': userId,
        'role': 'member',
        'joinedAt': Timestamp.now(),
        'isActive': true,
      });

      // Update invitation status
      await _firestore.collection('community_invitations').doc(invitationId).update({
        'status': 'accepted',
        'responded_at': Timestamp.now(),
      });

      print('DEBUG: Invitation accepted successfully: $invitationId');
      return true;
    } catch (e) {
      print('DEBUG: Error accepting invitation: $e');
      _error = e.toString();
      return false;
    }
  }

  /// Get pending invitations for user - real-time
  Stream<List<Map<String, dynamic>>> getPendingInvitationsStream(String userId) {
    return _firestore
        .collection('community_invitations')
        .where('invitee_id', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  /// Search users by unique identifier
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final querySnapshot = await _firestore
          .collection('users')
          .where('unique_identifier', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('unique_identifier', isLessThan: '${query.toLowerCase()}z')
          .limit(10)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('DEBUG: Error searching users: $e');
      return [];
    }
  }

  /// Stop all listeners
  void stopListeners() {
    _userWalletsListener?.cancel();
    _membersListener?.cancel();
    _userWalletsListener = null;
    _membersListener = null;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Helper method to parse DateTime from Firestore data
  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('DEBUG: Error parsing date string: $value, error: $e');
        return DateTime.now();
      }
    } else {
      print('DEBUG: Unknown date type: ${value.runtimeType}, value: $value');
      return DateTime.now();
    }
  }

  @override
  void dispose() {
    stopListeners();
    super.dispose();
  }
}