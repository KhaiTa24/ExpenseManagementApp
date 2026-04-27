import '../../repositories/wallet_repository.dart';

class DeleteWallet {
  final WalletRepository repository;

  DeleteWallet(this.repository);

  Future<void> call(String id) async {
    return await repository.deleteWallet(id);
  }
}
