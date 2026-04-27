import 'package:sqflite/sqflite.dart';
import '../../../core/constants/database_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/wallet_model.dart';
import 'database_helper.dart';

abstract class WalletLocalDataSource {
  Future<List<WalletModel>> getWallets(String userId);
  Future<WalletModel?> getWalletById(String id);
  Future<void> insertWallet(WalletModel wallet);
  Future<void> updateWallet(WalletModel wallet);
  Future<void> deleteWallet(String id);
  Future<void> updateWalletBalance(String id, double newBalance);
}

class WalletLocalDataSourceImpl implements WalletLocalDataSource {
  final DatabaseHelper databaseHelper;

  WalletLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<List<WalletModel>> getWallets(String userId) async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.walletsTable,
        where: '${DatabaseConstants.walletUserId} = ?',
        whereArgs: [userId],
        orderBy: '${DatabaseConstants.walletCreatedAt} DESC',
      );

      return maps.map((map) => WalletModel.fromJson(map)).toList();
    } catch (e) {
      throw CacheException('Không thể lấy danh sách ví');
    }
  }

  @override
  Future<WalletModel?> getWalletById(String id) async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.walletsTable,
        where: '${DatabaseConstants.walletId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return WalletModel.fromJson(maps.first);
    } catch (e) {
      throw CacheException('Không thể lấy thông tin ví');
    }
  }

  @override
  Future<void> insertWallet(WalletModel wallet) async {
    try {
      final db = await databaseHelper.database;
      await db.insert(
        DatabaseConstants.walletsTable,
        wallet.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException('Không thể thêm ví');
    }
  }

  @override
  Future<void> updateWallet(WalletModel wallet) async {
    try {
      final db = await databaseHelper.database;
      await db.update(
        DatabaseConstants.walletsTable,
        wallet.toJson(),
        where: '${DatabaseConstants.walletId} = ?',
        whereArgs: [wallet.id],
      );
    } catch (e) {
      throw CacheException('Không thể cập nhật ví');
    }
  }

  @override
  Future<void> deleteWallet(String id) async {
    try {
      final db = await databaseHelper.database;
      await db.delete(
        DatabaseConstants.walletsTable,
        where: '${DatabaseConstants.walletId} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw CacheException('Không thể xóa ví');
    }
  }

  @override
  Future<void> updateWalletBalance(String id, double newBalance) async {
    try {
      final db = await databaseHelper.database;
      await db.update(
        DatabaseConstants.walletsTable,
        {
          DatabaseConstants.walletBalance: newBalance,
          DatabaseConstants.walletUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        },
        where: '${DatabaseConstants.walletId} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw CacheException('Không thể cập nhật số dư ví');
    }
  }
}
