import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../domain/entities/user.dart';
import '../../domain/usecases/auth/login_with_email.dart';
import '../../domain/usecases/auth/login_with_google.dart';
import '../../domain/usecases/auth/register.dart';
import '../../domain/usecases/auth/logout.dart';
import '../../domain/usecases/auth/verify_biometric.dart';
import '../../domain/usecases/validation/validate_auth.dart';
import '../../data/services/firestore_user_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final LoginWithEmail loginWithEmail;
  final LoginWithGoogle loginWithGoogle;
  final Register register;
  final Logout logout;
  final VerifyBiometric verifyBiometric;
  final ValidateAuth validateAuth;
  final FirestoreUserService _firestoreUserService;

  AuthProvider({
    required this.loginWithEmail,
    required this.loginWithGoogle,
    required this.register,
    required this.logout,
    required this.verifyBiometric,
    required this.validateAuth,
  }) : _firestoreUserService = FirestoreUserService();

  AuthState _state = AuthState.initial;
  User? _currentUser;
  String? _errorMessage;

  AuthState get state => _state;
  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated;

  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _setState(AuthState.error);
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      _setState(AuthState.loading);
      _errorMessage = null;

      await validateAuth.validateEmail(email);
      await validateAuth.validatePassword(password);

      _currentUser = await loginWithEmail(email, password);
      
      // Tự động tạo unique identifier nếu chưa có
      if (_currentUser != null && _currentUser!.uniqueIdentifier == null) {
        final autoIdentifier = _generateUniqueIdentifierFromEmail(_currentUser!.email);
        await updateUniqueIdentifier(autoIdentifier);
      } else if (_currentUser != null) {
        // Lưu user vào Firestore
        await _firestoreUserService.createOrUpdateUser(_currentUser!);
      }
      
      _setState(AuthState.authenticated);
      
      // Save login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
    } catch (e) {
      // Check if this is a Google-only account trying to login with password
      if (e.toString().contains('wrong-password') || 
          e.toString().contains('user-not-found')) {
        _setError('Email hoặc mật khẩu không đúng. Nếu bạn đã đăng ký bằng Google, vui lòng dùng "Đăng nhập với Google"');
      } else {
        _setError(e.toString());
      }
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      _setState(AuthState.loading);
      _errorMessage = null;

      _currentUser = await loginWithGoogle();
      
      // Tự động tạo unique identifier nếu chưa có
      if (_currentUser != null && _currentUser!.uniqueIdentifier == null) {
        final autoIdentifier = _generateUniqueIdentifierFromEmail(_currentUser!.email);
        await updateUniqueIdentifier(autoIdentifier);
      } else if (_currentUser != null) {
        // Lưu user vào Firestore
        await _firestoreUserService.createOrUpdateUser(_currentUser!);
      }
      
      _setState(AuthState.authenticated);
      
      // Save login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> registerUser(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      _setState(AuthState.loading);
      _errorMessage = null;

      await validateAuth.validateEmail(email);
      await validateAuth.validatePassword(password);
      await validateAuth.validateDisplayName(displayName);

      _currentUser = await register(email, password, displayName);
      
      // Tự động tạo unique identifier từ email
      if (_currentUser != null) {
        final autoIdentifier = _generateUniqueIdentifierFromEmail(email);
        await updateUniqueIdentifier(autoIdentifier);
      }
      
      _setState(AuthState.authenticated);
      
      // Save login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      _setState(AuthState.loading);
      await logout();
      _currentUser = null;
      _setState(AuthState.unauthenticated);
      
      // Clear login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', false);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<bool> authenticateWithBiometric() async {
    try {
      return await verifyBiometric();
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadCurrentUser() async {
    try {
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        // Tải user từ Firestore trước
        User? firestoreUser;
        try {
          firestoreUser = await _firestoreUserService.getUserById(firebaseUser.uid);
        } catch (e) {
          // Ignore Firestore errors, will create new user
        }
        
        if (firestoreUser != null) {
          _currentUser = firestoreUser;
          
          // Nếu user tồn tại nhưng chưa có unique_identifier, tạo mới
          if (_currentUser!.uniqueIdentifier == null && _currentUser!.email.isNotEmpty) {
            final autoIdentifier = _generateUniqueIdentifierFromEmail(_currentUser!.email);
            await updateUniqueIdentifier(autoIdentifier);
          }
        } else {
          // Nếu chưa có trong Firestore, tạo mới
          _currentUser = User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            displayName: firebaseUser.displayName ?? 'User',
            uniqueIdentifier: null,
            createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
          );
          
          // Tự động tạo unique identifier và lưu vào Firestore
          if (_currentUser!.email.isNotEmpty) {
            final autoIdentifier = _generateUniqueIdentifierFromEmail(_currentUser!.email);
            await updateUniqueIdentifier(autoIdentifier);
          }
        }
        
        _setState(AuthState.authenticated);
      } else {
        _setState(AuthState.unauthenticated);
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<bool> updateUniqueIdentifier(String identifier) async {
    try {
      if (_currentUser != null) {
        // Thử kiểm tra identifier có tồn tại chưa (có thể skip nếu lỗi)
        bool exists = false;
        try {
          exists = await _firestoreUserService.isUniqueIdentifierExists(identifier);
        } catch (e) {
          // Tiếp tục mà không kiểm tra (có thể do Firestore rules)
        }
        
        if (exists) {
          _setError('Định danh này đã được sử dụng');
          return false;
        }

        // Cập nhật user locally trước
        _currentUser = User(
          id: _currentUser!.id,
          email: _currentUser!.email,
          displayName: _currentUser!.displayName,
          uniqueIdentifier: identifier,
          createdAt: _currentUser!.createdAt,
        );
        
        // Notify UI ngay lập tức
        notifyListeners();
        
        // Thử lưu vào Firestore (không block UI)
        try {
          await _firestoreUserService.createOrUpdateUser(_currentUser!);
        } catch (e) {
          // Vẫn giữ thay đổi local, có thể sync sau
        }
        
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  String _generateUniqueIdentifierFromEmail(String email) {
    // Lấy phần trước @ từ email
    final username = email.split('@').first.toLowerCase();
    
    // Chỉ giữ lại chữ cái, số và dấu gạch dưới
    final cleanUsername = username.replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    
    // Đảm bảo độ dài tối thiểu 3 ký tự
    if (cleanUsername.length < 3) {
      return '${cleanUsername}_user';
    }
    
    // Giới hạn độ dài tối đa 20 ký tự
    if (cleanUsername.length > 20) {
      return cleanUsername.substring(0, 20);
    }
    
    return cleanUsername;
  }
}
