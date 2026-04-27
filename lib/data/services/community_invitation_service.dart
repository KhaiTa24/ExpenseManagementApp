import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../repositories/community_wallet_repository_impl.dart';
import '../datasources/local/database_helper.dart';
import '../../core/constants/database_constants.dart';
import '../../domain/entities/community_member.dart';
import 'notification_service.dart';

class CommunityInvitationService {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  late final CommunityWalletRepositoryImpl _repository;

  CommunityInvitationService() {
    _repository = CommunityWalletRepositoryImpl(_databaseHelper);
  }

  // Send invitation
  Future<CommunityInvitationModel> sendInvitation({
    required String communityWalletId,
    required String inviterId,
    required String inviteeId,
    required String communityWalletName,
    required String inviterName,
  }) async {
    final invitation = CommunityInvitationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      communityWalletId: communityWalletId,
      inviterId: inviterId,
      inviteeId: inviteeId,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    // Save to local database
    final db = await _databaseHelper.database;
    await db.insert(
      DatabaseConstants.communityInvitationsTable,
      invitation.toJson(),
    );

    // Save to Firestore with consistent field names
    try {
      await _firestore
          .collection('community_invitations')
          .doc(invitation.id)
          .set({
        'id': invitation.id,
        'communityWalletId': invitation.communityWalletId,
        'inviterId': invitation.inviterId,
        'inviteeId': invitation.inviteeId,
        'status': invitation.status,
        'createdAt': Timestamp.fromDate(invitation.createdAt),
      });
    } catch (e) {
      // Firestore error is not critical for local operation
    }

    // Create notification for invitee
    try {
      await _notificationService.createCommunityInvitationNotification(
        inviteeId: inviteeId,
        inviterName: inviterName,
        communityWalletName: communityWalletName,
        communityWalletId: communityWalletId,
        invitationId: invitation.id,
      );
    } catch (e) {
      // Notification error is not critical
    }

    return invitation;
  }

  // Get pending invitations for user
  Future<List<CommunityInvitationModel>> getPendingInvitations(
      String userId) async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConstants.communityInvitationsTable,
      where:
          '${DatabaseConstants.invitationInviteeId} = ? AND ${DatabaseConstants.invitationStatus} = ?',
      whereArgs: [userId, 'pending'],
      orderBy: '${DatabaseConstants.invitationCreatedAt} DESC',
    );

    return List.generate(maps.length, (i) {
      return CommunityInvitationModel.fromJson(maps[i]);
    });
  }

  // Get all invitations for user (including accepted/rejected)
  Future<List<CommunityInvitationModel>> getAllInvitations(
      String userId) async {
    final db = await _databaseHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseConstants.communityInvitationsTable,
      where: '${DatabaseConstants.invitationInviteeId} = ?',
      whereArgs: [userId],
      orderBy: '${DatabaseConstants.invitationCreatedAt} DESC',
    );

    return List.generate(maps.length, (i) {
      return CommunityInvitationModel.fromJson(maps[i]);
    });
  }

  // Accept invitation
  Future<void> acceptInvitation(String invitationId, String userId) async {
    final db = await _databaseHelper.database;

    // Get invitation details
    final invitationMaps = await db.query(
      DatabaseConstants.communityInvitationsTable,
      where: '${DatabaseConstants.invitationId} = ?',
      whereArgs: [invitationId],
    );

    if (invitationMaps.isEmpty) {
      throw Exception('Invitation not found');
    }

    final invitation = CommunityInvitationModel.fromJson(invitationMaps.first);

    // Check if user is already a member
    final existingMembers = await db.query(
      DatabaseConstants.communityMembersTable,
      where:
          '${DatabaseConstants.communityMemberWalletId} = ? AND ${DatabaseConstants.communityMemberUserId} = ?',
      whereArgs: [invitation.communityWalletId, userId],
    );

    // Update invitation status to accepted
    await db.update(
      DatabaseConstants.communityInvitationsTable,
      {
        DatabaseConstants.invitationStatus: 'accepted',
        DatabaseConstants.invitationRespondedAt:
            DateTime.now().millisecondsSinceEpoch,
      },
      where: '${DatabaseConstants.invitationId} = ?',
      whereArgs: [invitationId],
    );

    // Add user as member if not already exists
    if (existingMembers.isEmpty) {
      final member = CommunityMember(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        communityWalletId: invitation.communityWalletId,
        userId: userId,
        role: 'member',
        joinedAt: DateTime.now(),
      );

      await _repository.addMember(member);
    }

    // IMPORTANT: Sync community wallet from Firestore to local database
    await _syncCommunityWalletFromFirestore(invitation.communityWalletId);

    // Update Firestore
    try {
      await _firestore
          .collection('community_invitations')
          .doc(invitationId)
          .update({
        'status': 'accepted',
        'respondedAt': DateTime.now(),
      });
    } catch (e) {
      // Firestore error is not critical for local operation
    }
  }

  // Sync community wallet from Firestore to local database
  Future<void> _syncCommunityWalletFromFirestore(String walletId) async {
    try {
      // Get wallet from Firestore
      final walletDoc = await _firestore
          .collection('community_wallets')
          .doc(walletId)
          .get();

      if (walletDoc.exists) {
        final walletData = walletDoc.data()!;
        
        // Convert Firestore data to local database format
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
        };

        final db = await _databaseHelper.database;
        
        // Check if wallet already exists
        final existingWallet = await db.query(
          DatabaseConstants.communityWalletsTable,
          where: '${DatabaseConstants.communityWalletId} = ?',
          whereArgs: [walletId],
        );

        if (existingWallet.isEmpty) {
          // Insert new wallet
          await db.insert(
            DatabaseConstants.communityWalletsTable,
            walletForLocal,
          );
        } else {
          // Update existing wallet
          await db.update(
            DatabaseConstants.communityWalletsTable,
            walletForLocal,
            where: '${DatabaseConstants.communityWalletId} = ?',
            whereArgs: [walletId],
          );
        }
      }
    } catch (e) {
      // Error syncing wallet from Firestore
    }
  }

  // Reject invitation
  Future<void> rejectInvitation(String invitationId) async {
    final db = await _databaseHelper.database;

    // Update invitation status
    await db.update(
      DatabaseConstants.communityInvitationsTable,
      {
        DatabaseConstants.invitationStatus: 'rejected',
        DatabaseConstants.invitationRespondedAt:
            DateTime.now().millisecondsSinceEpoch,
      },
      where: '${DatabaseConstants.invitationId} = ?',
      whereArgs: [invitationId],
    );

    // Update Firestore
    await _firestore
        .collection('community_invitations')
        .doc(invitationId)
        .update({
      'status': 'rejected',
      'respondedAt': DateTime.now(),
    });
  }

  // Get invitations stream for real-time updates
  Stream<List<CommunityInvitationModel>> getPendingInvitationsStream(
      String userId) {
    return _firestore
        .collection('community_invitations')
        .where('inviteeId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CommunityInvitationModel.fromFirestore(doc.data());
      }).toList();
    });
  }

  // Check if invitation already exists
  Future<bool> hasExistingInvitation(
      String communityWalletId, String inviteeId) async {
    final db = await _databaseHelper.database;
    final result = await db.query(
      DatabaseConstants.communityInvitationsTable,
      where:
          '${DatabaseConstants.invitationCommunityWalletId} = ? AND ${DatabaseConstants.invitationInviteeId} = ? AND ${DatabaseConstants.invitationStatus} = ?',
      whereArgs: [communityWalletId, inviteeId, 'pending'],
    );

    return result.isNotEmpty;
  }

  // Helper method to delete existing invitations (for testing)
  Future<void> deleteExistingInvitations(
      String communityWalletId, String inviteeId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      DatabaseConstants.communityInvitationsTable,
      where:
          '${DatabaseConstants.invitationCommunityWalletId} = ? AND ${DatabaseConstants.invitationInviteeId} = ?',
      whereArgs: [communityWalletId, inviteeId],
    );
  }

  // Sync invitation from Firestore to local database
  Future<void> syncInvitationToLocal(
      CommunityInvitationModel invitation) async {
    final db = await _databaseHelper.database;
    try {
      await db.insert(
        DatabaseConstants.communityInvitationsTable,
        invitation.toJson(),
      );
    } catch (e) {
      // If invitation already exists, update it
      if (e.toString().contains('UNIQUE constraint failed')) {
        await db.update(
          DatabaseConstants.communityInvitationsTable,
          invitation.toJson(),
          where: '${DatabaseConstants.invitationId} = ?',
          whereArgs: [invitation.id],
        );
      } else {
        rethrow;
      }
    }
  }

  // Get invitations from Firestore (for syncing)
  Future<List<CommunityInvitationModel>> getInvitationsFromFirestore(
      String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('community_invitations')
          .where('inviteeId', isEqualTo: userId)
          .get();

      return querySnapshot.docs.map((doc) {
        return CommunityInvitationModel.fromFirestore(doc.data());
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Fix pending invitations for users who are already members
  Future<void> fixPendingInvitationsForExistingMembers(String userId) async {
    try {
      final db = await _databaseHelper.database;
      final pendingInvitations = await getPendingInvitations(userId);

      for (final invitation in pendingInvitations) {
        // Check if user is already a member of this community wallet
        final existingMembers = await db.query(
          DatabaseConstants.communityMembersTable,
          where:
              '${DatabaseConstants.communityMemberWalletId} = ? AND ${DatabaseConstants.communityMemberUserId} = ?',
          whereArgs: [invitation.communityWalletId, userId],
        );

        if (existingMembers.isNotEmpty) {
          // Update invitation to accepted
          await db.update(
            DatabaseConstants.communityInvitationsTable,
            {
              DatabaseConstants.invitationStatus: 'accepted',
              DatabaseConstants.invitationRespondedAt:
                  DateTime.now().millisecondsSinceEpoch,
            },
            where: '${DatabaseConstants.invitationId} = ?',
            whereArgs: [invitation.id],
          );

          // Also update Firestore
          try {
            await _firestore
                .collection('community_invitations')
                .doc(invitation.id)
                .update({
              'status': 'accepted',
              'respondedAt': DateTime.now(),
            });
          } catch (e) {
            // Firestore error is not critical
          }
        }
      }
    } catch (e) {
      // Error is not critical for this operation
    }
  }
}
