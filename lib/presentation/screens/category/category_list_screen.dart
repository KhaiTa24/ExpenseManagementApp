import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/routes/route_names.dart';
import '../../providers/category_provider.dart';
import '../../providers/auth_provider.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;

    if (userId != null) {
      await context.read<CategoryProvider>().loadCategories(userId: userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh mục'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chi tiêu'),
            Tab(text: 'Thu nhập'),
          ],
        ),
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, categoryProvider, child) {
          if (categoryProvider.state == CategoryLoadingState.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (categoryProvider.state == CategoryLoadingState.error) {
            return Center(
              child: Text(
                categoryProvider.errorMessage ?? 'Đã xảy ra lỗi',
                style: AppTextStyles.bodyMedium,
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildCategoryList(categoryProvider.expenseCategories),
              _buildCategoryList(categoryProvider.incomeCategories),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            RouteNames.addCategory,
            arguments: _tabController.index == 0 ? 'expense' : 'income',
          ).then((_) => _loadCategories());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryList(List categories) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có danh mục',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(
                int.parse(category.color.replaceFirst('#', '0xFF')),
              ),
              child: Text(
                category.icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            title: Text(
              category.name,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              category.isDefault ? 'Mặc định' : 'Tùy chỉnh',
              style: AppTextStyles.bodySmall,
            ),
            trailing: category.isDefault
                ? null
                : PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Chỉnh sửa'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Xóa'),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteCategory(category);
                      }
                    },
                  ),
          ),
        );
      },
    );
  }

  Future<void> _deleteCategory(category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa danh mục "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.currentUser?.id;

      if (userId != null) {
        final success = await context
            .read<CategoryProvider>()
            .removeCategory(category.id, userId);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa danh mục')),
          );
        }
      }
    }
  }
}
