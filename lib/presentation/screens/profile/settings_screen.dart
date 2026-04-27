import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/routes/route_names.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/entities/category.dart' as app_category;
import '../../../domain/entities/budget.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/backup_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/budget_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
      ),
      body: ListView(
        children: [
          // User Info Section
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.currentUser;

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.textWhite,
                      child: Text(
                        user?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                        style: AppTextStyles.h1.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.displayName ?? 'User',
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.textWhite,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        if (user?.uniqueIdentifier != null) {
                          _copyToClipboard(context, user!.uniqueIdentifier!);
                        } else {
                          // Force tạo lại identifier
                          _forceCreateIdentifier(context);
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.alternate_email,
                            color: AppColors.textWhite,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user?.uniqueIdentifier ?? 'Đang tạo...',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textWhite.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (user?.uniqueIdentifier != null) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.copy,
                              color: AppColors.textWhite,
                              size: 14,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          // Appearance Section
          _buildSectionHeader('Giao diện'),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return SwitchListTile(
                title: const Text('Chế độ tối'),
                subtitle: const Text('Bật/tắt chế độ tối'),
                secondary: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                ),
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleTheme();
                },
              );
            },
          ),

          const Divider(),

          // Security Section
          _buildSectionHeader('Bảo mật'),
          ListTile(
            leading: const Icon(Icons.fingerprint),
            title: const Text('Xác thực sinh trắc học'),
            subtitle: const Text('Vân tay / Face ID'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, RouteNames.biometricSetup);
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Đổi mật khẩu'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, RouteNames.changePassword);
            },
          ),
          ListTile(
            leading: const Icon(Icons.pin_outlined),
            title: const Text('Mã PIN'),
            subtitle: const Text('Thiết lập mã PIN 6 số'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, RouteNames.pinSetup);
            },
          ),
          ListTile(
            leading: const Icon(Icons.alternate_email),
            title: const Text('Đổi định danh'),
            subtitle: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final identifier = authProvider.currentUser?.uniqueIdentifier;
                return Text(
                  identifier != null 
                      ? 'ID hiện tại: $identifier'
                      : 'Chưa thiết lập định danh',
                );
              },
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, RouteNames.uniqueIdentifierSetup);
            },
          ),

          const Divider(),

          // Data Section
          _buildSectionHeader('Dữ liệu'),
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: const Text('Sao lưu dữ liệu'),
            subtitle: const Text('Sao lưu lên cloud'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showBackupDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_download_outlined),
            title: const Text('Khôi phục dữ liệu'),
            subtitle: const Text('Khôi phục từ cloud'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showRestoreDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Đồng bộ'),
            subtitle: const Text('Đồng bộ dữ liệu với cloud'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _performSync(context),
          ),

          const Divider(),

          // Notifications Section
          _buildSectionHeader('Thông báo'),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Cài đặt thông báo'),
            subtitle: const Text('Nhắc nhở và cảnh báo'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, RouteNames.notificationSettings);
            },
          ),

          const Divider(),

          // About Section
          _buildSectionHeader('Về ứng dụng'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Phiên bản'),
            subtitle: const Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Chính sách bảo mật'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Show privacy policy
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Điều khoản sử dụng'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Show terms of service
            },
          ),

          const Divider(),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text(
              'Đăng xuất',
              style: TextStyle(color: AppColors.error),
            ),
            onTap: () {
              _showLogoutDialog(context);
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sao lưu dữ liệu'),
        content: const Text(
          'Sao lưu tất cả dữ liệu (giao dịch, danh mục, ngân sách) lên Firebase Cloud?\n\n'
          'Dữ liệu hiện tại trên cloud sẽ được ghi đè.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performBackup(context);
            },
            child: const Text('Sao lưu'),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog(BuildContext context) {
    // Lưu context của widget cha để sử dụng sau khi dialog đóng
    final parentContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Khôi phục dữ liệu'),
        content: const Text(
          'Khôi phục dữ liệu từ Firebase Cloud?\n\n'
          'Cảnh báo: Dữ liệu hiện tại trên thiết bị sẽ bị ghi đè!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Đóng dialog

              // Sử dụng parentContext thay vì dialogContext
              await _performRestore(parentContext);
            },
            child: const Text(
              'Khôi phục',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performBackup(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final backupProvider = context.read<BackupProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    final budgetProvider = context.read<BudgetProvider>();

    final userId = authProvider.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi: Không tìm thấy thông tin người dùng'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang sao lưu dữ liệu...'),
        duration: Duration(seconds: 3),
      ),
    );

    final success = await backupProvider.backupData(
      userId: userId,
      transactions: transactionProvider.transactions,
      categories: categoryProvider.categories,
      budgets: budgetProvider.budgets,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Sao lưu thành công!' : 'Sao lưu thất bại!'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _performRestore(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final backupProvider = context.read<BackupProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    final budgetProvider = context.read<BudgetProvider>();

    final userId = authProvider.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: User not found'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Restoring data...'),
        duration: Duration(seconds: 3),
      ),
    );

    final data = await backupProvider.restoreData(userId: userId);

    if (context.mounted) {
      if (data != null) {
        try {
          // Apply restored data directly (no delay)
          await _applyRestoredData(
            context,
            data,
            transactionProvider,
            categoryProvider,
            budgetProvider,
          );

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Restore successful! Data has been updated.'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Restore failed: ${e.toString()}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restore failed! No backup data found.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _applyRestoredData(
    BuildContext context,
    Map<String, dynamic> data,
    TransactionProvider transactionProvider,
    CategoryProvider categoryProvider,
    BudgetProvider budgetProvider,
  ) async {
    try {
      if (kDebugMode) {
        debugPrint('🚀 _applyRestoredData called');
        debugPrint('📊 Raw backup data keys: ${data.keys.toList()}');
      }

      // Import entities
      final transactions = data['transactions'] as List<dynamic>? ?? [];
      final categories = data['categories'] as List<dynamic>? ?? [];
      final budgets = data['budgets'] as List<dynamic>? ?? [];

      if (kDebugMode) {
        debugPrint('🔄 Starting restore process...');
        debugPrint(
            '📊 Data to restore - Transactions: ${transactions.length}, Categories: ${categories.length}, Budgets: ${budgets.length}');

        if (categories.isNotEmpty) {
          debugPrint(
              '📋 Categories data preview: ${categories.take(2).toList()}');
        } else {
          debugPrint('⚠️ Categories array is EMPTY!');
        }
      }

      // Get current user ID
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      if (kDebugMode) {
        debugPrint('🗑️ Clearing existing data before restore...');
      }

      // Clear existing data first (optional - comment out if you want to keep existing data)
      // This ensures restored data doesn't conflict with existing data

      // Restore categories first (transactions depend on categories)
      if (kDebugMode) {
        debugPrint('📂 Starting category restore...');
        debugPrint('📊 Categories to restore: ${categories.length}');
        if (categories.isNotEmpty) {
          debugPrint('📋 First category data: ${categories.first}');
        }
      }

      for (final categoryData in categories) {
        if (kDebugMode) {
          debugPrint('🔧 Processing category data: $categoryData');
        }

        final category = _createCategoryFromMap(categoryData);
        if (category != null) {
          if (kDebugMode) {
            debugPrint(
                '🔧 Attempting to restore category: ${category.id} - ${category.name}');
          }

          final success = await categoryProvider.restoreCategory(category);

          if (kDebugMode) {
            debugPrint(success
                ? '✅ Category restored successfully: ${category.name}'
                : '❌ Failed to restore category: ${category.name}');
          }
        } else {
          if (kDebugMode) {
            debugPrint('❌ Failed to create category from data: $categoryData');
          }
        }
      }

      // Restore transactions
      if (kDebugMode) {
        debugPrint('💰 Starting transaction restore...');
      }

      for (final transactionData in transactions) {
        final transaction = _createTransactionFromMap(transactionData);
        if (transaction != null) {
          // Check if categoryId exists in restored categories
          final categoryExists =
              categoryProvider.getCategoryById(transaction.categoryId) != null;

          if (!categoryExists) {
            if (kDebugMode) {
              debugPrint(
                  '⚠️ Category ID ${transaction.categoryId} not found, trying to find by type...');
            }

            // Try to find a suitable category by type
            final suitableCategories = transaction.type == 'income'
                ? categoryProvider.incomeCategories
                : categoryProvider.expenseCategories;

            if (suitableCategories.isNotEmpty) {
              // Use the first suitable category (or default category)
              final fallbackCategory = suitableCategories.first;

              if (kDebugMode) {
                debugPrint(
                    '🔄 Using fallback category: ${fallbackCategory.name} (${fallbackCategory.id})');
              }

              // Create new transaction with correct categoryId
              final correctedTransaction = Transaction(
                id: transaction.id,
                userId: transaction.userId,
                categoryId: fallbackCategory.id, // Use fallback category ID
                amount: transaction.amount,
                type: transaction.type,
                description: transaction.description,
                date: transaction.date,
                createdAt: transaction.createdAt,
                updatedAt: transaction.updatedAt,
              );

              await transactionProvider.addNewTransaction(correctedTransaction);
            } else {
              if (kDebugMode) {
                debugPrint(
                    '❌ No suitable fallback category found for transaction: ${transaction.description}');
              }
            }
          } else {
            // Category exists, proceed normally
            await transactionProvider.addNewTransaction(transaction);
          }
        }
      }

      // Restore budgets
      for (final budgetData in budgets) {
        final budget = _createBudgetFromMap(budgetData);
        if (budget != null) {
          await budgetProvider.addNewBudget(budget);
        }
      }

      // Reload all data to refresh UI - load categories first
      if (kDebugMode) {
        debugPrint('🔄 Reloading providers...');
      }

      await categoryProvider.loadCategories(userId: userId);
      await Future.wait([
        transactionProvider.loadTransactions(userId: userId),
        budgetProvider.loadBudgets(userId: userId),
      ]);

      if (kDebugMode) {
        debugPrint('✅ Restore process completed!');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Restore process failed: $e');
      }
      rethrow;
    }
  }

  // Helper methods to create entities from maps
  app_category.Category? _createCategoryFromMap(Map<String, dynamic> data) {
    try {
      // Handle missing createdAt field in old backup data
      DateTime createdAt;
      if (data['createdAt'] != null) {
        createdAt = DateTime.parse(data['createdAt'] as String);
      } else {
        createdAt = DateTime.now();
      }

      final category = app_category.Category(
        id: data['id'] as String,
        userId: data['userId'] as String,
        name: data['name'] as String,
        type: data['type'] as String,
        icon: data['icon'] as String,
        color: data['color'] as String,
        isDefault: data['isDefault'] as bool? ?? false,
        createdAt: createdAt,
      );

      // Debug: Log restored category
      if (kDebugMode) {
        debugPrint('✅ Restoring category: ${category.id} - ${category.name}');
      }

      return category;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating category: $e');
      }
      return null;
    }
  }

  Transaction? _createTransactionFromMap(Map<String, dynamic> data) {
    try {
      final transaction = Transaction(
        id: data['id'] as String,
        userId: data['userId'] as String,
        categoryId: data['categoryId'] as String,
        amount: (data['amount'] as num).toDouble(),
        type: data['type'] as String,
        description: data['description'] as String? ?? '',
        date: DateTime.parse(data['date'] as String),
        createdAt: DateTime.parse(data['createdAt'] as String),
        updatedAt: DateTime.parse(data['updatedAt'] as String),
      );

      // Debug: Log restored transaction
      if (kDebugMode) {
        debugPrint(
            '✅ Restoring transaction: ${transaction.id} - ${transaction.description} (categoryId: ${transaction.categoryId})');
      }

      return transaction;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error creating transaction: $e');
      }
      return null;
    }
  }

  Budget? _createBudgetFromMap(Map<String, dynamic> data) {
    try {
      final budget = Budget(
        id: data['id'] as String,
        userId: data['userId'] as String,
        categoryId: data['categoryId'] as String,
        amount: (data['amount'] as num).toDouble(),
        period: data['period'] as String,
        month: data['month'] as int,
        year: data['year'] as int,
        createdAt: DateTime.parse(data['createdAt'] as String),
      );

      return budget;
    } catch (e) {
      return null;
    }
  }

  Future<void> _performSync(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final backupProvider = context.read<BackupProvider>();
    final transactionProvider = context.read<TransactionProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    final budgetProvider = context.read<BudgetProvider>();

    final userId = authProvider.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: User not found'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Syncing data...'),
        duration: Duration(seconds: 5),
      ),
    );

    try {
      // Step 1: Backup current local data
      final backupSuccess = await backupProvider.backupData(
        userId: userId,
        transactions: transactionProvider.transactions,
        categories: categoryProvider.categories,
        budgets: budgetProvider.budgets,
      );

      if (!backupSuccess) {
        throw Exception('Backup failed during sync');
      }

      // Step 2: Check if there's existing cloud data to merge
      final hasCloudBackup = await backupProvider.hasBackup(userId: userId);

      if (hasCloudBackup) {
        // Step 3: Load backup info to show user
        await backupProvider.loadBackupInfo(userId: userId);
        final backupInfo = backupProvider.backupInfo;

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Sync successful! Backup updated with ${backupInfo?['transactionCount'] ?? 0} transactions, '
                  '${backupInfo?['categoryCount'] ?? 0} categories, ${backupInfo?['budgetCount'] ?? 0} budgets.'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sync successful! Initial backup created.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              final authProvider = context.read<AuthProvider>();
              await authProvider.signOut();

              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  RouteNames.login,
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép: $text'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _forceCreateIdentifier(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    
    if (user?.email != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang tạo định danh...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Tạo identifier từ email
      final email = user!.email;
      final username = email.split('@').first.toLowerCase();
      final cleanUsername = username.replaceAll(RegExp(r'[^a-z0-9_]'), '_');
      
      String identifier = cleanUsername;
      if (identifier.length < 3) {
        identifier = '${identifier}_user';
      }
      if (identifier.length > 20) {
        identifier = identifier.substring(0, 20);
      }
      
      final success = await authProvider.updateUniqueIdentifier(identifier);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã tạo định danh: $identifier'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tạo định danh, vui lòng thử lại'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
