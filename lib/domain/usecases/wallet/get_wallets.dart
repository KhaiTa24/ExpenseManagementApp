import '../../entities/wallet.dart';
import '../../repositories/wallet_repository.dart';

class GetWallets {
  final WalletRepository repository;

  GetWallets(this.repository);

  Future<List<Wallet>> call({String? userId}) async {
    return await repository.getWallets(userId: userId);
  }
}
