import 'dart:async';

/// Global refresh manager để trigger refresh across multiple screens
class GlobalRefreshManager {
  static final StreamController<String> _refreshController = 
      StreamController<String>.broadcast();
  
  /// Stream để listen for refresh events
  static Stream<String> get refreshStream => _refreshController.stream;
  
  /// Trigger refresh for all community wallet screens
  static void triggerRefresh([String? walletId]) {
    _refreshController.add(walletId ?? 'all');
  }
  
  /// Trigger refresh for specific wallet
  static void triggerWalletRefresh(String walletId) {
    _refreshController.add(walletId);
  }
  
  /// Dispose the controller (call this when app is closing)
  static void dispose() {
    _refreshController.close();
  }
}