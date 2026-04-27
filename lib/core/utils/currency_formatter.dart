import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class CurrencyFormatter {
  // Safe format that handles both int and double
  static String formatSafe(dynamic amount) {
    if (amount == null) return '0${AppConstants.currencySymbol}';

    double value;
    if (amount is int) {
      value = amount.toDouble();
    } else if (amount is double) {
      value = amount;
    } else if (amount is String) {
      value = double.tryParse(amount) ?? 0.0;
    } else {
      value = 0.0;
    }

    return format(value);
  }

  // Format amount to currency string (e.g., 100,000₫)
  static String format(double amount) {
    final formatter = NumberFormat('#,###', 'vi');
    return '${formatter.format(amount)}${AppConstants.currencySymbol}';
  }

  // Format amount without symbol (e.g., 100,000)
  static String formatWithoutSymbol(double amount) {
    final formatter = NumberFormat('#,###', 'vi');
    return formatter.format(amount);
  }

  // Format amount with sign (+ for income, - for expense)
  static String formatWithSign(double amount, bool isIncome) {
    final formatted = format(amount.abs());
    return isIncome ? '+$formatted' : '-$formatted';
  }

  // Parse currency string to double
  static double? parse(String value) {
    try {
      // Remove currency symbol and spaces
      String cleaned = value
          .replaceAll(AppConstants.currencySymbol, '')
          .replaceAll(' ', '')
          .replaceAll(',', '');

      return double.parse(cleaned);
    } catch (e) {
      return null;
    }
  }

  // Format for input field (with thousand separators)
  static String formatInput(String value) {
    if (value.isEmpty) return '';

    // Remove all non-digit characters
    String cleaned = value.replaceAll(RegExp(r'[^\d]'), '');

    if (cleaned.isEmpty) return '';

    // Parse to number and format
    final number = int.tryParse(cleaned);
    if (number == null) return value;

    return formatWithoutSymbol(number.toDouble());
  }

  // Validate decimal places
  static bool hasValidDecimalPlaces(double amount) {
    String amountStr = amount.toString();
    if (!amountStr.contains('.')) return true;

    int decimalPlaces = amountStr.split('.')[1].length;
    return decimalPlaces <= AppConstants.maxDecimalPlaces;
  }

  // Round to valid decimal places
  static double roundToValidDecimal(double amount) {
    return double.parse(
      amount.toStringAsFixed(AppConstants.maxDecimalPlaces),
    );
  }

  // Format compact (e.g., 1.5M, 100K)
  static String formatCompact(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}B${AppConstants.currencySymbol}';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M${AppConstants.currencySymbol}';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K${AppConstants.currencySymbol}';
    } else {
      return format(amount);
    }
  }
}
