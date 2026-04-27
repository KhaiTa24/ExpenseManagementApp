import '../../entities/wallet.dart';
import '../../repositories/wallet_repository.dart';

class UpdateWallet {
  final WalletRepository repository;

  UpdateWallet(this.repository);

  Future<void> call(Wallet wallet) async {
    return await repository.updateWallet(wallet);
  }
}
