import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/community_wallet.dart';
import '../../domain/entities/community_member.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/community_wallet_repository.dart';
import '../models/community_wallet_model.dart';
import '../models/community_member_model.dart';
import '../models/user_model.dart';
import '../datasources/local/database_helper.dart';
import '../services/firestore_user_service.dart';
import '../../core/constants/database_constants.dart';

class CommunityWalletRepositoryImpl implements CommunityWalletRepository {
  final DatabaseHelper _databaseHelper;
  final FirestoreUserService _firestoreUserService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  CommunityWalletRepositoryImpl(this._databaseHelper) 
      : _firestoreUserService = FirestoreUserService();

  @override
  Future<CommunityWallet> createCommunityWallet(CommunityWallet wallet) async {
    final db = await _databaseHelper.database;
    final walletModel = CommunityWalletModel.fromEntity(wallet);

    // Save to local database
    await db.insert(
        DatabaseConstants.communityWalletsTable, walletModel.toJson());

    // Thêm owner làm member đầu tiên
    final ownerMember = CommunityMemberModel(
      id: _uuid.v4(),
      communityWalletId: wallet.id,
      userId: wallet.ownerId,
      role: 'owner',
      joinedAt: DateTime.now(),
    );

    await db.insert(
        DatabaseConstants.communityMembersTable, ownerMember.toJson());

    // IMPORTANT: Sync wallet to Firestore
    await _syncWalletToFirestore(wallet);

    return wallet;
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
        'icon': wallet.icon,
        'color': wallet.color,
        'created_at': Timestamp.fromMillisecondsSinceEpoch(
            wallet.createdAt.millisecondsSinceEpoch),
        'updated_at': Timestamp.fromMillisecondsSinceEpoch(
            DateTime.now().millisecondsSinceEpoch),
      };

      await _firestore
          .collection('community_wallets')
          .doc(wallet.id)
          .set(walletData);
          
    } catch (e) {
      // Don't rethrow - we want local operation to succeed even if Firestore fails
    }
  }

  // Sync existing wallet to Firestore (for fixing existing wallets)
  Future<void> syncExistingWalletToFirestore(String walletId) async {
    try {
      final wallet = await getCommunityWallet(walletId);
      if (wallet != null) {
        await _syncWalletToFirestore(wallet);
      }
    } catch (e) {
      // Error syncing existing wallet
    }
  }

  @override
  Future<List<CommunityWallet>> getUserCommunityWallets(String userId) async {
    final db = await _databaseHelper.database;

    // Get wallets where user is a member (without is_active check for now)
    final result = await db.rawQuery('''
      SELECT cw.* FROM ${DatabaseConstants.communityWalletsTable} cw
      INNER JOIN ${DatabaseConstants.communityMembersTable} cm ON cw.${DatabaseConstants.communityWalletId} = cm.${DatabaseConstants.communityMemberWalletId}
      WHERE cm.${DatabaseConstants.communityMemberUserId} = ?
      ORDER BY cw.${DatabaseConstants.communityWalletCreatedAt} DESC
    ''', [userId]);

    return result.map((json) => CommunityWalletModel.fromJson(json)).toList();
  }

  @override
  Future<CommunityWallet?> getCommunityWallet(String walletId) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      DatabaseConstants.communityWalletsTable,
      where: '${DatabaseConstants.communityWalletId} = ?',
      whereArgs: [walletId],
    );

    if (result.isEmpty) return null;
    return CommunityWalletModel.fromJson(result.first);
  }

  @override
  Future<CommunityWallet> updateCommunityWallet(CommunityWallet wallet) async {
    final db = await _databaseHelper.database;
    final walletModel = CommunityWalletModel.fromEntity(wallet);

    await db.update(
      DatabaseConstants.communityWalletsTable,
      walletModel.toJson(),
      where: '${DatabaseConstants.communityWalletId} = ?',
      whereArgs: [wallet.id],
    );

    return wallet;
  }

  @override
  Future<void> deleteCommunityWallet(String walletId) async {
    final db = await _databaseHelper.database;

    await db.transaction((txn) async {
      // Xóa tất cả members
      await txn.delete(
        DatabaseConstants.communityMembersTable,
        where: '${DatabaseConstants.communityMemberWalletId} = ?',
        whereArgs: [walletId],
      );

      // Xóa wallet
      await txn.delete(
        DatabaseConstants.communityWalletsTable,
        where: '${DatabaseConstants.communityWalletId} = ?',
        whereArgs: [walletId],
      );
    });
  }

  @override
  Future<CommunityMember> addMember(CommunityMember member) async {
    try {
      // 1. Add to local database first
      final db = await _databaseHelper.database;
      final memberModel = CommunityMemberModel.fromEntity(member);
      await db.insert(
          DatabaseConstants.communityMembersTable, memberModel.toJson());
      
      // 2. Sync to Firestore
      await _syncMemberToFirestore(member);
      
      return member;
    } catch (e) {
      rethrow;
    }
  }

  // Sync a single member to Firestore
  Future<void> _syncMemberToFirestore(CommunityMember member) async {
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
      // Don't rethrow - we want local operation to succeed even if Firestore fails
    }
  }

  // Sync all members of a wallet to Firestore (useful for ensuring consistency)
  Future<void> syncAllMembersToFirestore(String walletId) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.query(
        DatabaseConstants.communityMembersTable,
        where: '${DatabaseConstants.communityMemberWalletId} = ?',
        whereArgs: [walletId],
      );

      for (final memberData in result) {
        try {
          final member = CommunityMemberModel.fromJson(memberData);
          await _syncMemberToFirestore(member);
        } catch (e) {
          // Continue with other members if one fails
        }
      }
    } catch (e) {
      // Error is not critical for this operation
    }
  }

  @override
  Future<List<CommunityMember>> getWalletMembers(String walletId) async {
    final db = await _databaseHelper.database;
    
    // Sync members from Firestore first
    await _syncMembersFromFirestore(walletId);
    
    final result = await db.query(
      DatabaseConstants.communityMembersTable,
      where: '${DatabaseConstants.communityMemberWalletId} = ?',
      whereArgs: [walletId],
      orderBy: '${DatabaseConstants.communityMemberJoinedAt} ASC',
    );
    
    final List<CommunityMember> members = [];
    for (final row in result) {
      try {
        final member = CommunityMemberModel.fromJson(row);
        members.add(member);
      } catch (e) {
        // Skip invalid member data
      }
    }

    return members;
  }

  // Sync members from Firestore to local database
  Future<void> _syncMembersFromFirestore(String walletId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('community_members')
          .where('communityWalletId', isEqualTo: walletId)
          .get();

      final db = await _databaseHelper.database;
      
      for (final doc in querySnapshot.docs) {
        try {
          final memberData = doc.data();
          final member = CommunityMemberModel.fromFirestore(memberData);
          
          // Check if member already exists in local database
          final existingMembers = await db.query(
            DatabaseConstants.communityMembersTable,
            where: '${DatabaseConstants.communityMemberId} = ?',
            whereArgs: [member.id],
          );
          
          if (existingMembers.isEmpty) {
            // Insert new member
            await db.insert(
              DatabaseConstants.communityMembersTable,
              member.toJson(),
            );
          } else {
            // Update existing member
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
      // Error is not critical for this operation
    }
  }

  @override
  Future<CommunityMember?> getMember(String memberId) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.query(
        DatabaseConstants.communityMembersTable,
        where: '${DatabaseConstants.communityMemberId} = ?',
        whereArgs: [memberId],
      );

      if (result.isEmpty) return null;
      return CommunityMemberModel.fromJson(result.first);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> removeMember(String memberId) async {
    try {
      // 1. Remove from local database
      final db = await _databaseHelper.database;
      await db.delete(
        DatabaseConstants.communityMembersTable,
        where: '${DatabaseConstants.communityMemberId} = ?',
        whereArgs: [memberId],
      );
      
      // 2. Remove from Firestore
      await _firestore
          .collection('community_members')
          .doc(memberId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateMemberRole(String memberId, String role) async {
    try {
      // 1. Update local database
      final db = await _databaseHelper.database;
      await db.update(
        DatabaseConstants.communityMembersTable,
        {DatabaseConstants.communityMemberRole: role},
        where: '${DatabaseConstants.communityMemberId} = ?',
        whereArgs: [memberId],
      );
      
      // 2. Update Firestore
      await _firestore
          .collection('community_members')
          .doc(memberId)
          .update({'role': role});
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateMemberStatus(String memberId, bool isActive) async {
    final db = await _databaseHelper.database;
    await db.update(
      DatabaseConstants.communityMembersTable,
      {DatabaseConstants.communityMemberIsActive: isActive ? 1 : 0},
      where: '${DatabaseConstants.communityMemberId} = ?',
      whereArgs: [memberId],
    );
  }

  @override
  Future<User?> findUserByIdentifier(String identifier) async {
    try {
      // Tìm trong Firestore trước
      return await _firestoreUserService.findUserByIdentifier(identifier);
    } catch (e) {
      // Nếu lỗi Firestore, tìm trong local database
      try {
        final db = await _databaseHelper.database;
        final result = await db.query(
          DatabaseConstants.tableUsers,
          where: '${DatabaseConstants.columnUserUniqueIdentifier} = ? OR ${DatabaseConstants.columnUserEmail} = ?',
          whereArgs: [identifier, identifier],
        );

        if (result.isEmpty) return null;
        return UserModel.fromJson(result.first);
      } catch (localError) {
        return null;
      }
    }
  }

  @override
  Future<List<User>> searchUsers(String query) async {
    try {
      // Tìm kiếm trong Firestore
      return await _firestoreUserService.searchUsers(query);
    } catch (e) {
      // Nếu lỗi Firestore, trả về danh sách rỗng
      return [];
    }
  }

  @override
  Future<void> updateBalance(String walletId, double amount) async {
    final db = await _databaseHelper.database;
    await db.rawUpdate('''
      UPDATE ${DatabaseConstants.communityWalletsTable} 
      SET ${DatabaseConstants.communityWalletBalance} = ${DatabaseConstants.communityWalletBalance} + ?, 
          ${DatabaseConstants.communityWalletUpdatedAt} = ?
      WHERE ${DatabaseConstants.communityWalletId} = ?
    ''', [amount, DateTime.now().millisecondsSinceEpoch, walletId]);
  }
}
