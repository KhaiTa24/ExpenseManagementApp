import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/firestore_notification_provider.dart';
import '../../providers/auth_provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListening();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _startListening() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    if (userId != null) {
      context
          .read<FirestoreNotificationProvider>()
          .startListeningToNotifications(userId);
      context
          .read<FirestoreNotificationProvider>()
          .startListeningToPendingInvitations(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông Báo'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Thông báo'),
            Tab(text: 'Lời mời'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _startListening,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationsTab(),
          _buildInvitationsTab(),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return Consumer<FirestoreNotificationProvider>(
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
                Text('Có lỗi xảy ra: ${provider.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _startListening,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        final notifications = provider.notifications;

        if (notifications.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Chưa có thông báo nào'),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return _buildNotificationCard(notification);
          },
        );
      },
    );
  }

  Widget _buildInvitationsTab() {
    return Consumer<FirestoreNotificationProvider>(
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
                Text('Có lỗi xảy ra: ${provider.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _startListening,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }

        final invitations = provider.pendingInvitations;

        if (invitations.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mail_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Chưa có lời mời nào'),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: invitations.length,
          itemBuilder: (context, index) {
            final invitation = invitations[index];
            return _buildInvitationCard(invitation);
          },
        );
      },
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['is_read'] ?? false;
    final createdAt =
        (notification['created_at'] as Timestamp?)?.toDate() ?? DateTime.now();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isRead ? null : Colors.blue[50],
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isRead ? Colors.grey : Colors.blue,
          child: Icon(
            _getNotificationIcon(notification['type']),
            color: Colors.white,
          ),
        ),
        title: Text(
          notification['title'] ?? 'Thông báo',
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification['message'] ?? ''),
            const SizedBox(height: 4),
            Text(
              timeago.format(createdAt, locale: 'vi'),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        onTap: () {
          if (!isRead) {
            context
                .read<FirestoreNotificationProvider>()
                .markAsRead(notification['id']);
          }
        },
      ),
    );
  }

  Widget _buildInvitationCard(Map<String, dynamic> invitation) {
    final createdAt =
        (invitation['created_at'] as Timestamp?)?.toDate() ?? DateTime.now();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: const Icon(Icons.group_add, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lời mời tham gia ví cộng đồng',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${invitation['inviter_name']} mời bạn tham gia "${invitation['wallet_name']}"',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeago.format(createdAt, locale: 'vi'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _rejectInvitation(invitation['id']),
                  child: const Text('Từ chối'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _acceptInvitation(invitation['id']),
                  child: const Text('Chấp nhận'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptInvitation(String invitationId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    if (userId == null) return;

    final success = await context
        .read<FirestoreNotificationProvider>()
        .acceptInvitation(invitationId, userId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Đã chấp nhận lời mời!'
              : 'Không thể chấp nhận lời mời'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectInvitation(String invitationId) async {
    final success = await context
        .read<FirestoreNotificationProvider>()
        .rejectInvitation(invitationId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              success ? 'Đã từ chối lời mời!' : 'Không thể từ chối lời mời'),
          backgroundColor: success ? Colors.orange : Colors.red,
        ),
      );
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'community_invitation':
        return Icons.group_add;
      case 'transaction':
        return Icons.payment;
      case 'budget':
        return Icons.account_balance_wallet;
      default:
        return Icons.notifications;
    }
  }
}
