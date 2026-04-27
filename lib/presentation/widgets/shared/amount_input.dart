import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

class AmountInput extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? errorText;
  final void Function(String)? onChanged;
  final bool isIncome;

  const AmountInput({
    super.key,
    required this.controller,
    this.label,
    this.errorText,
    this.onChanged,
    this.isIncome = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      onChanged: onChanged,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: isIncome ? AppColors.income : AppColors.expense,
      ),
      decoration: InputDecoration(
        labelText: label ?? 'Số tiền',
        errorText: errorText,
        prefixIcon: Icon(
          Icons.attach_money,
          color: isIncome ? AppColors.income : AppColors.expense,
        ),
        suffixText: 'VND',
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isIncome ? AppColors.income : AppColors.expense,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.grey300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isIncome ? AppColors.income : AppColors.expense,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }
}
