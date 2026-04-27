import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';

class LoginWithEmail {
  final AuthRepository repository;

  LoginWithEmail(this.repository);

  Future<User> call(String email, String password) async {
    return await repository.loginWithEmail(email, password);
  }
}
