import 'package:sqflite/sqflite.dart';
import '../../../core/constants/database_constants.dart';
import '../../models/transaction_model.dart';
import 'database_helper.dart';

class TransactionLocalDataSource {
  final DatabaseHelper dbHelper;

  TransactionLocalDataSource(this.dbHelper);

  Future<List<TransactionModel>> getTransactions({
    String? userId,
    String? categoryId,
    DateTime? startDate,
    DateTime? endDate,
    String? type,
    int? limit,
    int? offset,
  }) async {
    final db = await dbHelper.database;
    
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];
    
    if (userId != null) {
      whereClause += ' AND ${DatabaseConstants.columnTransactionUserId} = ?';
      whereArgs.add(userId);
    }
    
    if (categoryId != null) {
      whereClause += ' AND ${DatabaseConstants.columnTransactionCategoryId} = ?';
      whereArgs.add(categoryId);
    }
    
    if (startDate != null) {
      whereClause += ' AND ${DatabaseConstants.columnTransactionDate} >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }
    
    if (endDate != null) {
      whereClause += ' AND ${DatabaseConstants.columnTransactionDate} <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }
    
    if (type != null) {
      whereClause += ' AND ${DatabaseConstants.columnTransactionType} = ?';
      whereArgs.add(type);
    }
    
    final results = await db.query(
      DatabaseConstants.tableTransactions,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: '${DatabaseConstants.columnTransactionDate} DESC',
      limit: limit,
      offset: offset,
    );
    
    return results.map((json) => TransactionModel.fromJson(json)).toList();
  }

  Future<TransactionModel?> getTransactionById(String id) async {
    final db = await dbHelper.database;
    
    final results = await db.query(
      DatabaseConstants.tableTransactions,
      where: '${DatabaseConstants.columnTransactionId} = ?',
      whereArgs: [id],
    );
    
    if (results.isEmpty) return null;
    return TransactionModel.fromJson(results.first);
  }

  Future<String> insertTransaction(TransactionModel transaction) async {
    final db = await dbHelper.database;
    await db.insert(
      DatabaseConstants.tableTransactions,
      transaction.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return transaction.id;
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    final db = await dbHelper.database;
    await db.update(
      DatabaseConstants.tableTransactions,
      transaction.toJson(),
      where: '${DatabaseConstants.columnTransactionId} = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await dbHelper.database;
    await db.delete(
      DatabaseConstants.tableTransactions,
      where: '${DatabaseConstants.columnTransactionId} = ?',
      whereArgs: [id],
    );
  }

  Future<double> getTotalAmount({
    String? userId,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await dbHelper.database;
    
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];
    
    if (userId != null) {
      whereClause += ' AND ${DatabaseConstants.columnTransactionUserId} = ?';
      whereArgs.add(userId);
    }
    
    if (type != null) {
      whereClause += ' AND ${DatabaseConstants.columnTransactionType} = ?';
      whereArgs.add(type);
    }
    
    if (startDate != null) {
      whereClause += ' AND ${DatabaseConstants.columnTransactionDate} >= ?';
      whereArgs.add(startDate.millisecondsSinceEpoch);
    }
    
    if (endDate != null) {
      whereClause += ' AND ${DatabaseConstants.columnTransactionDate} <= ?';
      whereArgs.add(endDate.millisecondsSinceEpoch);
    }
    
    final result = await db.rawQuery(
      'SELECT SUM(${DatabaseConstants.columnTransactionAmount}) as total FROM ${DatabaseConstants.tableTransactions} WHERE $whereClause',
      whereArgs,
    );
    
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<TransactionModel>> searchTransactions(String query, {String? userId}) async {
    final db = await dbHelper.database;
    
    String whereClause = '${DatabaseConstants.columnTransactionDescription} LIKE ?';
    List<dynamic> whereArgs = ['%$query%'];
    
    if (userId != null) {
      whereClause += ' AND ${DatabaseConstants.columnTransactionUserId} = ?';
      whereArgs.add(userId);
    }
    
    final results = await db.query(
      DatabaseConstants.tableTransactions,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: '${DatabaseConstants.columnTransactionDate} DESC',
    );
    
    return results.map((json) => TransactionModel.fromJson(json)).toList();
  }
}
