import 'package:flutter/foundation.dart' hide Category;
import '../../domain/entities/category.dart';
import '../../domain/usecases/category/add_category.dart';
import '../../domain/usecases/category/update_category.dart';
import '../../domain/usecases/category/delete_category.dart';
import '../../domain/usecases/category/get_categories.dart';
import '../../domain/usecases/category/initialize_default_categories.dart';
import '../../domain/usecases/validation/validate_category.dart';
import '../../domain/usecases/sync/sync_from_cloud.dart';

enum CategoryLoadingState { initial, loading, loaded, error }

class CategoryProvider extends ChangeNotifier {
  final AddCategory addCategory;
  final UpdateCategory updateCategory;
  final DeleteCategory deleteCategory;
  final GetCategories getCategories;
  final InitializeDefaultCategories initializeDefaultCategories;
  final ValidateCategory validateCategory;
  final SyncFromCloud syncFromCloud;

  CategoryProvider({
    required this.addCategory,
    required this.updateCategory,
    required this.deleteCategory,
    required this.getCategories,
    required this.initializeDefaultCategories,
    required this.validateCategory,
    required this.syncFromCloud,
  });

  CategoryLoadingState _state = CategoryLoadingState.initial;
  List<Category> _categories = [];
  String? _errorMessage;

  CategoryLoadingState get state => _state;
  List<Category> get categories => _categories;
  String? get errorMessage => _errorMessage;

  List<Category> get incomeCategories =>
      _categories.where((c) => c.type == 'income').toList();

  List<Category> get expenseCategories =>
      _categories.where((c) => c.type == 'expense').toList();

  void _setState(CategoryLoadingState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _setState(CategoryLoadingState.error);
  }

  Future<void> loadCategories({String? userId}) async {
    try {
      print('Loading categories for user: $userId');
      _setState(CategoryLoadingState.loading);
      _errorMessage = null;

      _categories = await getCategories(userId: userId);

      // Remove duplicates based on name and type
      final uniqueCategories = <Category>[];
      final seen = <String>{};

      for (final category in _categories) {
        final key = '${category.name}_${category.type}_${category.userId}';
        if (!seen.contains(key)) {
          seen.add(key);
          uniqueCategories.add(category);
        }
      }

      if (uniqueCategories.length != _categories.length) {
        print(
            'Removed ${_categories.length - uniqueCategories.length} duplicate categories');
        _categories = uniqueCategories;
      }

      _setState(CategoryLoadingState.loaded);
    } catch (e) {
      print('Error loading categories: $e');
      _setError(e.toString());
    }
  }

  Future<bool> addNewCategory(Category category) async {
    try {
      _errorMessage = null;

      await validateCategory(
        name: category.name,
        type: category.type,
        userId: category.userId,
      );

      await addCategory(category);
      await loadCategories(userId: category.userId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  /// Add category during restore - bypasses validation and handles duplicates
  Future<bool> restoreCategory(Category category) async {
    try {
      _errorMessage = null;

      // Try to add category directly without validation
      await addCategory(category);
      return true;
    } catch (e) {
      // If category already exists, that's OK during restore
      if (e.toString().contains('đã tồn tại') ||
          e.toString().contains('already exists') ||
          e.toString().contains('UNIQUE constraint')) {
        return true; // Consider it successful
      }

      // For other errors, log but don't fail the entire restore
      return false;
    }
  }

  Future<bool> editCategory(Category category) async {
    try {
      _errorMessage = null;

      await validateCategory(
        name: category.name,
        type: category.type,
        userId: category.userId,
        categoryId: category.id,
      );

      await updateCategory(category);
      await loadCategories(userId: category.userId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> removeCategory(String id, String userId) async {
    try {
      _errorMessage = null;
      await deleteCategory(id);
      await loadCategories(userId: userId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<void> initializeDefaults(String userId) async {
    try {
      print('Checking if default categories exist for user: $userId');

      // Check if user already has categories
      await loadCategories(userId: userId);
      if (_categories.isNotEmpty) {
        print(
            'User already has ${_categories.length} categories, skipping initialization');
        return;
      }

      print(
          'No categories found, initializing default categories for user: $userId');
      await initializeDefaultCategories(userId);
      await initializeDefaultCategories(userId);
      await loadCategories(userId: userId);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> syncCategoriesFromCloud() async {
    try {
      _setState(CategoryLoadingState.loading);
      _errorMessage = null;

      await syncFromCloud();

      // Reload categories after sync
      _categories = await getCategories();
      _setState(CategoryLoadingState.loaded);
    } catch (e) {
      _setError('Lỗi đồng bộ từ cloud: ${e.toString()}');
    }
  }

  Category? getCategoryById(String id) {
    try {
      final category = _categories.firstWhere((c) => c.id == id);
      return category;
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
