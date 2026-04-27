import 'package:sqflite/sqflite.dart';
import '../../../core/constants/database_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/recurring_model.dart';
import 'database_helper.dart';

abstract class RecurringLocalDataSource {
  Future<List<RecurringModel>> getRecurringTransactions(String userId);
  Future<List<RecurringModel>> getActiveRecurringTransactions(String userId);
  Future<RecurringModel?> getRecurringById(String id);
  Future<void> insertRecurring(RecurringModel recurring);
  Future<void> updateRecurring(RecurringModel recurring);
  Future<void> deleteRecurring(String id);
  Future<void> updateLastProcessedDate(String id, DateTime date);
}

class RecurringLocalDataSourceImpl implements RecurringLocalDataSource {
  final DatabaseHelper databaseHelper;

  RecurringLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<List<RecurringModel>> getRecurringTransactions(String userId) async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.recurringTable,
        where: '${DatabaseConstants.recurringUserId} = ?',
        whereArgs: [userId],
        orderBy: '${DatabaseConstants.recurringCreatedAt} DESC',
      );

      return maps.map((map) => RecurringModel.fromJson(map)).toList();
    } catch (e) {
      throw CacheException('Không thể lấy danh sách giao dịch định kỳ');
    }
  }

  @override
  Future<List<RecurringModel>> getActiveRecurringTransactions(
    String userId,
  ) async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.recurringTable,
        where: '${DatabaseConstants.recurringUserId} = ? AND ${DatabaseConstants.recurringIsActive} = ?',
        whereArgs: [userId, 1],
        orderBy: '${DatabaseConstants.recurringStartDate} ASC',
      );

      return maps.map((map) => RecurringModel.fromJson(map)).toList();
    } catch (e) {
      throw CacheException('Không thể lấy giao dịch định kỳ đang hoạt động');
    }
  }

  @override
  Future<RecurringModel?> getRecurringById(String id) async {
    try {
      final db = await databaseHelper.database;
      final maps = await db.query(
        DatabaseConstants.recurringTable,
        where: '${DatabaseConstants.recurringId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return RecurringModel.fromJson(maps.first);
    } catch (e) {
      throw CacheException('Không thể lấy thông tin giao dịch định kỳ');
    }
  }

  @override
  Future<void> insertRecurring(RecurringModel recurring) async {
    try {
      final db = await databaseHelper.database;
      await db.insert(
        DatabaseConstants.recurringTable,
        recurring.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException('Không thể thêm giao dịch định kỳ');
    }
  }

  @override
  Future<void> updateRecurring(RecurringModel recurring) async {
    try {
      final db = await databaseHelper.database;
      await db.update(
        DatabaseConstants.recurringTable,
        recurring.toJson(),
        where: '${DatabaseConstants.recurringId} = ?',
        whereArgs: [recurring.id],
      );
    } catch (e) {
      throw CacheException('Không thể cập nhật giao dịch định kỳ');
    }
  }

  @override
  Future<void> deleteRecurring(String id) async {
    try {
      final db = await databaseHelper.database;
      await db.delete(
        DatabaseConstants.recurringTable,
        where: '${DatabaseConstants.recurringId} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw CacheException('Không thể xóa giao dịch định kỳ');
    }
  }

  @override
  Future<void> updateLastProcessedDate(String id, DateTime date) async {
    try {
      final db = await databaseHelper.database;
      await db.update(
        DatabaseConstants.recurringTable,
        {
          DatabaseConstants.recurringLastProcessedDate: date.millisecondsSinceEpoch,
        },
        where: '${DatabaseConstants.recurringId} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw CacheException('Không thể cập nhật ngày xử lý');
    }
  }
}
