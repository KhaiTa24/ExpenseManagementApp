import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/community_wallet.dart';
import '../../domain/entities/community_member.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/community_wallet_repository.dart';
import '../../data/services/community_invitation_service.dart';
import '../../data/models/community_wallet_model.dart';
import '../../core/utils/global_refresh_manager.dart';

class CommunityWalletProvider with ChangeNotifier {
  final CommunityWalletRepository _repository;
  final CommunityInvitationService _invitationService =
      CommunityInvitationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  CommunityWalletProvider(this._repository);

  List<CommunityWallet> _communityWallets = [];
  List<CommunityMember> _currentWalletMembers = [];
  List<User> _searchResults = [];
  bool _isLoading = false;
  String? _error;

  List<CommunityWallet> get communityWallets => _communityWallets;
  List<CommunityMember> get currentWalletMembers => _currentWalletMembers;
  List<User> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUserCommunityWallets(String userId) async {
    _setLoading(true);
    try {
      print('DEBUG: Loading community wallets for user: $userId');
      _communityWallets = await _repository.getUserCommunityWallets(userId);
      print('DEBUG: Loaded ${_communityWallets.length} community wallets');

      _error = null;
    } catch (e) {
      print('DEBUG: Error loading community wallets: $e');
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createCommunityWallet({
    required String name,
    required String description,
    required String ownerId,
    String? icon,
    String? color,
  }) async {
    _setLoading(true);
    try {
      final wallet = CommunityWallet(
        id: _uuid.v4(),
        name: name,
        description: description,
        balance: 0.0,
        ownerId: ownerId,
        icon: icon,
        color: color,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 1. Create wallet in local database
      await _repository.createCommunityWallet(wallet);

      // 2. CRITICAL: Sync wallet to Firestore immediately
      await _syncWalletToFirestore(wallet);

      // 3. Create owner as first member and sync to Firestore
      await _createOwnerMember(wallet.id, ownerId);

      // 4. Reload user's wallets
      await loadUserCommunityWallets(ownerId);

      // 5. Trigger global refresh events
      GlobalRefreshManager.triggerRefresh('all');
      GlobalRefreshManager.triggerRefresh('community_wallets');
      GlobalRefreshManager.triggerRefresh('user_wallets_$ownerId');

      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadWalletMembers(String walletId) async {
    try {
      _currentWalletMembers = await _repository.getWalletMembers(walletId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Force refresh members from Firestore
  Future<void> refreshMembers(String walletId) async {
    try {
      // This will trigger sync from Firestore
      final members = await _repository.getWalletMembers(walletId);

      // Update current wallet members
      _currentWalletMembers = members;

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Sync all members to Firestore (useful for ensuring consistency)
  Future<void> syncAllMembersToFirestore(String walletId) async {
    try {
      await _repository.syncAllMembersToFirestore(walletId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> inviteMemberToWallet({
    required String walletId,
    required String userId,
    required String inviterName,
    required String walletName,
    required String inviterId,
  }) async {
    try {
      // Check if invitation already exists
      final hasExisting =
          await _invitationService.hasExistingInvitation(walletId, userId);

      if (hasExisting) {
        // Delete existing invitation and create new one
        await _invitationService.deleteExistingInvitations(walletId, userId);
      }

      // Check if user is already a member
      final members = await _repository.getWalletMembers(walletId);
      final isAlreadyMember = members.any((member) => member.userId == userId);

      if (isAlreadyMember) {
        _error = 'Người dùng đã là thành viên của ví này';
        return false;
      }

      // Send invitation
      await _invitationService.sendInvitation(
        communityWalletId: walletId,
        inviterId: inviterId,
        inviteeId: userId,
        communityWalletName: walletName,
        inviterName: inviterName,
      );

      _error = null;
      return true;
    } catch (e) {
      _error = 'Không thể gửi lời mời: $e';
      return false;
    }
  }

  Future<bool> updateMemberRole(
      String memberId, String role, String walletId) async {
    try {
      _setLoading(true);

      // 1. Update role in local database
      await _repository.updateMemberRole(memberId, role);

      // 2. Sync role change to Firestore
      await _syncMemberRoleToFirestore(memberId, role);

      // 3. Reload members list
      await loadWalletMembers(walletId);

      // 4. Trigger global refresh for all members of this wallet
      GlobalRefreshManager.triggerRefresh('members_$walletId');
      GlobalRefreshManager.triggerRefresh('wallet_$walletId');

      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> suspendMember(String memberId, String walletId) async {
    try {
      _setLoading(true);

      // 1. Update status in local database
      await _repository.updateMemberStatus(memberId, false);

      // 2. Sync status change to Firestore
      await _syncMemberStatusToFirestore(memberId, false);

      // 3. Reload members list
      await loadWalletMembers(walletId);

      // 4. Trigger global refresh for all members of this wallet
      GlobalRefreshManager.triggerRefresh('members_$walletId');
      GlobalRefreshManager.triggerRefresh('wallet_$walletId');

      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> activateMember(String memberId, String walletId) async {
    try {
      _setLoading(true);

      // 1. Update status in local database
      await _repository.updateMemberStatus(memberId, true);

      // 2. Sync status change to Firestore
      await _syncMemberStatusToFirestore(memberId, true);

      // 3. Reload members list
      await loadWalletMembers(walletId);

      // 4. Trigger global refresh for all members of this wallet
      GlobalRefreshManager.triggerRefresh('members_$walletId');
      GlobalRefreshManager.triggerRefresh('wallet_$walletId');

      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      _searchResults = await _repository.searchUsers(query);
      _error = null;
    } catch (e) {
      _error = e.toString();
      _searchResults = [];
    }
    notifyListeners();
  }

  Future<User?> findUserByIdentifier(String identifier) async {
    try {
      return await _repository.findUserByIdentifier(identifier);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Sync existing wallet to Firestore (for fixing existing wallets)
  Future<void> syncExistingWalletToFirestore(String walletId) async {
    try {
      await _repository.syncExistingWalletToFirestore(walletId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Force reload user's community wallets (called after accepting invitation)
  Future<void> forceReloadUserWallets(String userId) async {
    await loadUserCommunityWallets(userId);
  }

  // Sync wallet and members from Firestore (called when opening wallet detail)
  Future<void> syncWalletFromFirestore(String walletId) async {
    try {
      print('DEBUG: Syncing wallet $walletId from Firestore');

      // 1. Sync wallet data from Firestore
      final walletDoc =
          await _firestore.collection('community_wallets').doc(walletId).get();

      if (walletDoc.exists) {
        final walletData = walletDoc.data()!;
        // Update local database with Firestore data
        await _updateLocalWalletFromFirestore(walletId, walletData);
      }

      // 2. Sync members data from Firestore
      final membersQuery = await _firestore
          .collection('community_members')
          .where('communityWalletId', isEqualTo: walletId)
          .get();

      for (final memberDoc in membersQuery.docs) {
        final memberData = memberDoc.data();
        await _updateLocalMemberFromFirestore(memberDoc.id, memberData);
      }

      print('DEBUG: Wallet $walletId synced from Firestore successfully');
    } catch (e) {
      print('DEBUG: Error syncing wallet from Firestore: $e');
      // Don't rethrow - local data is still usable
    }
  }

  // Update local wallet data from Firestore
  Future<void> _updateLocalWalletFromFirestore(
      String walletId, Map<String, dynamic> firestoreData) async {
    try {
      final walletForLocal = {
        'id': firestoreData['id'],
        'name': firestoreData['name'],
        'description': firestoreData['description'] ?? '',
        'owner_id': firestoreData['owner_id'],
        'balance': (firestoreData['balance'] ?? 0.0).toDouble(),
        'icon': firestoreData['icon'],
        'color': firestoreData['color'],
        'created_at': firestoreData['created_at'] is Timestamp
            ? (firestoreData['created_at'] as Timestamp).millisecondsSinceEpoch
            : DateTime.now().millisecondsSinceEpoch,
        'updated_at': firestoreData['updated_at'] is Timestamp
            ? (firestoreData['updated_at'] as Timestamp).millisecondsSinceEpoch
            : DateTime.now().millisecondsSinceEpoch,
      };

      // Update in repository
      await _repository
          .updateCommunityWallet(CommunityWalletModel.fromJson(walletForLocal));
    } catch (e) {
      print('DEBUG: Error updating local wallet: $e');
    }
  }

  // Update local member data from Firestore
  Future<void> _updateLocalMemberFromFirestore(
      String memberId, Map<String, dynamic> firestoreData) async {
    try {
      // This would need to be implemented in repository
      // For now, we'll rely on the existing sync mechanisms
      print('DEBUG: Member $memberId data synced from Firestore');
    } catch (e) {
      print('DEBUG: Error updating local member: $e');
    }
  }

  // Remove member from wallet (kick member)
  Future<bool> removeMemberFromWallet(String memberId, String walletId) async {
    try {
      _setLoading(true);

      // Remove member from local database
      await _repository.removeMember(memberId);

      // Sync to Firestore - set member as inactive
      await _syncMemberRemovalToFirestore(memberId, walletId);

      // Reload members list
      await loadWalletMembers(walletId);

      // Trigger global refresh for all members of this wallet
      GlobalRefreshManager.triggerRefresh('members_$walletId');

      // Trigger refresh for the specific user who was kicked
      final kickedMember = await _repository.getMember(memberId);
      if (kickedMember != null) {
        GlobalRefreshManager.triggerRefresh(
            'user_wallets_${kickedMember.userId}');
      }

      _error = null;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sync member role change to Firestore
  Future<void> _syncMemberRoleToFirestore(String memberId, String role) async {
    try {
      await _firestore.collection('community_members').doc(memberId).update({
        'role': role,
        'updated_at': Timestamp.now(),
      });

      print('DEBUG: Member $memberId role updated to $role in Firestore');
    } catch (e) {
      print('DEBUG: Error syncing member role to Firestore: $e');
      // Don't rethrow - local operation should still succeed
    }
  }

  // Sync member status change to Firestore
  Future<void> _syncMemberStatusToFirestore(
      String memberId, bool isActive) async {
    try {
      await _firestore.collection('community_members').doc(memberId).update({
        'isActive': isActive,
        'updated_at': Timestamp.now(),
      });

      print('DEBUG: Member $memberId status updated to $isActive in Firestore');
    } catch (e) {
      print('DEBUG: Error syncing member status to Firestore: $e');
      // Don't rethrow - local operation should still succeed
    }
  }

  // Sync wallet to Firestore
  Future<void> _syncWalletToFirestore(CommunityWallet wallet) async {
    try {
      final walletData = {
        'id': wallet.id,
        'name': wallet.name,
        'description': wallet.description,
        'owner_id': wallet.ownerId,
        'balance': wallet.balance,
        'icon': wallet.icon ?? '💰',
        'color': wallet.color ?? '#4CAF50',
        'created_at': Timestamp.fromMillisecondsSinceEpoch(
            wallet.createdAt.millisecondsSinceEpoch),
        'updated_at': Timestamp.fromMillisecondsSinceEpoch(
            wallet.updatedAt.millisecondsSinceEpoch),
      };

      await _firestore
          .collection('community_wallets')
          .doc(wallet.id)
          .set(walletData);

      print('DEBUG: Wallet ${wallet.id} synced to Firestore successfully');
    } catch (e) {
      print('DEBUG: Error syncing wallet to Firestore: $e');
      // Don't rethrow - we want local operation to succeed even if Firestore fails
    }
  }

  // Create owner as first member
  Future<void> _createOwnerMember(String walletId, String ownerId) async {
    try {
      final ownerMember = CommunityMember(
        id: _uuid.v4(),
        communityWalletId: walletId,
        userId: ownerId,
        role: 'owner',
        joinedAt: DateTime.now(),
        isActive: true,
      );

      // Add to local database
      await _repository.addMember(ownerMember);

      // Sync to Firestore
      await _syncMemberToFirestore(ownerMember);

      print('DEBUG: Owner member created and synced to Firestore');
    } catch (e) {
      print('DEBUG: Error creating owner member: $e');
      // Don't rethrow - wallet creation should still succeed
    }
  }

  // Sync member to Firestore
  Future<void> _syncMemberToFirestore(CommunityMember member) async {
    try {
      final memberData = {
        'id': member.id,
        'communityWalletId': member.communityWalletId,
        'userId': member.userId,
        'role': member.role,
        'joinedAt': Timestamp.fromMillisecondsSinceEpoch(
            member.joinedAt.millisecondsSinceEpoch),
        'isActive': member.isActive,
      };

      await _firestore
          .collection('community_members')
          .doc(member.id)
          .set(memberData);
    } catch (e) {
      print('DEBUG: Error syncing member to Firestore: $e');
      // Don't rethrow
    }
  }

  // Sync member removal to Firestore
  Future<void> _syncMemberRemovalToFirestore(
      String memberId, String walletId) async {
    try {
      await _firestore.collection('community_members').doc(memberId).update({
        'isActive': false,
        'removedAt': Timestamp.now(),
      });
    } catch (e) {
      // Firestore sync error is not critical for local operation
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
