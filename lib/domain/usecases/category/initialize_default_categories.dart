import 'package:uuid/uuid.dart';
import '../../entities/category.dart';
import '../../repositories/category_repository.dart';

class InitializeDefaultCategories {
  final CategoryRepository repository;
  final Uuid uuid;

  InitializeDefaultCategories({
    required this.repository,
    required this.uuid,
  });

  Future<void> call(String userId) async {
    final now = DateTime.now();

    // Income categories
    final incomeCategories = [
      Category(
        id: uuid.v4(),
        userId: userId,
        name: 'Lương',
        icon: '💰',
        color: '#4CAF50',
        type: 'income',
        isDefault: true,
        createdAt: now,
      ),
      Category(
        id: uuid.v4(),
        userId: userId,
        name: 'Thưởng',
        icon: '🎁',
        color: '#FF9800',
        type: 'income',
        isDefault: true,
        createdAt: now,
      ),
      Category(
        id: uuid.v4(),
        userId: userId,
        name: 'Đầu tư',
        icon: '📈',
        color: '#2196F3',
        type: 'income',
        isDefault: true,
        createdAt: now,
      ),
      Category(
        id: uuid.v4(),
        userId: userId,
        name: 'Thu nhập khác',
        icon: '💵',
        color: '#00BCD4',
        type: 'income',
        isDefault: true,
        createdAt: now,
      ),
    ];

    // Expense categories
    final expenseCategories = [
      Category(
        id: uuid.v4(),
        userId: userId,
        name: 'Ăn uống',
        icon: '🍔',
        color: '#FF5722',
        type: 'expense',
        isDefault: true,
        createdAt: now,
      ),
      Category(
        id: uuid.v4(),
        userId: userId,
        name: 'Mua sắm',
        icon: '🛒',
        color: '#E91E63',
        type: 'expense',
        isDefault: true,
        createdAt: now,
      ),
      Category(
        id: uuid.v4(),
        userId: userId,
        name: 'Đi lại',
        icon: '🚗',
        color: '#9C27B0',
        type: 'expense',
        isDefault: true,
        createdAt: now,
      ),
      Category(
        id: uuid.v4(),
        userId: userId,
        name: 'Hóa đơn',
        icon: '📄',
        color: '#F44336',
        type: 'expense',
        isDefault: true,
        createdAt: now,
      ),
      Category(
        id: uuid.v4(),
        userId: userId,
        name: 'Giải trí',
        icon: '🎬',
        color: '#673AB7',
        type: 'expense',
        isDefault: true,
        createdAt: now,
      ),
      Category(
        id: uuid.v4(),
        userId: userId,
        name: 'Y tế',
        icon: '🏥',
        color: '#009688',
        type: 'expense',
        isDefault: true,
        createdAt: now,
      ),
      Category(
        id: uuid.v4(),
        userId: userId,
        name: 'Giáo dục',
        icon: '🎓',
        color: '#3F51B5',
        type: 'expense',
        isDefault: true,
        createdAt: now,
      ),
      Category(
        id: uuid.v4(),
        userId: userId,
        name: 'Chi phí khác',
        icon: '📌',
        color: '#795548',
        type: 'expense',
        isDefault: true,
        createdAt: now,
      ),
    ];

    // Add all categories
    for (var category in [...incomeCategories, ...expenseCategories]) {
      await repository.addCategory(category);
    }
  }
}
