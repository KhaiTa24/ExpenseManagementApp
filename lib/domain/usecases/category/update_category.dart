import '../../entities/category.dart';
import '../../repositories/category_repository.dart';

class UpdateCategory {
  final CategoryRepository repository;

  UpdateCategory(this.repository);

  Future<void> call(Category category) async {
    return await repository.updateCategory(category);
  }
}
