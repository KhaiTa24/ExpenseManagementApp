import '../entities/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> getCategories({String? userId, String? type});
  
  Future<Category?> getCategoryById(String id);
  
  Future<String> addCategory(Category category);
  
  Future<void> updateCategory(Category category);
  
  Future<void> deleteCategory(String id);
  
  Future<List<Category>> getDefaultCategories();
  
  Future<void> initializeDefaultCategories(String userId);
  
  Future<bool> isCategoryNameExists(String name, String type, String userId);
}
