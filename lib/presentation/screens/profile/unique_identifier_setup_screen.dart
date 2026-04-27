import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class UniqueIdentifierSetupScreen extends StatefulWidget {
  const UniqueIdentifierSetupScreen({super.key});

  @override
  State<UniqueIdentifierSetupScreen> createState() =>
      _UniqueIdentifierSetupScreenState();
}

class _UniqueIdentifierSetupScreenState
    extends State<UniqueIdentifierSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    if (user?.uniqueIdentifier != null) {
      _identifierController.text = user!.uniqueIdentifier!;
    } else {
      // Đề xuất một unique identifier mẫu
      final email = user?.email ?? '';
      if (email.isNotEmpty) {
        final username = email.split('@').first.toLowerCase();
        _identifierController.text =
            username.replaceAll(RegExp(r'[^a-z0-9_]'), '_');
      }
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đổi định danh duy nhất'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Về định danh duy nhất',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Định danh duy nhất giúp người khác tìm và thêm bạn vào ví cộng đồng. '
                        'Bạn có thể thay đổi định danh này bất cứ lúc nào.',
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Định danh duy nhất *',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _identifierController,
                decoration: const InputDecoration(
                  hintText: 'Ví dụ: john_doe, user123, my_unique_id',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.alternate_email),
                  helperText: 'Chỉ được sử dụng chữ cái, số và dấu gạch dưới',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập định danh duy nhất';
                  }

                  final identifier = value.trim();
                  if (identifier.length < 3) {
                    return 'Định danh phải có ít nhất 3 ký tự';
                  }

                  if (identifier.length > 30) {
                    return 'Định danh không được quá 30 ký tự';
                  }

                  // Kiểm tra ký tự hợp lệ
                  final validPattern = RegExp(r'^[a-zA-Z0-9_]+$');
                  if (!validPattern.hasMatch(identifier)) {
                    return 'Chỉ được sử dụng chữ cái, số và dấu gạch dưới';
                  }

                  return null;
                },
                onChanged: (value) {
                  // Chuyển về chữ thường và loại bỏ ký tự không hợp lệ
                  final cleaned =
                      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
                  if (cleaned != value) {
                    _identifierController.value = TextEditingValue(
                      text: cleaned,
                      selection:
                          TextSelection.collapsed(offset: cleaned.length),
                    );
                  }
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveIdentifier,
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Cập nhật định danh',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveIdentifier() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Cập nhật unique identifier
      final identifier = _identifierController.text.trim().toLowerCase();
      final success =
          await context.read<AuthProvider>().updateUniqueIdentifier(identifier);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật định danh thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Định danh đã tồn tại, vui lòng chọn định danh khác'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
