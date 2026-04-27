import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/community_transaction.dart';

class CommunityTransactionProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final List<CommunityTransaction> _transactions = [];
  bool _isLoading = false;
  String? _error;
  
  // Track active listeners to avoid duplicates
  final Set<String> _activeListeners = {};

  List<CommunityTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get transactions for a specific community wallet
  List<CommunityTransaction> getTransactionsForWallet(String walletId) {
    return _transactions.where((t) => t.communityWalletId == walletId).toList();
  }

  // Calculate totals for a wallet
  double getWalletIncome(String walletId) {
    return getTransactionsForWallet(walletId)
        .where((t) => t.isIncome)
        .fold(0.0, (total, t) => total + t.amount);
  }

  double getWalletExpense(String walletId) {
    return getTransactionsForWallet(walletId)
        .where((t) => t.isExpense)
        .fold(0.0, (total, t) => total + t.amount);
  }

  double getWalletBalance(String walletId) {
    return getWalletIncome(walletId) - getWalletExpense(walletId);
  }

  // Start listening to transactions for a community wallet
  void startListeningToWalletTransactions(String walletId) {
    // Remove from active listeners to allow refresh
    _activeListeners.remove(walletId);
    
    // Avoid creating duplicate listeners
    if (_activeListeners.contains(walletId)) {
      return;
    }
    
    _activeListeners.add(walletId);
    
    _firestore
        .collection('community_transactions')
        .where('community_wallet_id', isEqualTo: walletId)
        .orderBy('date', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        try {
          // Remove old transactions for this wallet
          _transactions.removeWhere((t) => t.communityWalletId == walletId);
          
          // Add new transactions
          final newTransactions = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return CommunityTransaction.fromMap(data);
          }).toList();
          
          _transactions.addAll(newTransactions);
          
          // Sort by date
          _transactions.sort((a, b) => b.date.compareTo(a.date));
          
          _error = null;
          notifyListeners();
        } catch (e) {
          _error = 'Lỗi tải giao dịch: $e';
          notifyListeners();
        }
      },
      onError: (error) {
        _error = 'Lỗi kết nối: $error';
        notifyListeners();
      },
    );
  }

  // Add a new community transaction
  Future<void> addTransaction({
    required String communityWalletId,
    required String userId,
    required String userName,
    required String type,
    required double amount,
    required String categoryId,
    required String categoryName,
    required String categoryIcon,
    required String description,
    required DateTime date,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final now = DateTime.now();
      final transaction = CommunityTransaction(
        id: '', // Firestore will generate
        communityWalletId: communityWalletId,
        userId: userId,
        userName: userName,
        type: type,
        amount: amount,
        categoryId: categoryId,
        categoryName: categoryName,
        categoryIcon: categoryIcon,
        description: description,
        date: date,
        createdAt: now,
        updatedAt: now,
      );

      // Add to Firestore
      await _firestore
          .collection('community_transactions')
          .add(transaction.toMap());

      // Update community wallet balance
      await _updateWalletBalance(communityWalletId);

      _error = null;
    } catch (e) {
      _error = 'Lỗi thêm giao dịch: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update community transaction
  Future<void> updateTransaction({
    required String transactionId,
    required String communityWalletId,
    required String type,
    required double amount,
    required String categoryId,
    required String categoryName,
    required String categoryIcon,
    required String description,
    required DateTime date,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestore
          .collection('community_transactions')
          .doc(transactionId)
          .update({
        'type': type,
        'amount': amount,
        'category_id': categoryId,
        'category_name': categoryName,
        'category_icon': categoryIcon,
        'description': description,
        'date': date.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Update community wallet balance
      await _updateWalletBalance(communityWalletId);

      _error = null;
    } catch (e) {
      _error = 'Lỗi cập nhật giao dịch: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete community transaction
  Future<void> deleteTransaction(String communityWalletId, String transactionId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Delete the transaction from Firestore
      await _firestore
          .collection('community_transactions')
          .doc(transactionId)
          .delete();

      // Remove from local list immediately
      _transactions.removeWhere((t) => t.id == transactionId);

      // Try to update wallet balance, but don't fail the whole operation
      try {
        await _updateWalletBalance(communityWalletId);
      } catch (balanceError) {
        // Don't throw error, transaction deletion was successful
      }

      _error = null;
      
    } catch (e) {
      _error = 'Lỗi xóa giao dịch: $e';
      rethrow; // Only re-throw if transaction deletion actually failed
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update wallet balance in Firestore
  Future<void> _updateWalletBalance(String walletId) async {
    try {
      // Check if wallet exists first
      final walletDoc = await _firestore
          .collection('community_wallets')
          .doc(walletId)
          .get();
      
      if (!walletDoc.exists) {
        debugPrint('Ví cộng đồng không tồn tại: $walletId');
        return; // Don't throw error, just return
      }

      final income = getWalletIncome(walletId);
      final expense = getWalletExpense(walletId);
      final balance = income - expense;

      await _firestore
          .collection('community_wallets')
          .doc(walletId)
          .update({
        'balance': balance,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      debugPrint('Cập nhật số dư ví thành công: $walletId, balance: $balance');
    } catch (e) {
      debugPrint('Lỗi cập nhật số dư ví: $e');
      // Don't rethrow - let the caller decide what to do
      throw Exception('Không thể cập nhật số dư ví: $e');
    }
  }

  // Force refresh transactions for a wallet
  void forceRefreshWalletTransactions(String walletId) {
    _activeListeners.remove(walletId);
    startListeningToWalletTransactions(walletId);
  }

  // Clear transactions (when user logs out)
  void clearTransactions() {
    _transactions.clear();
    _activeListeners.clear();
    _error = null;
    notifyListeners();
  }
}