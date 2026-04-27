import '../../entities/transaction.dart';
import '../../entities/category.dart';
import '../../repositories/transaction_repository.dart';
import '../../repositories/category_repository.dart';

class CategoryAnalysis {
  final String categoryId;
  final String categoryName;
  final double totalAmount;
  final int transactionCount;
  final double percentage;
  final List<Transaction> transactions;

  CategoryAnalysis({
    required this.categoryId,
    required this.categoryName,
    required this.totalAmount,
    required this.transactionCount,
    required this.percentage,
    required this.transactions,
  });
}

class GetCategoryAnalysis {
  final TransactionRepository transactionRepository;
  final CategoryRepository categoryRepository;

  GetCategoryAnalysis({
    required this.transactionRepository,
    required this.categoryRepository,
  });

  Future<List<CategoryAnalysis>> call({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    String? type,
  }) async {
    final transactions = await transactionRepository.getTransactions(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      type: type,
    );

    final categories = await categoryRepository.getCategories(userId: userId);
    
    // Group transactions by category
    Map<String, List<Transaction>> categoryTransactions = {};
    Map<String, double> categoryTotals = {};
    
    for (var transaction in transactions) {
      categoryTransactions.putIfAbsent(
        transaction.categoryId,
        () => [],
      ).add(transaction);
      
      categoryTotals[transaction.categoryId] = 
          (categoryTotals[transaction.categoryId] ?? 0) + transaction.amount;
    }

    // Calculate total for percentage
    final grandTotal = categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);

    // Create analysis list
    List<CategoryAnalysis> analysisList = [];
    
    for (var entry in categoryTotals.entries) {
      final category = categories.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => Category(
          id: entry.key,
          userId: userId,
          name: 'Unknown',
          icon: '❓',
          color: '#999999',
          type: type ?? 'expense',
          createdAt: DateTime.now(),
        ),
      );

      analysisList.add(CategoryAnalysis(
        categoryId: entry.key,
        categoryName: category.name,
        totalAmount: entry.value,
        transactionCount: categoryTransactions[entry.key]!.length,
        percentage: grandTotal > 0 ? (entry.value / grandTotal) * 100 : 0,
        transactions: categoryTransactions[entry.key]!,
      ));
    }

    // Sort by total amount descending
    analysisList.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    return analysisList;
  }
}
