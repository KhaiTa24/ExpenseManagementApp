import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/remote/firebase_auth_datasource.dart';
import '../datasources/remote/firestore_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource firebaseAuthDataSource;
  final FirestoreDataSource firestoreDataSource;
  final FlutterSecureStorage secureStorage;
  final LocalAuthentication localAuth;

  static const String _pinKey = 'user_pin';
  static const String _biometricKey = 'biometric_enabled';

  AuthRepositoryImpl({
    required this.firebaseAuthDataSource,
    required this.firestoreDataSource,
    required this.secureStorage,
    required this.localAuth,
  });

  @override
  Future<User> loginWithEmail(String email, String password) async {
    final firebaseUser = await firebaseAuthDataSource.signInWithEmail(
      email,
      password,
    );

    if (firebaseUser == null) {
      throw Exception('Đăng nhập thất bại');
    }

    return User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? '',
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
    );
  }

  @override
  Future<User> loginWithGoogle() async {
    final firebaseUser = await firebaseAuthDataSource.signInWithGoogle();

    if (firebaseUser == null) {
      throw Exception('Đăng nhập Google thất bại');
    }

    // Create user in Firestore if not exists
    final userData = {
      'id': firebaseUser.uid,
      'email': firebaseUser.email ?? '',
      'display_name': firebaseUser.displayName ?? '',
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };

    final existingUser = await firestoreDataSource.getUser(firebaseUser.uid);
    if (existingUser == null) {
      await firestoreDataSource.createUser(userData);
    }

    return User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? '',
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
    );
  }

  @override
  Future<User> register(String email, String password, String displayName) async {
    final firebaseUser = await firebaseAuthDataSource.registerWithEmail(
      email,
      password,
      displayName,
    );

    if (firebaseUser == null) {
      throw Exception('Đăng ký thất bại');
    }

    // Create user in Firestore
    final userData = {
      'id': firebaseUser.uid,
      'email': email,
      'display_name': displayName,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };

    await firestoreDataSource.createUser(userData);

    return User(
      id: firebaseUser.uid,
      email: email,
      displayName: displayName,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> logout() async {
    await firebaseAuthDataSource.signOut();
  }

  @override
  Future<void> resetPassword(String email) async {
    await firebaseAuthDataSource.sendPasswordResetEmail(email);
  }

  @override
  Future<User?> getCurrentUser() async {
    final firebaseUser = firebaseAuthDataSource.getCurrentUser();
    if (firebaseUser == null) return null;

    return User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? '',
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
    );
  }

  @override
  Future<bool> isLoggedIn() async {
    final user = firebaseAuthDataSource.getCurrentUser();
    return user != null;
  }

  @override
  Future<bool> verifyBiometric() async {
    try {
      final canCheckBiometrics = await localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) return false;

      return await localAuth.authenticate(
        localizedReason: 'Xác thực để truy cập ứng dụng',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> savePin(String pin) async {
    await secureStorage.write(key: _pinKey, value: pin);
  }

  @override
  Future<bool> verifyPin(String pin) async {
    final savedPin = await secureStorage.read(key: _pinKey);
    return savedPin == pin;
  }

  @override
  Future<void> enableBiometric() async {
    await secureStorage.write(key: _biometricKey, value: 'true');
  }

  @override
  Future<void> disableBiometric() async {
    await secureStorage.delete(key: _biometricKey);
  }

  @override
  Future<bool> isBiometricEnabled() async {
    final value = await secureStorage.read(key: _biometricKey);
    return value == 'true';
  }
}
