import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/firestore_community_provider.dart';
import '../../providers/community_transaction_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../domain/entities/community_wallet.dart';
import 'community_wallet_detail_screen.dart';
import 'create_community_wallet_screen.dart';

class CommunityWalletsScreen extends StatefulWidget {
  const CommunityWalletsScreen({super.key});

  @override
  State<CommunityWalletsScreen> createState() => _CommunityWalletsScreenState();
}

class _CommunityWalletsScreenState extends State<CommunityWalletsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startFirestoreListening();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _startFirestoreListening();
    }
  }

  // Start Firestore real-time listening
  void _startFirestoreListening() {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;

    if (userId != null) {
      context
          .read<FirestoreCommunityProvider>()
          .startListeningToUserWallets(userId);
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
          // Manual refresh button for testing
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _startFirestoreListening();
            },
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
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Có lỗi xảy ra',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    style: TextStyle(color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _startFirestoreListening,
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
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có ví cộng đồng nào',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tạo ví mới hoặc chờ lời mời từ người khác',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const CreateCommunityWalletScreen(),
                        ),
                      );
                    },
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
      floatingActionButton: FloatingActionButton(
        heroTag: "community_fab",
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateCommunityWalletScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildWalletCard(CommunityWallet wallet) {
    return Consumer<CommunityTransactionProvider>(
      builder: (context, transactionProvider, child) {
        // Ensure transaction listener is started for this wallet
        WidgetsBinding.instance.addPostFrameCallback((_) {
          transactionProvider.forceRefreshWalletTransactions(wallet.id);
        });

        final balance = transactionProvider.getWalletBalance(wallet.id);
        
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
                  'Số dư: ${_formatCurrency(balance)}',
                  style: TextStyle(
                    color: balance >= 0 ? Colors.green : Colors.red,
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
                  builder: (context) =>
                      CommunityWalletDetailScreen(walletId: wallet.id),
                ),
              );
            },
          ),
        );
      },
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
