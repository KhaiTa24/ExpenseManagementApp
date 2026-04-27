import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import '../datasources/local/database_helper.dart';
import '../models/community_wallet_model.dart';
import '../models/community_member_model.dart';
import '../../core/constants/database_constants.dart';
import '../../core/utils/global_refresh_manager.dart';

/// Service để sync real-time community wallet data
class CommunitySyncService {
  static final CommunitySyncService _instance = CommunitySyncService._internal();
  factory CommunitySyncService() => _instance;
  CommunitySyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final Map<String, StreamSubscription> _walletListeners = {};
  final Map<String, StreamSubscription> _memberListeners = {};

  /// Start listening to a community wallet for real-time updates
  Future<void> startListeningToWallet(String walletId, String userId) async {
    // Stop existing listener if any
    await stopListeningToWallet(walletId);

    // Listen to wallet changes
    _walletListeners[walletId] = _firestore
        .collection('community_wallets')
        .doc(walletId)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.exists) {
        await _syncWalletFromFirestore(snapshot.data()!);
        GlobalRefreshManager.triggerWalletRefresh(walletId);
      }
    });

    // Listen to members changes
    _memberListeners[walletId] = _firestore
        .collection('community_members')
        .where('communityWalletId', isEqualTo: walletId)
        .snapshots()
        .listen((snapshot) async {
      await _syncMembersFromFirestore(walletId, snapshot.docs);
      GlobalRefreshManager.triggerWalletRefresh(walletId);
    });
  }

  /// Stop listening to a community wallet
  Future<void> stopListeningToWallet(String walletId) async {
    _walletListeners[walletId]?.cancel();
    _walletListeners.remove(walletId);
    
    _memberListeners[walletId]?.cancel();
    _memberListeners.remove(walletId);
  }

  /// Start listening to all user's community wallets
  Future<void> startListeningToUserWallets(String userId) async {
    try {
      print('DEBUG: Starting to listen to user wallets for: $userId');
      
      // Listen directly to user's membership changes in Firestore
      _listenToUserMembershipChanges(userId);
      
      // Get user's wallets from local database
      final db = await _databaseHelper.database;
      final memberWallets = await db.query(
        DatabaseConstants.communityMembersTable,
        where: '${DatabaseConstants.communityMemberUserId} = ?',
        whereArgs: [userId],
      );

      // Start listening to each wallet
      for (final member in memberWallets) {
        final walletId = member['community_wallet_id'] as String;
        await startListeningToWallet(walletId, userId);
      }
    } catch (e) {
      print('DEBUG: Error starting user wallet listeners: $e');
    }
  }

  /// Listen to user's membership changes in Firestore
  void _listenToUserMembershipChanges(String userId) {
    try {
      _firestore
          .collection('community_members')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .listen((snapshot) async {
        print('DEBUG: User membership changes detected for: $userId');
        
        for (final change in snapshot.docChanges) {
          final memberData = change.doc.data();
          
          if (change.type == DocumentChangeType.removed || 
              (memberData != null && memberData['isActive'] == false)) {
            // Member was removed or deactivated
            print('DEBUG: Member removed/deactivated: ${change.doc.id}');
            
            // Remove from local database
            await _removeMemberFromLocal(change.doc.id);
            
            // Trigger refresh for user's wallets
            GlobalRefreshManager.triggerRefresh('user_wallets_$userId');
            GlobalRefreshManager.triggerRefresh('community_wallets');
          } else if (change.type == DocumentChangeType.added || 
                     change.type == DocumentChangeType.modified) {
            // Member was added or modified
            if (memberData != null) {
              await _syncMemberToLocal(memberData);
              
              // Trigger refresh
              GlobalRefreshManager.triggerRefresh('user_wallets_$userId');
            }
          }
        }
      });
    } catch (e) {
      print('DEBUG: Error listening to user membership changes: $e');
    }
  }

  /// Remove member from local database
  Future<void> _removeMemberFromLocal(String memberId) async {
    try {
      final db = await _databaseHelper.database;
      await db.delete(
        DatabaseConstants.communityMembersTable,
        where: '${DatabaseConstants.communityMemberId} = ?',
        whereArgs: [memberId],
      );
      print('DEBUG: Member $memberId removed from local database');
    } catch (e) {
      print('DEBUG: Error removing member from local: $e');
    }
  }

  /// Sync member to local database
  Future<void> _syncMemberToLocal(Map<String, dynamic> memberData) async {
    try {
      final member = CommunityMemberModel.fromFirestore(memberData);
      final db = await _databaseHelper.database;
      
      await db.insert(
        DatabaseConstants.communityMembersTable,
        member.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      print('DEBUG: Member ${member.id} synced to local database');
    } catch (e) {
      print('DEBUG: Error syncing member to local: $e');
    }
  }

  /// Stop listening to all wallets
  void stopAllListeners() {
    for (final subscription in _walletListeners.values) {
      subscription.cancel();
    }
    _walletListeners.clear();

    for (final subscription in _memberListeners.values) {
      subscription.cancel();
    }
    _memberListeners.clear();
  }

  /// Sync wallet data from Firestore to local database
  Future<void> _syncWalletFromFirestore(Map<String, dynamic> walletData) async {
    try {
      final walletForLocal = {
        DatabaseConstants.communityWalletId: walletData['id'],
        DatabaseConstants.communityWalletName: walletData['name'],
        DatabaseConstants.communityWalletDescription: walletData['description'] ?? '',
        DatabaseConstants.communityWalletOwnerId: walletData['owner_id'],
        DatabaseConstants.communityWalletBalance: (walletData['balance'] ?? 0.0).toDouble(),
        DatabaseConstants.communityWalletIcon: walletData['icon'],
        DatabaseConstants.communityWalletColor: walletData['color'],
        DatabaseConstants.communityWalletCreatedAt: walletData['created_at'] is Timestamp
            ? (walletData['created_at'] as Timestamp).millisecondsSinceEpoch
            : DateTime.now().millisecondsSinceEpoch,
        DatabaseConstants.communityWalletUpdatedAt: DateTime.now().millisecondsSinceEpoch,
      };

      final db = await _databaseHelper.database;
      
      // Check if wallet exists
      final existingWallet = await db.query(
        DatabaseConstants.communityWalletsTable,
        where: '${DatabaseConstants.communityWalletId} = ?',
        whereArgs: [walletData['id']],
      );

      if (existingWallet.isEmpty) {
        await db.insert(DatabaseConstants.communityWalletsTable, walletForLocal);
      } else {
        await db.update(
          DatabaseConstants.communityWalletsTable,
          walletForLocal,
          where: '${DatabaseConstants.communityWalletId} = ?',
          whereArgs: [walletData['id']],
        );
      }
    } catch (e) {
      // Error is not critical
    }
  }

  /// Sync members data from Firestore to local database
  Future<void> _syncMembersFromFirestore(String walletId, List<QueryDocumentSnapshot> memberDocs) async {
    try {
      final db = await _databaseHelper.database;
      
      for (final doc in memberDocs) {
        try {
          final memberData = doc.data() as Map<String, dynamic>;
          final member = CommunityMemberModel.fromFirestore(memberData);
          
          // Check if member exists
          final existingMember = await db.query(
            DatabaseConstants.communityMembersTable,
            where: '${DatabaseConstants.communityMemberId} = ?',
            whereArgs: [member.id],
          );
          
          if (existingMember.isEmpty) {
            await db.insert(DatabaseConstants.communityMembersTable, member.toJson());
          } else {
            await db.update(
              DatabaseConstants.communityMembersTable,
              member.toJson(),
              where: '${DatabaseConstants.communityMemberId} = ?',
              whereArgs: [member.id],
            );
          }
        } catch (e) {
          // Skip invalid member data
        }
      }
    } catch (e) {
      // Error is not critical
    }
  }

  /// Trigger sync for a specific wallet (call this when making changes)
  Future<void> triggerWalletSync(String walletId) async {
    try {
      // Get wallet data and sync to Firestore
      final db = await _databaseHelper.database;
      final walletResult = await db.query(
        DatabaseConstants.communityWalletsTable,
        where: '${DatabaseConstants.communityWalletId} = ?',
        whereArgs: [walletId],
      );

      if (walletResult.isNotEmpty) {
        final wallet = CommunityWalletModel.fromJson(walletResult.first);
        await _syncWalletToFirestore(wallet);
      }

      // Sync members to Firestore
      final membersResult = await db.query(
        DatabaseConstants.communityMembersTable,
        where: '${DatabaseConstants.communityMemberWalletId} = ?',
        whereArgs: [walletId],
      );

      for (final memberData in membersResult) {
        final member = CommunityMemberModel.fromJson(memberData);
        await _syncMemberToFirestore(member);
      }

      // Trigger global refresh
      GlobalRefreshManager.triggerWalletRefresh(walletId);
    } catch (e) {
      // Error is not critical
    }
  }

  /// Sync wallet to Firestore
  Future<void> _syncWalletToFirestore(CommunityWalletModel wallet) async {
    try {
      final walletData = {
        'id': wallet.id,
        'name': wallet.name,
        'description': wallet.description,
        'owner_id': wallet.ownerId,
        'balance': wallet.balance,
        'icon': wallet.icon,
        'color': wallet.color,
        'created_at': Timestamp.fromMillisecondsSinceEpoch(wallet.createdAt.millisecondsSinceEpoch),
        'updated_at': Timestamp.now(),
      };

      await _firestore
          .collection('community_wallets')
          .doc(wallet.id)
          .set(walletData);
    } catch (e) {
      // Error is not critical
    }
  }

  /// Sync member to Firestore
  Future<void> _syncMemberToFirestore(CommunityMemberModel member) async {
    try {
      final memberData = {
        'id': member.id,
        'communityWalletId': member.communityWalletId,
        'userId': member.userId,
        'role': member.role,
        'joinedAt': Timestamp.fromMillisecondsSinceEpoch(member.joinedAt.millisecondsSinceEpoch),
        'isActive': member.isActive,
      };

      await _firestore
          .collection('community_members')
          .doc(member.id)
          .set(memberData);
    } catch (e) {
      // Error is not critical
    }
  }
}