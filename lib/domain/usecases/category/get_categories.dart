import '../../entities/category.dart';
import '../../repositories/category_repository.dart';

class GetCategories {
  final CategoryRepository repository;

  GetCategories(this.repository);

  Future<List<Category>> call({String? userId, String? type}) async {
    return await repository.getCategories(userId: userId, type: type);
  }
}
