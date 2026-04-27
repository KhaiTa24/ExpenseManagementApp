import '../entities/community_wallet.dart';
import '../entities/community_member.dart';
import '../entities/user.dart';

abstract class CommunityWalletRepository {
  // Community Wallet operations
  Future<CommunityWallet> createCommunityWallet(CommunityWallet wallet);
  Future<List<CommunityWallet>> getUserCommunityWallets(String userId);
  Future<CommunityWallet?> getCommunityWallet(String walletId);
  Future<CommunityWallet> updateCommunityWallet(CommunityWallet wallet);
  Future<void> deleteCommunityWallet(String walletId);
  
  // Member operations
  Future<CommunityMember> addMember(CommunityMember member);
  Future<List<CommunityMember>> getWalletMembers(String walletId);
  Future<CommunityMember?> getMember(String memberId);
  Future<void> removeMember(String memberId);
  Future<void> updateMemberRole(String memberId, String role);
  Future<void> updateMemberStatus(String memberId, bool isActive);
  
  // Sync operations
  Future<void> syncAllMembersToFirestore(String walletId);
  Future<void> syncExistingWalletToFirestore(String walletId);
  
  // User search
  Future<User?> findUserByIdentifier(String identifier);
  Future<List<User>> searchUsers(String query);
  
  // Balance operations
  Future<void> updateBalance(String walletId, double amount);
}