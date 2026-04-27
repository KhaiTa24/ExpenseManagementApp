import 'package:flutter/foundation.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/usecases/wallet/create_wallet.dart';
import '../../domain/usecases/wallet/update_wallet.dart';
import '../../domain/usecases/wallet/delete_wallet.dart';
import '../../domain/usecases/wallet/get_wallets.dart';

enum WalletLoadingState { initial, loading, loaded, error }

class WalletProvider extends ChangeNotifier {
  final CreateWallet createWallet;
  final UpdateWallet updateWallet;
  final DeleteWallet deleteWallet;
  final GetWallets getWallets;

  WalletProvider({
    required this.createWallet,
    required this.updateWallet,
    required this.deleteWallet,
    required this.getWallets,
  });

  WalletLoadingState _state = WalletLoadingState.initial;
  List<Wallet> _wallets = [];
  String? _errorMessage;

  WalletLoadingState get state => _state;
  List<Wallet> get wallets => _wallets;
  String? get errorMessage => _errorMessage;

  double get totalBalance =>
      _wallets.fold(0, (sum, wallet) => sum + wallet.balance);

  void _setState(WalletLoadingState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _setState(WalletLoadingState.error);
  }

  Future<void> loadWallets({String? userId}) async {
    try {
      _setState(WalletLoadingState.loading);
      _errorMessage = null;

      _wallets = await getWallets(userId: userId);
      _setState(WalletLoadingState.loaded);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<bool> addNewWallet(Wallet wallet) async {
    try {
      _errorMessage = null;
      await createWallet(wallet);
      await loadWallets(userId: wallet.userId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> editWallet(Wallet wallet) async {
    try {
      _errorMessage = null;
      await updateWallet(wallet);
      await loadWallets(userId: wallet.userId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> removeWallet(String id, String userId) async {
    try {
      _errorMessage = null;
      await deleteWallet(id);
      await loadWallets(userId: userId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Wallet? getWalletById(String id) {
    try {
      return _wallets.firstWhere((w) => w.id == id);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
