import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/firestore_community_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../domain/entities/community_wallet.dart';

/// Simplified Community Wallets Screen using pure Firestore real-time
class FirestoreCommunityWalletsScreen extends StatefulWidget {
  const FirestoreCommunityWalletsScreen({super.key});

  @override
  State<FirestoreCommunityWalletsScreen> createState() => _FirestoreCommunityWalletsScreenState();
}

class _FirestoreCommunityWalletsScreenState extends State<FirestoreCommunityWalletsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListening();
    });
  }

  void _startListening() {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;
    
    if (userId != null) {
      context.read<FirestoreCommunityProvider>().startListeningToUserWallets(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ví Cộng Đồng'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateWalletDialog,
          ),
        ],
      ),
      body: Consumer<FirestoreCommunityProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Có lỗi xảy ra',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    style: TextStyle(color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _startListening,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          final wallets = provider.userWallets;

          if (wallets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet_outlined, 
                       size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có ví cộng đồng nào',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tạo ví mới hoặc chờ lời mời từ người khác',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showCreateWalletDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo ví cộng đồng'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: wallets.length,
            itemBuilder: (context, index) {
              final wallet = wallets[index];
              return _buildWalletCard(wallet);
            },
          );
        },
      ),
    );
  }

  Widget _buildWalletCard(CommunityWallet wallet) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _parseColor(wallet.color),
          child: Text(
            wallet.icon ?? '💰',
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          wallet.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(wallet.description),
            const SizedBox(height: 4),
            Text(
              'Số dư: ${_formatCurrency(wallet.balance)}',
              style: TextStyle(
                color: wallet.balance >= 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FirestoreWalletDetailScreen(walletId: wallet.id),
            ),
          );
        },
      ),
    );
  }

  void _showCreateWalletDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo ví cộng đồng mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Tên ví',
                hintText: 'Ví dụ: Gia đình, Bạn bè...',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                hintText: 'Mô tả ngắn về ví này...',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              final authProvider = context.read<AuthProvider>();
              final userId = authProvider.currentUser?.id;
              
              if (userId != null) {
                final success = await context.read<FirestoreCommunityProvider>()
                    .createCommunityWallet(
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  ownerId: userId,
                );

                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tạo ví cộng đồng thành công!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String? colorString) {
    if (colorString == null) return Colors.blue;
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )} ₫';
  }
}

/// Placeholder for wallet detail screen
class FirestoreWalletDetailScreen extends StatelessWidget {
  final String walletId;

  const FirestoreWalletDetailScreen({super.key, required this.walletId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết ví'),
      ),
      body: Center(
        child: Text('Wallet Detail: $walletId'),
      ),
    );
  }
}