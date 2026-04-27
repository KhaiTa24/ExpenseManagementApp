import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> loginWithEmail(String email, String password);
  
  Future<User> loginWithGoogle();
  
  Future<User> register(String email, String password, String displayName);
  
  Future<void> logout();
  
  Future<void> resetPassword(String email);
  
  Future<User?> getCurrentUser();
  
  Future<bool> isLoggedIn();
  
  Future<bool> verifyBiometric();
  
  Future<void> savePin(String pin);
  
  Future<bool> verifyPin(String pin);
  
  Future<void> enableBiometric();
  
  Future<void> disableBiometric();
  
  Future<bool> isBiometricEnabled();
}
