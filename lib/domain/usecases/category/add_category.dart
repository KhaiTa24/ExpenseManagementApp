import '../../entities/category.dart';
import '../../repositories/category_repository.dart';

class AddCategory {
  final CategoryRepository repository;

  AddCategory(this.repository);

  Future<String> call(Category category) async {
    // Check if category name already exists
    final exists = await repository.isCategoryNameExists(
      category.name,
      category.type,
      category.userId,
    );
    
    if (exists) {
      throw Exception('Tên danh mục đã tồn tại');
    }
    
    return await repository.addCategory(category);
  }
}
