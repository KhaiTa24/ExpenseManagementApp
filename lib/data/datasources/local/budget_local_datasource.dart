import 'package:sqflite/sqflite.dart';
import '../../../core/constants/database_constants.dart';
import '../../models/budget_model.dart';
import 'database_helper.dart';

class BudgetLocalDataSource {
  final DatabaseHelper dbHelper;

  BudgetLocalDataSource(this.dbHelper);

  Future<List<BudgetModel>> getBudgets({
    String? userId,
    String? categoryId,
    int? month,
    int? year,
  }) async {
    final db = await dbHelper.database;
    
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];
    
    if (userId != null) {
      whereClause += ' AND ${DatabaseConstants.columnBudgetUserId} = ?';
      whereArgs.add(userId);
    }
    
    if (categoryId != null) {
      whereClause += ' AND ${DatabaseConstants.columnBudgetCategoryId} = ?';
      whereArgs.add(categoryId);
    }
    
    if (month != null) {
      whereClause += ' AND ${DatabaseConstants.columnBudgetMonth} = ?';
      whereArgs.add(month);
    }
    
    if (year != null) {
      whereClause += ' AND ${DatabaseConstants.columnBudgetYear} = ?';
      whereArgs.add(year);
    }
    
    final results = await db.query(
      DatabaseConstants.tableBudgets,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: '${DatabaseConstants.columnBudgetCreatedAt} DESC',
    );
    
    return results.map((json) => BudgetModel.fromJson(json)).toList();
  }

  Future<BudgetModel?> getBudgetById(String id) async {
    final db = await dbHelper.database;
    
    final results = await db.query(
      DatabaseConstants.tableBudgets,
      where: '${DatabaseConstants.columnBudgetId} = ?',
      whereArgs: [id],
    );
    
    if (results.isEmpty) return null;
    return BudgetModel.fromJson(results.first);
  }

  Future<String> insertBudget(BudgetModel budget) async {
    final db = await dbHelper.database;
    await db.insert(
      DatabaseConstants.tableBudgets,
      budget.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return budget.id;
  }

  Future<void> updateBudget(BudgetModel budget) async {
    final db = await dbHelper.database;
    await db.update(
      DatabaseConstants.tableBudgets,
      budget.toJson(),
      where: '${DatabaseConstants.columnBudgetId} = ?',
      whereArgs: [budget.id],
    );
  }

  Future<void> deleteBudget(String id) async {
    final db = await dbHelper.database;
    await db.delete(
      DatabaseConstants.tableBudgets,
      where: '${DatabaseConstants.columnBudgetId} = ?',
      whereArgs: [id],
    );
  }

  Future<BudgetModel?> getBudgetForCategory({
    required String categoryId,
    required int month,
    required int year,
  }) async {
    final db = await dbHelper.database;
    
    final results = await db.query(
      DatabaseConstants.tableBudgets,
      where: '${DatabaseConstants.columnBudgetCategoryId} = ? AND ${DatabaseConstants.columnBudgetMonth} = ? AND ${DatabaseConstants.columnBudgetYear} = ?',
      whereArgs: [categoryId, month, year],
    );
    
    if (results.isEmpty) return null;
    return BudgetModel.fromJson(results.first);
  }
}
