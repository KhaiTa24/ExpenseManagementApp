import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // Check if user is already logged in
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      // User is logged in, check if PIN/Biometric is enabled
      final prefs = await SharedPreferences.getInstance();
      final isPinEnabled = prefs.getBool('pin_enabled') ?? false;
      final isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      
      if (!mounted) return;
      
      if (isPinEnabled || isBiometricEnabled) {
        // Show lock screen
        Navigator.pushReplacementNamed(context, '/lock');
      } else {
        // Go directly to home
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      // User not logged in, go to login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/ic_launcher.png',
                  width: 100,
                  height: 100,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppConstants.appName,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textWhite,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Quản lý chi tiêu thông minh',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textWhite,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
