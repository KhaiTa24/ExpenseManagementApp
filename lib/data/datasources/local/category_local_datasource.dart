import 'package:sqflite/sqflite.dart';
import '../../../core/constants/database_constants.dart';
import '../../models/category_model.dart';
import 'database_helper.dart';

class CategoryLocalDataSource {
  final DatabaseHelper dbHelper;

  CategoryLocalDataSource(this.dbHelper);

  Future<List<CategoryModel>> getCategories({String? userId, String? type}) async {
    final db = await dbHelper.database;
    
    String whereClause = '1=1';
    List<dynamic> whereArgs = [];
    
    if (userId != null) {
      whereClause += ' AND ${DatabaseConstants.columnCategoryUserId} = ?';
      whereArgs.add(userId);
    }
    
    if (type != null) {
      whereClause += ' AND ${DatabaseConstants.columnCategoryType} = ?';
      whereArgs.add(type);
    }
    
    final results = await db.query(
      DatabaseConstants.tableCategories,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: '${DatabaseConstants.columnCategoryIsDefault} DESC, ${DatabaseConstants.columnCategoryName} ASC',
    );
    
    return results.map((json) => CategoryModel.fromJson(json)).toList();
  }

  Future<CategoryModel?> getCategoryById(String id) async {
    final db = await dbHelper.database;
    
    final results = await db.query(
      DatabaseConstants.tableCategories,
      where: '${DatabaseConstants.columnCategoryId} = ?',
      whereArgs: [id],
    );
    
    if (results.isEmpty) return null;
    return CategoryModel.fromJson(results.first);
  }

  Future<String> insertCategory(CategoryModel category) async {
    final db = await dbHelper.database;
    await db.insert(
      DatabaseConstants.tableCategories,
      category.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return category.id;
  }

  Future<void> updateCategory(CategoryModel category) async {
    final db = await dbHelper.database;
    await db.update(
      DatabaseConstants.tableCategories,
      category.toJson(),
      where: '${DatabaseConstants.columnCategoryId} = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(String id) async {
    final db = await dbHelper.database;
    await db.delete(
      DatabaseConstants.tableCategories,
      where: '${DatabaseConstants.columnCategoryId} = ?',
      whereArgs: [id],
    );
  }

  Future<bool> isCategoryNameExists(String name, String type, String userId) async {
    final db = await dbHelper.database;
    
    final results = await db.query(
      DatabaseConstants.tableCategories,
      where: '${DatabaseConstants.columnCategoryName} = ? AND ${DatabaseConstants.columnCategoryType} = ? AND ${DatabaseConstants.columnCategoryUserId} = ?',
      whereArgs: [name, type, userId],
    );
    
    return results.isNotEmpty;
  }

  Future<List<CategoryModel>> getDefaultCategories() async {
    final db = await dbHelper.database;
    
    final results = await db.query(
      DatabaseConstants.tableCategories,
      where: '${DatabaseConstants.columnCategoryIsDefault} = ?',
      whereArgs: [1],
    );
    
    return results.map((json) => CategoryModel.fromJson(json)).toList();
  }
}
