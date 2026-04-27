import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/firestore_community_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';

class CreateCommunityWalletScreen extends StatefulWidget {
  const CreateCommunityWalletScreen({super.key});

  @override
  State<CreateCommunityWalletScreen> createState() => _CreateCommunityWalletScreenState();
}

class _CreateCommunityWalletScreenState extends State<CreateCommunityWalletScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedIcon = '👥';
  Color _selectedColor = Colors.blue;
  bool _isLoading = false;
  List<String> _availableIcons = [];

  final List<Color> _availableColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
    Colors.brown,
    Colors.grey,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories();
    });
  }

  Future<void> _loadCategories() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;
    if (userId != null) {
      await context.read<CategoryProvider>().loadCategories(userId: userId);
      
      // Get unique icons from categories
      final categories = context.read<CategoryProvider>().categories;
      final iconSet = <String>{};
      
      // Add default community icons
      iconSet.addAll(['👥', '👨‍👩‍👧‍👦', '🏠', '💼', '🎓', '⚽', '🍽️', '🛒', '✈️', '🏥']);
      
      // Add icons from categories
      for (final category in categories) {
        if (category.icon.isNotEmpty) {
          iconSet.add(category.icon);
        }
      }
      
      setState(() {
        _availableIcons = iconSet.toList();
        if (_availableIcons.isNotEmpty && !_availableIcons.contains(_selectedIcon)) {
          _selectedIcon = _availableIcons.first;
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo Ví Cộng Đồng'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Preview
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _selectedColor,
                      radius: 30,
                      child: Text(
                        _selectedIcon,
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nameController.text.isEmpty ? 'Tên ví' : _nameController.text,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _descriptionController.text.isEmpty 
                                ? 'Mô tả ví' 
                                : _descriptionController.text,
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tên ví
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên ví *',
                hintText: 'Ví dụ: Gia đình, Bạn bè, Công ty...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên ví';
                }
                if (value.trim().length < 2) {
                  return 'Tên ví phải có ít nhất 2 ký tự';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Mô tả
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                hintText: 'Mô tả ngắn về mục đích sử dụng ví',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),

            // Chọn icon
            Text(
              'Chọn biểu tượng',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableIcons.map((iconEmoji) {
                final isSelected = iconEmoji == _selectedIcon;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedIcon = iconEmoji;
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? _selectedColor : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? _selectedColor : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      iconEmoji,
                      style: TextStyle(
                        fontSize: 24,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Chọn màu
            Text(
              'Chọn màu sắc',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableColors.map((color) {
                final isSelected = color == _selectedColor;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.grey[300]!,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // Nút tạo
            ElevatedButton(
              onPressed: _isLoading ? null : _createWallet,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Tạo Ví Cộng Đồng',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createWallet() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập để tiếp tục')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await context.read<FirestoreCommunityProvider>().createCommunityWallet(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      ownerId: userId,
      icon: _selectedIcon,
      color: '#${_selectedColor.value.toRadixString(16).substring(2)}',
    );

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo ví cộng đồng thành công!')),
      );
      Navigator.pop(context);
    } else {
      final error = context.read<FirestoreCommunityProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${error ?? "Không thể tạo ví"}')),
      );
    }
  }
}