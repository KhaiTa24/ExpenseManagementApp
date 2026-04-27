import '../../../core/errors/exceptions.dart';
import '../../repositories/category_repository.dart';

class ValidateCategory {
  final CategoryRepository repository;

  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int maxCategoriesPerUser = 50;

  ValidateCategory(this.repository);

  Future<void> call({
    required String name,
    required String type,
    required String userId,
    String? categoryId,
  }) async {
    // Validate name length
    if (name.trim().isEmpty) {
      throw ValidationException('Vui lòng nhập tên danh mục');
    }

    if (name.length < minNameLength) {
      throw ValidationException('Tên danh mục phải có ít nhất $minNameLength ký tự');
    }

    if (name.length > maxNameLength) {
      throw ValidationException('Tên danh mục không quá $maxNameLength ký tự');
    }

    // Validate type
    if (type != 'income' && type != 'expense') {
      throw ValidationException('Loại danh mục không hợp lệ');
    }

    // Check duplicate name in same type
    final categories = await repository.getCategories(userId: userId);
    final duplicates = categories.where(
      (c) => c.name.toLowerCase() == name.toLowerCase() && 
             c.type == type &&
             c.id != categoryId,
    );

    if (duplicates.isNotEmpty) {
      throw ValidationException('Tên danh mục đã tồn tại');
    }

    // Check max categories limit (only for new categories)
    if (categoryId == null && categories.length >= maxCategoriesPerUser) {
      throw ValidationException('Đã đạt giới hạn $maxCategoriesPerUser danh mục');
    }
  }
}
