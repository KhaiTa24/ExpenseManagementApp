import '../../repositories/category_repository.dart';

class DeleteCategory {
  final CategoryRepository repository;

  DeleteCategory(this.repository);

  Future<void> call(String id) async {
    return await repository.deleteCategory(id);
  }
}
