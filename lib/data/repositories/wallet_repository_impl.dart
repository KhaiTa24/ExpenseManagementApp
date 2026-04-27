import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/local/wallet_local_datasource.dart';
import '../models/wallet_model.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletLocalDataSource localDataSource;

  WalletRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Wallet>> getWallets({String? userId}) async {
    if (userId == null) {
      throw Exception('User ID is required');
    }
    return await localDataSource.getWallets(userId);
  }

  @override
  Future<Wallet?> getWalletById(String id) async {
    return await localDataSource.getWalletById(id);
  }

  @override
  Future<String> createWallet(Wallet wallet) async {
    final model = WalletModel.fromEntity(wallet);
    await localDataSource.insertWallet(model);
    return wallet.id;
  }

  @override
  Future<void> updateWallet(Wallet wallet) async {
    final model = WalletModel.fromEntity(wallet);
    await localDataSource.updateWallet(model);
  }

  @override
  Future<void> deleteWallet(String id) async {
    await localDataSource.deleteWallet(id);
  }

  @override
  Future<void> updateBalance(String walletId, double amount) async {
    await localDataSource.updateWalletBalance(walletId, amount);
  }
}
