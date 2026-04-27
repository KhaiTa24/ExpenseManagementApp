import '../../repositories/auth_repository.dart';

class VerifyBiometric {
  final AuthRepository repository;

  VerifyBiometric(this.repository);

  Future<bool> call() async {
    return await repository.verifyBiometric();
  }
}
