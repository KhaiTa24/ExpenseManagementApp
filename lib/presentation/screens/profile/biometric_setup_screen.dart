import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';

class BiometricSetupScreen extends StatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isLoading = false;
  bool _canCheckBiometrics = false;
  bool _isBiometricEnabled = false;
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _checkBiometricSupport();
    _loadBiometricStatus();
  }

  Future<void> _checkBiometricSupport() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      setState(() {
        _canCheckBiometrics = canCheck;
        _availableBiometrics = availableBiometrics;
      });
    } catch (e) {
      debugPrint('Error checking biometric support: $e');
    }
  }

  Future<void> _loadBiometricStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      await _enableBiometric();
    } else {
      await _disableBiometric();
    }
  }

  Future<void> _enableBiometric() async {
    setState(() => _isLoading = true);

    try {
      // Check if biometric is enrolled
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      if (availableBiometrics.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng thiết lập sinh trắc học trong cài đặt hệ thống trước'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 4),
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Xác thực để bật sinh trắc học',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('biometric_enabled', true);
        
        setState(() {
          _isBiometricEnabled = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã bật xác thực sinh trắc học'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } on PlatformException catch (e) {
      String message = 'Lỗi xác thực sinh trắc học';
      
      if (e.code == 'NotAvailable') {
        message = 'Sinh trắc học không khả dụng trên thiết bị này';
      } else if (e.code == 'NotEnrolled') {
        message = 'Vui lòng thiết lập sinh trắc học trong cài đặt hệ thống';
      } else if (e.code == 'LockedOut') {
        message = 'Quá nhiều lần thử. Vui lòng thử lại sau';
      } else if (e.code == 'PermanentlyLockedOut') {
        message = 'Sinh trắc học đã bị khóa. Vui lòng mở khóa trong cài đặt';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _disableBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', false);
    
    setState(() {
      _isBiometricEnabled = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã tắt xác thực sinh trắc học'),
        ),
      );
    }
  }

  String _getBiometricTypeText() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Vân tay';
    } else if (_availableBiometrics.contains(BiometricType.iris)) {
      return 'Mống mắt';
    }
    return 'Sinh trắc học';
  }

  IconData _getBiometricIcon() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return Icons.face;
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    }
    return Icons.security;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác thực sinh trắc học'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_canCheckBiometrics
              ? _buildNotSupportedView()
              : _buildBiometricView(),
    );
  }

  Widget _buildNotSupportedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 24),
            const Text(
              'Thiết bị không hỗ trợ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Thiết bị của bạn không hỗ trợ xác thực sinh trắc học hoặc chưa được thiết lập.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          
          Icon(
            _getBiometricIcon(),
            size: 100,
            color: AppColors.primary,
          ),
          
          const SizedBox(height: 24),
          
          Text(
            _getBiometricTypeText(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Sử dụng ${_getBiometricTypeText().toLowerCase()} để đăng nhập nhanh chóng và bảo mật',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 40),
          
          Card(
            child: SwitchListTile(
              title: Text('Bật ${_getBiometricTypeText()}'),
              subtitle: Text(
                _isBiometricEnabled
                    ? 'Đã bật xác thực sinh trắc học'
                    : 'Tắt xác thực sinh trắc học',
              ),
              value: _isBiometricEnabled,
              onChanged: _toggleBiometric,
            ),
          ),
          
          const SizedBox(height: 24),
          
          if (_isBiometricEnabled)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bạn có thể sử dụng ${_getBiometricTypeText().toLowerCase()} để đăng nhập vào ứng dụng',
                      style: const TextStyle(
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 24),
          
          if (!_isBiometricEnabled && _availableBiometrics.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Chưa thiết lập sinh trắc học',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Để sử dụng tính năng này, vui lòng:\n'
                    '1. Mở Cài đặt hệ thống\n'
                    '2. Vào Bảo mật → Sinh trắc học\n'
                    '3. Thiết lập vân tay hoặc Face ID\n'
                    '4. Quay lại ứng dụng và bật lại',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          
        ],
      ),
    );
  }
}
