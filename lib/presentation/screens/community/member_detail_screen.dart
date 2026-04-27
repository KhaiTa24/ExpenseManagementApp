import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/community_transaction_provider.dart';
import '../../providers/auth_provider.dart';
import '../../../domain/entities/community_wallet.dart';

class MemberDetailScreen extends StatefulWidget {
  final String memberId;
  final String walletId;

  const MemberDetailScreen({
    super.key,
    required this.memberId,
    required this.walletId,
  });

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  Map<String, dynamic>? _memberData;
  CommunityWallet? _wallet;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Start listening to transactions immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CommunityTransactionProvider>();
      provider.forceRefreshWalletTransactions(widget.walletId);
    });
  }

  Future<void> _loadData() async {
    try {
      // Load member data
      final memberSnapshot = await FirebaseFirestore.instance
          .collection('community_members')
          .where('communityWalletId', isEqualTo: widget.walletId)
          .where('userId', isEqualTo: widget.memberId)
          .get();

      if (memberSnapshot.docs.isNotEmpty) {
        _memberData = memberSnapshot.docs.first.data();
      }

      // Load wallet data
      final walletDoc = await FirebaseFirestore.instance
          .collection('community_wallets')
          .doc(widget.walletId)
          .get();

      if (walletDoc.exists) {
        final data = walletDoc.data()!;
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
      }

    } catch (e) {
      debugPrint('Error loading member data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết thành viên'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_memberData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chi tiết thành viên'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Không tìm thấy thông tin thành viên'),
        ),
      );
    }

    final userId = _memberData!['userId'] ?? '';
    final isRestricted = _memberData!['restricted'] ?? false;

    // Check permissions
    final currentUserId = context.read<AuthProvider>().currentUser?.id;
    final isOwner = _wallet?.ownerId == currentUserId;
    final canManage = isOwner && userId != currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết thành viên'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (canManage)
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: isRestricted ? 'unrestrict' : 'restrict',
                  child: Row(
                    children: [
                      Icon(
                        isRestricted ? Icons.check_circle : Icons.block,
                        color: isRestricted ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(isRestricted ? 'Bỏ hạn chế' : 'Hạn chế'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'kick',
                  child: Row(
                    children: [
                      Icon(Icons.person_remove, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Kick khỏi nhóm'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMemberInfoCard(),
            const SizedBox(height: 16),
            _buildRoleCard(),
            const SizedBox(height: 16),
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildStatsCard(),
            const SizedBox(height: 16),
            _buildRecentTransactionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: FutureBuilder<String>(
                    future: _getMemberDisplayName(_memberData!['userId']),
                    builder: (context, snapshot) {
                      final name = snapshot.data ?? 'U';
                      return Text(
                        name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<String>(
                        future: _getMemberDisplayName(_memberData!['userId']),
                        builder: (context, snapshot) {
                          return Text(
                            snapshot.data ?? 'Đang tải...',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      FutureBuilder<String>(
                        future: _getMemberUniqueId(_memberData!['userId']),
                        builder: (context, snapshot) {
                          return Text(
                            'ID: ${snapshot.data ?? 'Đang tải...'}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Tham gia: ${_formatDate(_parseDateTime(_memberData!['joinedAt']))}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard() {
    final role = _memberData!['role'] ?? 'member';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getRoleIcon(role), color: _getRoleColor(role)),
                const SizedBox(width: 8),
                const Text(
                  'Vai trò',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getRoleColor(role).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _getRoleColor(role)),
              ),
              child: Text(
                _getRoleDisplayName(role),
                style: TextStyle(
                  color: _getRoleColor(role),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getRoleDescription(role),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final isRestricted = _memberData!['restricted'] ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isRestricted ? Icons.block : Icons.check_circle,
                  color: isRestricted ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Trạng thái',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (isRestricted ? Colors.red : Colors.green)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isRestricted ? Colors.red : Colors.green,
                ),
              ),
              child: Text(
                isRestricted ? 'Bị hạn chế' : 'Hoạt động',
                style: TextStyle(
                  color: isRestricted ? Colors.red : Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isRestricted
                  ? 'Thành viên bị hạn chế không thể thực hiện giao dịch chi tiêu'
                  : 'Thành viên có thể thực hiện giao dịch bình thường',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Consumer<CommunityTransactionProvider>(
      builder: (context, provider, child) {
        final memberTransactions = provider
            .getTransactionsForWallet(widget.walletId)
            .where((t) => t.userId == widget.memberId)
            .toList();

        final memberIncome = memberTransactions
            .where((t) => t.isIncome)
            .fold(0.0, (total, t) => total + t.amount);

        final memberExpense = memberTransactions
            .where((t) => t.isExpense)
            .fold(0.0, (total, t) => total + t.amount);

        final netContribution = memberIncome - memberExpense;
        final transactionCount = memberTransactions.length;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics,
                        color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    const Text(
                      'Thống kê trong nhóm',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Thu nhập',
                        '${memberIncome.toStringAsFixed(0)}đ',
                        Icons.trending_up,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatItem(
                        'Chi tiêu',
                        '${memberExpense.toStringAsFixed(0)}đ',
                        Icons.trending_down,
                        Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Đóng góp ròng',
                        '${netContribution.toStringAsFixed(0)}đ',
                        Icons.account_balance_wallet,
                        netContribution >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatItem(
                        'Giao dịch',
                        transactionCount.toString(),
                        Icons.receipt,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsCard() {
    return Consumer<CommunityTransactionProvider>(
      builder: (context, provider, child) {
        final memberTransactions = provider
            .getTransactionsForWallet(widget.walletId)
            .where((t) => t.userId == widget.memberId)
            .take(5)
            .toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    const Text(
                      'Giao dịch gần đây',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (memberTransactions.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Chưa có giao dịch nào',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...memberTransactions.map((transaction) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: transaction.isIncome
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          child: Text(
                            transaction.categoryIcon,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        title: Text(transaction.description),
                        subtitle: Text(
                          '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}',
                        ),
                        trailing: Text(
                          '${transaction.isIncome ? '+' : '-'}${transaction.amount.toStringAsFixed(0)}đ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: transaction.isIncome
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      )),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'restrict':
        _showRestrictDialog();
        break;
      case 'unrestrict':
        _unrestrictMember();
        break;
      case 'kick':
        _showKickDialog();
        break;
    }
  }

  void _showRestrictDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hạn chế thành viên'),
        content: const Text(
          'Bạn có chắc chắn muốn hạn chế thành viên này?\n\n'
          'Thành viên sẽ không thể thêm giao dịch chi tiêu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _restrictMember();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Hạn chế'),
          ),
        ],
      ),
    );
  }

  void _showKickDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kick thành viên'),
        content: const Text(
          'Bạn có chắc chắn muốn kick thành viên này khỏi nhóm?\n\n'
          'Hành động này không thể hoàn tác!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _kickMember();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Kick'),
          ),
        ],
      ),
    );
  }

  Future<void> _restrictMember() async {
    try {
      await FirebaseFirestore.instance
          .collection('community_members')
          .where('communityWalletId', isEqualTo: widget.walletId)
          .where('userId', isEqualTo: widget.memberId)
          .get()
          .then((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.first.reference.update({
            'restricted': true,
            'restrictedAt': Timestamp.now(),
          });
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã hạn chế thành viên'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadData();
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
    }
  }

  Future<void> _unrestrictMember() async {
    try {
      await FirebaseFirestore.instance
          .collection('community_members')
          .where('communityWalletId', isEqualTo: widget.walletId)
          .where('userId', isEqualTo: widget.memberId)
          .get()
          .then((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          return snapshot.docs.first.reference.update({
            'restricted': false,
            'restrictedAt': FieldValue.delete(),
          });
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã bỏ hạn chế thành viên'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
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
    }
  }

  Future<void> _kickMember() async {
    try {
      await FirebaseFirestore.instance
          .collection('community_members')
          .where('communityWalletId', isEqualTo: widget.walletId)
          .where('userId', isEqualTo: widget.memberId)
          .get()
          .then((snapshot) {
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        return batch.commit();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã kick thành viên khỏi nhóm'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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

  Future<String> _getMemberUniqueId(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final uniqueId = userData['uniqueIdentifier'] ?? userData['unique_identifier'];
        if (uniqueId != null && uniqueId.toString().isNotEmpty) {
          return uniqueId.toString();
        }
      }
      return userId.substring(0, 8) + '...';
    } catch (e) {
      return userId.substring(0, 8) + '...';
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
        debugPrint('Error parsing date string: $value, error: $e');
        return DateTime.now();
      }
    } else {
      debugPrint('Unknown date type: ${value.runtimeType}, value: $value');
      return DateTime.now();
    }
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
    switch (role) {
      case 'owner':
        return Icons.star;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
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

  String _getRoleDescription(String role) {
    switch (role) {
      case 'owner':
        return 'Có toàn quyền quản lý ví cộng đồng';
      case 'admin':
        return 'Có thể quản lý thành viên và giao dịch';
      default:
        return 'Có thể xem và thực hiện giao dịch';
    }
  }
}
