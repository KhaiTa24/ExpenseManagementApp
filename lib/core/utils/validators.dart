import '../constants/app_constants.dart';

class Validators {
  // Email Validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập email';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Email không hợp lệ';
    }
    
    return null;
  }
  
  // Password Validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    
    if (value.length < AppConstants.minPasswordLength) {
      return 'Mật khẩu phải có ít nhất ${AppConstants.minPasswordLength} ký tự';
    }
    
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Mật khẩu phải có ít nhất 1 chữ hoa';
    }
    
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Mật khẩu phải có ít nhất 1 chữ thường';
    }
    
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Mật khẩu phải có ít nhất 1 số';
    }
    
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Mật khẩu phải có ít nhất 1 ký tự đặc biệt';
    }
    
    return null;
  }
  
  // Amount Validation
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập số tiền';
    }
    
    final amount = double.tryParse(value.replaceAll(',', ''));
    
    if (amount == null) {
      return 'Số tiền không hợp lệ';
    }
    
    if (amount < AppConstants.minAmount) {
      return 'Số tiền tối thiểu là ${AppConstants.minAmount.toStringAsFixed(0)} VND';
    }
    
    if (amount > AppConstants.maxAmount) {
      return 'Số tiền vượt quá giới hạn';
    }
    
    if (amount == 0) {
      return 'Số tiền không thể bằng 0';
    }
    
    return null;
  }
  
  // Category Name Validation
  static String? validateCategoryName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập tên danh mục';
    }
    
    if (value.length < AppConstants.minCategoryNameLength) {
      return 'Tên danh mục phải có ít nhất ${AppConstants.minCategoryNameLength} ký tự';
    }
    
    if (value.length > AppConstants.maxCategoryNameLength) {
      return 'Tên danh mục không quá ${AppConstants.maxCategoryNameLength} ký tự';
    }
    
    return null;
  }
  
  // Description Validation
  static String? validateDescription(String? value) {
    if (value != null && value.length > AppConstants.maxDescriptionLength) {
      return 'Mô tả không quá ${AppConstants.maxDescriptionLength} ký tự';
    }
    return null;
  }
  
  // PIN Validation
  static String? validatePin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mã PIN';
    }
    
    if (value.length != AppConstants.pinLength) {
      return 'Mã PIN phải có ${AppConstants.pinLength} chữ số';
    }
    
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Mã PIN chỉ được chứa số';
    }
    
    return null;
  }
  
  // Budget Amount Validation
  static String? validateBudgetAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập số tiền ngân sách';
    }
    
    final amount = double.tryParse(value.replaceAll(',', ''));
    
    if (amount == null) {
      return 'Số tiền không hợp lệ';
    }
    
    if (amount < AppConstants.minBudget) {
      return 'Ngân sách tối thiểu là ${AppConstants.minBudget.toStringAsFixed(0)} VND';
    }
    
    if (amount > AppConstants.maxBudget) {
      return 'Ngân sách vượt quá giới hạn';
    }
    
    return null;
  }
  
  // Required Field Validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập $fieldName';
    }
    return null;
  }
}
