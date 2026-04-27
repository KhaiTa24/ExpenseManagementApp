import '../../../core/errors/exceptions.dart';

class ValidateAuth {
  static const int minPasswordLength = 8;
  static const int pinLength = 6;

  Future<void> validateEmail(String email) async {
    if (email.isEmpty) {
      throw ValidationException('Vui lòng nhập email');
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      throw ValidationException('Email không hợp lệ');
    }
  }

  Future<void> validatePassword(String password) async {
    if (password.isEmpty) {
      throw ValidationException('Vui lòng nhập mật khẩu');
    }

    if (password.length < minPasswordLength) {
      throw ValidationException('Mật khẩu phải có ít nhất $minPasswordLength ký tự');
    }

    // Check for uppercase
    if (!password.contains(RegExp(r'[A-Z]'))) {
      throw ValidationException('Mật khẩu phải có ít nhất 1 chữ hoa');
    }

    // Check for lowercase
    if (!password.contains(RegExp(r'[a-z]'))) {
      throw ValidationException('Mật khẩu phải có ít nhất 1 chữ thường');
    }

    // Check for number
    if (!password.contains(RegExp(r'[0-9]'))) {
      throw ValidationException('Mật khẩu phải có ít nhất 1 chữ số');
    }

    // Check for special character
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      throw ValidationException('Mật khẩu phải có ít nhất 1 ký tự đặc biệt');
    }
  }

  Future<void> validatePin(String pin) async {
    if (pin.isEmpty) {
      throw ValidationException('Vui lòng nhập mã PIN');
    }

    if (pin.length != pinLength) {
      throw ValidationException('Mã PIN phải có đúng $pinLength chữ số');
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(pin)) {
      throw ValidationException('Mã PIN chỉ được chứa số');
    }
  }

  Future<void> validateDisplayName(String displayName) async {
    if (displayName.isEmpty) {
      throw ValidationException('Vui lòng nhập tên hiển thị');
    }

    if (displayName.length < 2) {
      throw ValidationException('Tên hiển thị phải có ít nhất 2 ký tự');
    }

    if (displayName.length > 50) {
      throw ValidationException('Tên hiển thị không quá 50 ký tự');
    }
  }
}
