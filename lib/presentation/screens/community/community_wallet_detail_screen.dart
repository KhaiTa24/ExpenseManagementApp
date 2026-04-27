import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/community_transaction_provider.dart';
import '../../../domain/entities/community_wallet.dart';
import '../../../core/routes/route_names.dart';

class CommunityWalletDetailScreen extends StatefulWidget {
  final String walletId;

  const CommunityWalletDetailScreen({
    super.key,
    required this.walletId,
  });

  @override
  State<CommunityWalletDetailScreen> createState() =>
      _CommunityWalletDetailScreenState();
}

class _CommunityWalletDetailScreenState
    extends State<CommunityWalletDetailScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  late TabController _tabController;
  CommunityWallet? _wallet;
  Timer? _refreshTimer;
  StreamSubscription? _globalRefreshSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    _loadWalletData();
    _startPeriodicRefresh();
    _listenToGlobalRefresh();

    // Start listening to community transactions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<CommunityTransactionProvider>()
          .startListeningToWalletTransactions(widget.walletId);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _globalRefreshSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  void _loadWalletData() async {
    try {
      final walletDoc = await FirebaseFirestore.instance
          .collection('community_wallets')
          .doc(widget.walletId)
          .get();

      if (walletDoc.exists && mounted) {
        final data = walletDoc.data()!;
        setState(() {
          _wallet = CommunityWallet(
            id: walletDoc.id,
            name: data['name'] ?? 'Ví cộng đồng',
            description: data['description'] ?? '',
            icon: data['icon'] ?? '👥',
            balance: (data['balance'] ?? 0).toDouble(),
            createdAt: data['created_at'] != null
                ? _parseDateTime(data['created_at'])
                : DateTime.now(),
            updatedAt: data['updated_at'] != null
                ? _parseDateTime(data['updated_at'])
                : DateTime.now(),
            ownerId: data['owner_id'] ?? '',
          );
        });
      }
    } catch (e) {
      // Error loading wallet data - fail silently
    }
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _loadWalletData();
      }
    });
  }

  void _listenToGlobalRefresh() {
    // Listen to global refresh events if needed
  }

  Future<void> _refreshData() async {
    _loadWalletData();
    if (mounted) {
      context
          .read<CommunityTransactionProvider>()
          .startListeningToWalletTransactions(widget.walletId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_wallet?.name ?? 'Ví cộng đồng'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showGroupSettings,
            tooltip: 'Cài đặt nhóm',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Thành viên'),
            Tab(text: 'Giao dịch'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMembersTab(),
          _buildTransactionsTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              heroTag: 'invite_member_fab',
              onPressed: _navigateToInviteMember,
              tooltip: 'Mời thành viên',
              child: const Icon(Icons.add),
            )
          : _tabController.index == 1
              ? FloatingActionButton(
                  heroTag: 'add_transaction_fab',
                  onPressed: _navigateToAddTransaction,
                  tooltip: 'Thêm giao dịch',
                  child: const Icon(Icons.add),
                )
              : null,
    );
  }

  Widget _buildMembersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('community_members')
          .where('communityWalletId', isEqualTo: widget.walletId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Lỗi: ${snapshot.error}'),
          );
        }

        final memberDocs = snapshot.data?.docs ?? [];

        if (memberDocs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Chưa có thành viên nào',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshData,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: memberDocs.length,
            itemBuilder: (context, index) {
              final memberData =
                  memberDocs[index].data() as Map<String, dynamic>;
              return _buildMemberCard(memberData);
            },
          ),
        );
      },
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> memberData) {
    final role = memberData['role'] ?? 'member';
    final userId = memberData['userId'] ?? '';
    final joinedAt = memberData['joinedAt'] != null
        ? _parseDateTime(memberData['joinedAt'])
        : DateTime.now();
    final isRestricted = memberData['restricted'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: isRestricted ? Colors.grey : _getRoleColor(role),
              child: Icon(
                _getRoleIcon(role),
                color: Colors.white,
              ),
            ),
            if (isRestricted)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.block,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
        title: FutureBuilder<String>(
          future: _getMemberDisplayName(userId),
          builder: (context, snapshot) {
            return Text(
              snapshot.data ?? 'Đang tải...',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isRestricted ? Colors.grey : null,
              ),
            );
          },
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _getRoleDisplayName(role),
                  style: TextStyle(
                    color: isRestricted ? Colors.grey : _getRoleColor(role),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isRestricted) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red, width: 1),
                    ),
                    child: const Text(
                      'Bị hạn chế',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  'Tham gia: ${_formatDate(joinedAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: isRestricted
            ? const Icon(Icons.block, color: Colors.red)
            : null,
        isThreeLine: true,
        onTap: () {
          _showMemberDetail(memberData);
        },
      ),
    );
  }

  void _showMemberDetail(Map<String, dynamic> memberData) {
    final userId = memberData['userId'] ?? '';

    Navigator.pushNamed(
      context,
      RouteNames.memberDetail,
      arguments: {
        'memberId': userId,
        'walletId': widget.walletId,
        'memberData': memberData,
      },
    );
  }

  Widget _buildTransactionsTab() {
    return Consumer<CommunityTransactionProvider>(
      builder: (context, provider, child) {
        final transactions = provider.getTransactionsForWallet(widget.walletId);

        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long_outlined,
                    size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Chưa có giao dịch nào',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Thêm giao dịch đầu tiên cho ví cộng đồng',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _navigateToAddTransaction,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm giao dịch'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            provider.startListeningToWalletTransactions(widget.walletId);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: transaction.isIncome
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    child: Text(
                      transaction.categoryIcon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  title: Text(
                    transaction.description,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(transaction.categoryName),
                      Text(
                        'Bởi ${transaction.userName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  trailing: Text(
                    '${transaction.isIncome ? '+' : '-'}${transaction.amount.toStringAsFixed(0)}đ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: transaction.isIncome
                          ? Colors.green
                          : Colors.red,
                      fontSize: 16,
                    ),
                  ),
                  isThreeLine: true,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      RouteNames.transactionDetail,
                      arguments: {
                        'personalTransaction': null,
                        'communityTransaction': transaction,
                        'walletName': _wallet?.name,
                      },
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'owner':
        return Colors.red;
      case 'admin':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData _getRoleIcon(String role) {
    return Icons.person; // All roles use person icon
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'owner':
        return 'Chủ sở hữu';
      case 'admin':
        return 'Quản trị viên';
      default:
        return 'Thành viên';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Helper method to parse DateTime from Firestore data
  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    } else {
      return DateTime.now();
    }
  }

  Future<String> _getMemberDisplayName(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final displayName = userData['displayName'] ?? userData['display_name'];
        if (displayName != null && displayName.toString().isNotEmpty) {
          return displayName.toString();
        }
      }
      return 'User ${userId.substring(0, 8)}...';
    } catch (e) {
      return 'User ${userId.substring(0, 8)}...';
    }
  }

  void _navigateToInviteMember() {
    Navigator.pushNamed(
      context,
      RouteNames.inviteMember,
      arguments: {
        'walletId': widget.walletId,
        'walletName': _wallet?.name ?? 'Ví cộng đồng',
      },
    ).then((_) => _loadWalletData());
  }

  void _navigateToAddTransaction() {
    Navigator.pushNamed(
      context,
      RouteNames.addTransaction,
      arguments: {
        'communityWalletId': widget.walletId,
        'communityWalletName': _wallet?.name ?? 'Ví cộng đồng',
      },
    );
  }

  void _showGroupSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Cài đặt nhóm',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text(
                'Xóa nhóm',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Xóa vĩnh viễn nhóm và tất cả dữ liệu'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteGroupDialog();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showDeleteGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa nhóm'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa nhóm này?\n\n'
          'CẢNH BÁO: Hành động này không thể hoàn tác!\n'
          '• Tất cả thành viên sẽ bị xóa khỏi nhóm\n'
          '• Toàn bộ dữ liệu giao dịch sẽ bị xóa\n'
          '• Nhóm sẽ bị xóa vĩnh viễn',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteGroup();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa nhóm'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGroup() async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // 1. Delete all members
      final membersSnapshot = await FirebaseFirestore.instance
          .collection('community_members')
          .where('communityWalletId', isEqualTo: widget.walletId)
          .get();

      for (final doc in membersSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 2. Delete all transactions
      final transactionsSnapshot = await FirebaseFirestore.instance
          .collection('community_transactions')
          .where('community_wallet_id', isEqualTo: widget.walletId)
          .get();

      for (final doc in transactionsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 3. Delete all invitations
      final invitationsSnapshot = await FirebaseFirestore.instance
          .collection('community_invitations')
          .where('communityWalletId', isEqualTo: widget.walletId)
          .get();

      for (final doc in invitationsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 4. Delete the wallet itself
      batch.delete(
        FirebaseFirestore.instance
            .collection('community_wallets')
            .doc(widget.walletId),
      );

      // Execute all deletions
      await batch.commit();

      if (mounted) {
        // Show success message and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nhóm đã được xóa thành công'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to community wallets list
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa nhóm: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
