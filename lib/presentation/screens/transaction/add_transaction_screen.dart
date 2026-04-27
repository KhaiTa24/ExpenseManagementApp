import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/routes/route_names.dart';
import '../../../domain/entities/transaction.dart' as domain;
import '../../../domain/entities/category.dart' as domain;
import '../../../domain/entities/community_wallet.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/firestore_community_provider.dart';
import '../../providers/community_transaction_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/shared/amount_input.dart';
import '../../widgets/shared/date_picker_field.dart';

class AddTransactionScreen extends StatefulWidget {
  final String? initialType;

  const AddTransactionScreen({super.key, this.initialType});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _type = 'expense';
  DateTime _selectedDate = DateTime.now();
  domain.Category? _selectedCategory;

  // Wallet selection
  String _walletType = 'personal'; // 'personal' or 'community'
  CommunityWallet? _selectedCommunityWallet;

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _type = widget.initialType!;
    }

    // Load categories and community wallets
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.id;
      if (userId != null) {
        final categoryProvider = context.read<CategoryProvider>();
        await categoryProvider.loadCategories(userId: userId);

        // If no categories exist, initialize default categories
        if (categoryProvider.categories.isEmpty) {
          await categoryProvider.initializeDefaults(userId);
        }

        // Check if we have categories for current type
        final categoriesForType = categoryProvider.categories
            .where((cat) => cat.type == _type)
            .toList();

        if (categoriesForType.isEmpty) {
          await categoryProvider.initializeDefaults(userId);
        }

        context
            .read<FirestoreCommunityProvider>()
            .startListeningToUserWallets(userId);
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    // Manual validation for category since we're not using DropdownButtonFormField
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn danh mục'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_walletType == 'community' && _selectedCommunityWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ví cộng đồng'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;

    if (userId == null) return;

    final amount = double.parse(_amountController.text);

    if (_walletType == 'community') {
      // Add community transaction
      final communityTransactionProvider =
          context.read<CommunityTransactionProvider>();

      await communityTransactionProvider.addTransaction(
        communityWalletId: _selectedCommunityWallet!.id,
        userId: userId,
        userName: authProvider.currentUser?.displayName ?? 'Unknown',
        type: _type,
        amount: amount,
        categoryId: _selectedCategory!.id,
        categoryName: _selectedCategory!.name,
        categoryIcon: _selectedCategory!.icon,
        description: _descriptionController.text.isEmpty
            ? 'Giao dịch ${_type == 'income' ? 'thu nhập' : 'chi tiêu'}'
            : _descriptionController.text,
        date: _selectedDate,
      );

      final success = communityTransactionProvider.error == null;

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Đã thêm giao dịch vào ${_selectedCommunityWallet!.name}'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(communityTransactionProvider.error ?? 'Có lỗi xảy ra'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } else {
      // Add personal transaction
      final transaction = domain.Transaction(
        id: const Uuid().v4(),
        userId: userId,
        categoryId: _selectedCategory!.id,
        amount: amount,
        type: _type,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        date: _selectedDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        walletId: 'personal',
        communityWalletId: null,
      );

      final transactionProvider = context.read<TransactionProvider>();
      final success = await transactionProvider.addNewTransaction(transaction);

      if (mounted) {
        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã thêm giao dịch cá nhân'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Có lỗi xảy ra khi thêm giao dịch'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  // Helper method to parse color from string
  Color _parseColor(String colorString) {
    try {
      // Remove # if present
      String cleanColor = colorString.replaceAll('#', '');

      // Add FF for alpha if not present
      if (cleanColor.length == 6) {
        cleanColor = 'FF$cleanColor';
      }

      return Color(int.parse(cleanColor, radix: 16));
    } catch (e) {
      // Return default color if parsing fails
      return AppColors.primary;
    }
  }

  void _showCategorySelector(BuildContext context,
      List<domain.Category> categories, CategoryProvider categoryProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chọn danh mục ${_type == 'income' ? 'thu nhập' : 'chi tiêu'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await Navigator.pushNamed(
                        context,
                        RouteNames.addCategory,
                        arguments: _type,
                      );

                      // Always reload categories after returning from add category screen
                      if (mounted) {
                        final authProvider = context.read<AuthProvider>();
                        final userId = authProvider.currentUser?.id;
                        if (userId != null) {
                          await categoryProvider.loadCategories(userId: userId);
                          // Force rebuild to show new categories
                          setState(() {});
                        }
                      }
                    },
                    icon: const Icon(Icons.add),
                    tooltip: 'Thêm danh mục mới',
                  ),
                ],
              ),
            ),

            // Categories Grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = _selectedCategory?.id == category.id;
                    final categoryColor = _parseColor(category.color);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? categoryColor : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isSelected ? categoryColor : Colors.grey[300]!,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              category.icon,
                              style: TextStyle(
                                fontSize: 24,
                                color:
                                    isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              category.name,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color:
                                    isSelected ? Colors.white : Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_walletType == 'personal'
            ? 'Thêm giao dịch cá nhân'
            : 'Thêm giao dịch cộng đồng'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wallet Selection Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Loại ví', style: AppTextStyles.h3),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Cá nhân'),
                              value: 'personal',
                              groupValue: _walletType,
                              onChanged: (value) {
                                setState(() {
                                  _walletType = value!;
                                  _selectedCommunityWallet = null;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Cộng đồng'),
                              value: 'community',
                              groupValue: _walletType,
                              onChanged: (value) {
                                setState(() {
                                  _walletType = value!;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),

                      // Community wallet dropdown
                      if (_walletType == 'community') ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text('Ví cộng đồng', style: AppTextStyles.h3),
                        const SizedBox(height: 8),
                        Consumer<FirestoreCommunityProvider>(
                          builder: (context, provider, child) {
                            final wallets = provider.userWallets;

                            if (wallets.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.orange[300]!),
                                ),
                                child: const Text(
                                  'Chưa có ví cộng đồng nào. Tạo ví cộng đồng trước.',
                                  style: TextStyle(color: Colors.orange),
                                ),
                              );
                            }

                            return DropdownButtonFormField<CommunityWallet>(
                              value: _selectedCommunityWallet,
                              decoration: const InputDecoration(
                                labelText: 'Chọn ví cộng đồng',
                                border: OutlineInputBorder(),
                              ),
                              isExpanded: true,
                              items: wallets.map((wallet) {
                                return DropdownMenuItem<CommunityWallet>(
                                  value: wallet,
                                  child: Row(
                                    children: [
                                      Text(
                                        wallet.icon ?? '👥',
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          wallet.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (wallet) {
                                setState(() {
                                  _selectedCommunityWallet = wallet;
                                });
                              },
                              validator: (value) {
                                if (_walletType == 'community' &&
                                    value == null) {
                                  return 'Vui lòng chọn ví cộng đồng';
                                }
                                return null;
                              },
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Transaction Details Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Chi tiết giao dace', style: AppTextStyles.h3),
                      const SizedBox(height: 16),

                      // Transaction Type
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Chi tiêu'),
                              value: 'expense',
                              groupValue: _type,
                              onChanged: (value) {
                                setState(() {
                                  _type = value!;
                                  _selectedCategory = null;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Thu nhập'),
                              value: 'income',
                              groupValue: _type,
                              onChanged: (value) {
                                setState(() {
                                  _type = value!;
                                  _selectedCategory = null;
                                });
                              },
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Amount Input
                      AmountInput(
                        controller: _amountController,
                        label: 'Số tiền',
                      ),

                      const SizedBox(height: 16),

                      // Date Picker
                      DatePickerField(
                        selectedDate: _selectedDate,
                        onDateSelected: (date) {
                          setState(() {
                            _selectedDate = date;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Category & Description Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Danh mục & Mô tả', style: AppTextStyles.h3),
                      const SizedBox(height: 12),
                      Consumer<CategoryProvider>(
                        builder: (context, categoryProvider, child) {
                          final categories = categoryProvider.categories
                              .where((cat) => cat.type == _type)
                              .toList();

                          // Show loading state
                          if (categoryProvider.state ==
                              CategoryLoadingState.loading) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          // Show empty state with option to initialize defaults
                          if (categories.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange[300]!),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'Chưa có danh mục ${_type == 'income' ? 'thu nhập' : 'chi tiêu'} nào',
                                    style: TextStyle(color: Colors.orange[700]),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      final authProvider =
                                          context.read<AuthProvider>();
                                      final userId =
                                          authProvider.currentUser?.id;
                                      if (userId != null) {
                                        await categoryProvider
                                            .initializeDefaults(userId);
                                      }
                                    },
                                    icon: const Icon(Icons.auto_fix_high),
                                    label: const Text('Tạo danh mục mặc định'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Column(
                            children: [
                              // Category Selection Button
                              GestureDetector(
                                onTap: () => _showCategorySelector(
                                    context, categories, categoryProvider),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      if (_selectedCategory != null) ...[
                                        // Selected category display
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: _parseColor(
                                                _selectedCategory!.color),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Center(
                                            child: Text(
                                              _selectedCategory!.icon,
                                              style: const TextStyle(
                                                fontSize: 20,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _selectedCategory!.name,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                'Tap để thay đổi',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ] else ...[
                                        // No category selected
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.category,
                                              color: Colors.grey,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Chọn danh mục',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                'Tap để chọn danh mục',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Description
                              CustomTextField(
                                controller: _descriptionController,
                                label: 'Mô tả giao dịch (tùy chọn)',
                                maxLines: 3,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Lưu giao dịch',
                  onPressed: _handleSave,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
