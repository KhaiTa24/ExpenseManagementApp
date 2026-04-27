import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color secondary = Color(0xFFFF6584);
  static const Color success = Color(0xFF00D4AA);
  static const Color warning = Color(0xFFFFA726);
  static const Color error = Color(0xFFFF5252);
  
  // Background Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
  static const Color textLight = Color(0xFFA0AEC0);
  static const Color textWhite = Color(0xFFFFFFFF);
  
  // Transaction Type Colors
  static const Color income = Color(0xFF00D4AA);
  static const Color expense = Color(0xFFFF6584);
  
  // Budget Alert Colors
  static const Color budgetNormal = Color(0xFF00D4AA);
  static const Color budgetWarning = Color(0xFFFFA726);
  static const Color budgetDanger = Color(0xFFFF5252);
  
  // Default Category Colors
  static const Color categorySalary = Color(0xFF4CAF50);
  static const Color categoryBonus = Color(0xFFFF9800);
  static const Color categoryInvestment = Color(0xFF2196F3);
  static const Color categoryOtherIncome = Color(0xFF00BCD4);
  static const Color categoryFood = Color(0xFFFF5722);
  static const Color categoryShopping = Color(0xFFE91E63);
  static const Color categoryTransport = Color(0xFF9C27B0);
  static const Color categoryBills = Color(0xFFF44336);
  static const Color categoryEntertainment = Color(0xFF673AB7);
  static const Color categoryHealthcare = Color(0xFF009688);
  static const Color categoryEducation = Color(0xFF3F51B5);
  static const Color categoryOtherExpense = Color(0xFF795548);
  
  // Neutral Colors
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient incomeGradient = LinearGradient(
    colors: [Color(0xFF00D4AA), Color(0xFF00B894)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient expenseGradient = LinearGradient(
    colors: [Color(0xFFFF6584), Color(0xFFFF4757)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
