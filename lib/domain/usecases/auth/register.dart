import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';

class Register {
  final AuthRepository repository;

  Register(this.repository);

  Future<User> call(String email, String password, String displayName) async {
    return await repository.register(email, password, displayName);
  }
}
