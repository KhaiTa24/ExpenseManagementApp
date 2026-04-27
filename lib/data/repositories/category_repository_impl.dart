import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/local/category_local_datasource.dart';
import '../models/category_model.dart';
import 'package:uuid/uuid.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryLocalDataSource localDataSource;

  CategoryRepositoryImpl(this.localDataSource);

  @override
  Future<List<Category>> getCategories({String? userId, String? type}) async {
    return await localDataSource.getCategories(userId: userId, type: type);
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    return await localDataSource.getCategoryById(id);
  }

  @override
  Future<String> addCategory(Category category) async {
    final model = CategoryModel.fromEntity(category);
    return await localDataSource.insertCategory(model);
  }

  @override
  Future<void> updateCategory(Category category) async {
    final model = CategoryModel.fromEntity(category);
    await localDataSource.updateCategory(model);
  }

  @override
  Future<void> deleteCategory(String id) async {
    await localDataSource.deleteCategory(id);
  }

  @override
  Future<List<Category>> getDefaultCategories() async {
    return await localDataSource.getDefaultCategories();
  }

  @override
  Future<void> initializeDefaultCategories(String userId) async {
    final uuid = const Uuid();
    final now = DateTime.now();

    // Income Categories
    final incomeCategories = [
      CategoryModel(
        id: uuid.v4(),
        userId: userId,
        name: 'Lương',
        icon: 'wallet',
        color: '#4CAF50',
        type: 'income',
        isDefault: true,
        createdAt: now,
      ),
      CategoryModel(
        id: uuid.v4(),
        userId: userId,
        name: 'Thưởng',
        icon: 'card_giftcard',
        color: '#FF9800',
        type: 'income',
        isDefault: true,
        createdAt: now,
      ),
      CategoryModel(
        id: uuid.v4(),
        userId: userId,
        name: 'Đầu tư',
        icon: 'trending_up',
        color: '#2196F3',
        type: 'income',
        isDefault: true,
        createdAt: now,
      ),
      CategoryModel(
        id: uuid.v4(),
        userId: userId,
        name: 'Thu nhập khác',
        icon: 'attach_money',
        color: '#00BCD4',
        type: 'income',
        isDefault: true,
        createdAt: now,
      ),
    ];

    // Expense Categories
    final expenseCategories = [
      CategoryModel(
        id: uuid.v4(),
        userId: userId,
        name: 'Ăn uống',
        icon: 'restaurant',
        color: '#FF5722',
        type: 'expense',
        isDefault: true,
        createdAt: now,
      ),
      CategoryModel(
        id: uuid.v4(),
        userId: userId,
        name: 'Mua sắm',
        icon: 'shopping_cart',
        color: '#E91E63',
        type: 'expense',
        isDefault: true,
        createdAt: now,
      ),
      CategoryModel(
        id: uuid.v4(),
        userId: userId,
        name: 'Đi lại',
        icon: 'directions_car',
        color: '#9C27B0',
        type: 'expense',
        isDefault: true,
        createdAt: now,
      ),
      CategoryModel(
        id: uuid.v4(),
        userId: userId,
        name: 'Hóa đơn',
        icon: 'receipt',
        color: '#F44336',
        type: 'expense',
        isDefault: true,
        createdAt: now,
      ),
      CategoryModel(
        id: uuid.v4(),
        userId: userId,
        name: 'Giải trí',
        icon: 'movie',
        color: '#673AB7',
        type: 'expense',
        isDefault: true,
        createdAt: now,
      ),
      CategoryModel(
        id: uuid.v4(),
        userId: userId,
        name: 'Y tế',
        icon: 'local_hospital',
        color: '#009688',
        type: 'expense',
        isDefault: true,
        createdAt: now,
      ),
      CategoryModel(
        id: uuid.v4(),
        userId: userId,
        name: 'Giáo dục',
        icon: 'school',
        color: '#3F51B5',
        type: 'expense',
        isDefault: true,
        createdAt: now,
      ),
      CategoryModel(
        id: uuid.v4(),
        userId: userId,
        name: 'Chi phí khác',
        icon: 'more_horiz',
        color: '#795548',
        type: 'expense',
        isDefault: true,
        createdAt: now,
      ),
    ];

    // Insert all default categories
    for (var category in [...incomeCategories, ...expenseCategories]) {
      try {
        // Check if category with same name and type already exists
        final exists = await localDataSource.isCategoryNameExists(
          category.name, 
          category.type, 
          userId
        );
        
        if (!exists) {
          await localDataSource.insertCategory(category);
          print('Inserted category: ${category.name}');
        } else {
          print('Category already exists: ${category.name}');
        }
      } catch (e) {
        print('Error inserting category ${category.name}: $e');
        // Continue with other categories
      }
    }
  }

  @override
  Future<bool> isCategoryNameExists(String name, String type, String userId) async {
    return await localDataSource.isCategoryNameExists(name, type, userId);
  }
}
