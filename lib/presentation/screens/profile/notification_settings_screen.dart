import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/notification_helper.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _dailyReminder = false;
  bool _budgetAlert = false;
  bool _transactionNotification = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _isLoading = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final hasPermission = await NotificationHelper.instance.checkPermissions();
    setState(() {
      _hasPermission = hasPermission;
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyReminder = prefs.getBool('daily_reminder') ?? false;
      _budgetAlert = prefs.getBool('budget_alert') ?? true;
      _transactionNotification = prefs.getBool('transaction_notification') ?? true;
      
      final hour = prefs.getInt('reminder_hour') ?? 20;
      final minute = prefs.getInt('reminder_minute') ?? 0;
      _reminderTime = TimeOfDay(hour: hour, minute: minute);
      
      _isLoading = false;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    }
  }

  Future<void> _toggleDailyReminder(bool value) async {
    if (value && !_hasPermission) {
      final granted = await NotificationHelper.instance.checkPermissions();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cần cấp quyền thông báo để sử dụng tính năng này'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      setState(() => _hasPermission = true);
    }

    setState(() => _dailyReminder = value);
    await _saveSetting('daily_reminder', value);

    if (value) {
      await NotificationHelper.instance.scheduleDailyReminder(
        hour: _reminderTime.hour,
        minute: _reminderTime.minute,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã bật nhắc nhở hàng ngày lúc ${_reminderTime.format(context)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      await NotificationHelper.instance.cancelDailyReminder();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã tắt nhắc nhở hàng ngày'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );

    if (picked != null) {
      setState(() => _reminderTime = picked);
      
      await _saveSetting('reminder_hour', picked.hour);
      await _saveSetting('reminder_minute', picked.minute);

      if (_dailyReminder) {
        await NotificationHelper.instance.scheduleDailyReminder(
          hour: picked.hour,
          minute: picked.minute,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt thông báo'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Cảnh báo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          
          SwitchListTile(
            title: const Text('Cảnh báo ngân sách'),
            subtitle: const Text('Thông báo khi vượt ngân sách'),
            secondary: const Icon(Icons.warning),
            value: _budgetAlert,
            onChanged: (value) async {
              setState(() => _budgetAlert = value);
              await _saveSetting('budget_alert', value);
            },
          ),
          
          const Divider(),
          
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Nhắc nhở',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          
          SwitchListTile(
            title: const Text('Nhắc nhở hàng ngày'),
            subtitle: Text(
              _dailyReminder 
                  ? 'Bật - ${_reminderTime.format(context)}'
                  : 'Tắt',
            ),
            secondary: const Icon(Icons.notifications_active),
            value: _dailyReminder,
            onChanged: _toggleDailyReminder,
          ),
          
          if (_dailyReminder)
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Thời gian nhắc nhở'),
              subtitle: Text(_reminderTime.format(context)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectTime,
            ),
          
          const Divider(),
          
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Giao dịch',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          
          SwitchListTile(
            title: const Text('Thông báo giao dịch'),
            subtitle: const Text('Xác nhận khi thêm/sửa/xóa giao dịch'),
            secondary: const Icon(Icons.receipt_long),
            value: _transactionNotification,
            onChanged: (value) async {
              setState(() => _transactionNotification = value);
              await _saveSetting('transaction_notification', value);
            },
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}