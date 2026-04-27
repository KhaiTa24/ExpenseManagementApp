import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/errors/exceptions.dart';

abstract class FirebaseAuthDataSource {
  Future<User?> signInWithEmail(String email, String password);
  Future<User?> signInWithGoogle();
  Future<User?> registerWithEmail(
      String email, String password, String displayName);
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
  User? getCurrentUser();
  Stream<User?> get authStateChanges;
}

class FirebaseAuthDataSourceImpl implements FirebaseAuthDataSource {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthDataSourceImpl({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn;

  @override
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      // For invalid-credential error, provide helpful message
      if (e.code == 'invalid-credential') {
        throw const ServerException(
          'Email hoặc mật khẩu không đúng. Nếu bạn đã đăng ký bằng Google, vui lòng dùng "Đăng nhập với Google"',
        );
      }

      throw ServerException(_getAuthErrorMessage(e.code));
    } catch (e) {
      if (e is ServerException) rethrow;
      throw const ServerException('Đăng nhập thất bại');
    }
  }

  @override
  Future<User?> signInWithGoogle() async {
    try {
      // Try to sign out first, but don't fail if it errors (e.g., no Google Play Services)
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        // Ignore sign out errors - device might not have Google Play Services
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Check if we have the required tokens
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw const ServerException('Không thể lấy token từ Google');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase errors
      String message = 'Đăng nhập Google thất bại';
      switch (e.code) {
        case 'account-exists-with-different-credential':
          // This happens when user registered with email/password first
          // Firebase automatically links the accounts if they have the same email
          message =
              'Email này đã được đăng ký. Vui lòng đăng nhập bằng email/password trước, sau đó link Google account trong Settings';
          break;
        case 'invalid-credential':
          message = 'Thông tin xác thực không hợp lệ';
          break;
        case 'operation-not-allowed':
          message = 'Đăng nhập Google chưa được kích hoạt trong Firebase';
          break;
        case 'user-disabled':
          message = 'Tài khoản đã bị vô hiệu hóa';
          break;
        case 'network-request-failed':
          message = 'Lỗi kết nối mạng. Vui lòng thử lại';
          break;
      }
      throw ServerException('$message (${e.code})');
    } catch (e) {
      if (e.toString().contains('PlatformException')) {
        if (e.toString().contains('Google Play Store') ||
            e.toString().contains('SERVICE_INVALID') ||
            e.toString().contains('GooglePlayServicesUtil')) {
          throw const ServerException(
            'Thiết bị cần cài đặt Google Play Services để đăng nhập với Google',
          );
        }
        throw const ServerException(
          'Lỗi cấu hình Google Sign In. Kiểm tra SHA-1 certificate và Firebase settings',
        );
      }
      throw ServerException('Đăng nhập Google thất bại: ${e.toString()}');
    }
  }

  @override
  Future<User?> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.updateDisplayName(displayName);
      await credential.user?.reload();

      return _firebaseAuth.currentUser;
    } on FirebaseAuthException catch (e) {
      throw ServerException(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw ServerException('Đăng ký thất bại');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw ServerException('Đăng xuất thất bại');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw ServerException(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw ServerException('Gửi email thất bại');
    }
  }

  @override
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email không tồn tại';
      case 'wrong-password':
        return 'Mật khẩu không đúng';
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không đúng';
      case 'email-already-in-use':
        return 'Email đã được sử dụng';
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'weak-password':
        return 'Mật khẩu quá yếu';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa';
      case 'too-many-requests':
        return 'Quá nhiều yêu cầu, vui lòng thử lại sau';
      default:
        return 'Đã xảy ra lỗi ($code)';
    }
  }
}
