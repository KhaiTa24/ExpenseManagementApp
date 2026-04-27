import '../../entities/wallet.dart';
import '../../repositories/wallet_repository.dart';

class CreateWallet {
  final WalletRepository repository;

  CreateWallet(this.repository);

  Future<String> call(Wallet wallet) async {
    return await repository.createWallet(wallet);
  }
}
