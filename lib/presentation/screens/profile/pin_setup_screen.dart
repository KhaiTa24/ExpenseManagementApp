import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  bool _isPinEnabled = false;
  bool _isLoading = true;
  bool _isSettingUp = false;
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _loadPinStatus();
  }

  Future<void> _loadPinStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isPinEnabled = prefs.getBool('pin_enabled') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _togglePin(bool value) async {
    if (value) {
      setState(() => _isSettingUp = true);
    } else {
      await _disablePin();
    }
  }

  Future<void> _disablePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_pin');
    await prefs.setBool('pin_enabled', false);
    
    setState(() {
      _isPinEnabled = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tắt mã PIN')),
      );
    }
  }

  void _onNumberPressed(String number) {
    setState(() {
      if (_isConfirming) {
        if (_confirmPin.length < 6) {
          _confirmPin += number;
          if (_confirmPin.length == 6) {
            _verifyPin();
          }
        }
      } else {
        if (_pin.length < 6) {
          _pin += number;
          if (_pin.length == 6) {
            _isConfirming = true;
          }
        }
      }
    });
  }

  void _onDeletePressed() {
    setState(() {
      if (_isConfirming) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      } else {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      }
    });
  }

  Future<void> _verifyPin() async {
    if (_pin != _confirmPin) {
      setState(() {
        _confirmPin = '';
        _isConfirming = false;
        _pin = '';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mã PIN không khớp. Vui lòng thử lại'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_pin', _pin);
      await prefs.setBool('pin_enabled', true);

      if (mounted) {
        setState(() {
          _isPinEnabled = true;
          _isSettingUp = false;
          _pin = '';
          _confirmPin = '';
          _isConfirming = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thiết lập mã PIN thành công'),
            backgroundColor: AppColors.success,
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
      // No need to set loading false here
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isSettingUp) {
      return _buildPinSetupView();
    }

    return _buildPinManagementView();
  }

  Widget _buildPinManagementView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mã PIN'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            
            const Icon(
              Icons.pin_outlined,
              size: 100,
              color: AppColors.primary,
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Mã PIN 6 số',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Text(
              'Sử dụng mã PIN để bảo vệ ứng dụng của bạn',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            
            const SizedBox(height: 40),
            
            Card(
              child: SwitchListTile(
                title: const Text('Bật mã PIN'),
                subtitle: Text(
                  _isPinEnabled
                      ? 'Đã bật mã PIN'
                      : 'Tắt mã PIN',
                ),
                value: _isPinEnabled,
                onChanged: _togglePin,
              ),
            ),
            
            const SizedBox(height: 24),
            
            if (_isPinEnabled)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bạn sẽ cần nhập mã PIN khi mở ứng dụng',
                        style: TextStyle(
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinSetupView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thiết lập mã PIN'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            setState(() {
              _isSettingUp = false;
              _pin = '';
              _confirmPin = '';
              _isConfirming = false;
            });
          },
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          
          Text(
            _isConfirming ? 'Xác nhận mã PIN' : 'Nhập mã PIN (6 số)',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // PIN dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              final currentPin = _isConfirming ? _confirmPin : _pin;
              final isFilled = index < currentPin.length;
              
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
                const SizedBox(), // Empty space
                _buildNumberButton('0'),
                _buildDeleteButton(),
              ],
            ),
          ),
        ],
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
}
