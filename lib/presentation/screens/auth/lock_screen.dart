import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routes/route_names.dart';
import '../../providers/auth_provider.dart' as app_auth;

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  String _pin = '';
  String? _savedPin;
  bool _isBiometricEnabled = false;
  bool _isPinEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _savedPin = prefs.getString('user_pin');
      _isPinEnabled = prefs.getBool('pin_enabled') ?? false;
      _isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      _isLoading = false;
    });

    // Try biometric first if enabled
    if (_isBiometricEnabled) {
      await _authenticateWithBiometric();
    }
  }

  Future<void> _authenticateWithBiometric() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Xác thực để truy cập ứng dụng',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated && mounted) {
        _navigateToHome();
      }
    } catch (e) {
      debugPrint('Biometric authentication error: $e');
    }
  }

  void _onNumberPressed(String number) {
    if (_pin.length < 6) {
      setState(() {
        _pin += number;
      });

      if (_pin.length == 6) {
        _verifyPin();
      }
    }
  }

  void _onDeletePressed() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  void _verifyPin() {
    if (_pin == _savedPin) {
      _navigateToHome();
    } else {
      setState(() {
        _pin = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mã PIN không đúng'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _navigateToHome() async {
    if (mounted) {
      // Load current user into auth provider
      await context.read<app_auth.AuthProvider>().loadCurrentUser();

      if (mounted) {
        Navigator.pushReplacementNamed(context, RouteNames.home);
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

    // If no security is enabled, go to home directly
    if (!_isPinEnabled && !_isBiometricEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToHome();
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // If only biometric is enabled (no PIN), show biometric only screen
    if (!_isPinEnabled && _isBiometricEnabled) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.fingerprint,
                  size: 100,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Xác thực sinh trắc học',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sử dụng sinh trắc học để mở khóa',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: _authenticateWithBiometric,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Xác thực'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show PIN screen (with optional biometric button)
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),

            const Icon(
              Icons.lock_outline,
              size: 80,
              color: AppColors.primary,
            ),

            const SizedBox(height: 24),

            const Text(
              'Nhập mã PIN',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                final isFilled = index < _pin.length;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? AppColors.primary : AppColors.grey300,
                  ),
                );
              }),
            ),

            const SizedBox(height: 60),

            // Number pad
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                padding: const EdgeInsets.all(20),
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                children: [
                  ...List.generate(9, (index) {
                    final number = (index + 1).toString();
                    return _buildNumberButton(number);
                  }),
                  if (_isBiometricEnabled)
                    _buildBiometricButton()
                  else
                    const SizedBox(),
                  _buildNumberButton('0'),
                  _buildDeleteButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return InkWell(
      onTap: () => _onNumberPressed(number),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.grey300, width: 2),
        ),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return InkWell(
      onTap: _onDeletePressed,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.grey300, width: 2),
        ),
        child: const Center(
          child: Icon(Icons.backspace_outlined, size: 28),
        ),
      ),
    );
  }

  Widget _buildBiometricButton() {
    return InkWell(
      onTap: _authenticateWithBiometric,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: const Center(
          child: Icon(
            Icons.fingerprint,
            size: 32,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
