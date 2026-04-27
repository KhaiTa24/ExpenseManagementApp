import '../entities/wallet.dart';

abstract class WalletRepository {
  Future<List<Wallet>> getWallets({String? userId});
  
  Future<Wallet?> getWalletById(String id);
  
  Future<String> createWallet(Wallet wallet);
  
  Future<void> updateWallet(Wallet wallet);
  
  Future<void> deleteWallet(String id);
  
  Future<void> updateBalance(String walletId, double amount);
}
