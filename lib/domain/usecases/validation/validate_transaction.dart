import '../../../core/errors/exceptions.dart';

class ValidateTransaction {
  static const double minAmount = 1000;
  static const double maxAmount = 999999999999;
  static const int maxDescriptionLength = 200;

  Future<void> call({
    required double amount,
    required String categoryId,
    required DateTime date,
    String? description,
  }) async {
    // Validate amount
    if (amount <= 0) {
      throw ValidationException('Vui lòng nhập số tiền');
    }

    if (amount < minAmount) {
      throw ValidationException('Số tiền tối thiểu là 1,000 VND');
    }

    if (amount > maxAmount) {
      throw ValidationException('Số tiền vượt quá giới hạn');
    }

    // Validate category
    if (categoryId.isEmpty) {
      throw ValidationException('Vui lòng chọn danh mục');
    }

    // Validate date
    if (date.isAfter(DateTime.now())) {
      throw ValidationException('Không thể chọn ngày trong tương lai');
    }

    // Validate description
    if (description != null && description.length > maxDescriptionLength) {
      throw ValidationException('Mô tả không quá 200 ký tự');
    }
  }
}
