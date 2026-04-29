// features/auth/presentation/widgets/profile_form_widgets.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';

class CustomProfileTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final Color? floatingLabelColor;

  const CustomProfileTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.floatingLabelColor,
  });

  @override
  Widget build(BuildContext context) {
    return _buildContainer(
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: AppTextStyles.poppins(fontSize: 16.sp, color: Colors.black),
        decoration: _buildInputDecoration(label, hintText, floatingLabelColor),
      ),
    );
  }
}

class CustomProfileDropdown extends StatelessWidget {
  final String label;
  final String hintText;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const CustomProfileDropdown({
    super.key,
    required this.label,
    required this.hintText,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _buildContainer(
      child: DropdownButtonFormField<String>(
        value: value,
        icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600], size: 24.r),
        style: AppTextStyles.poppins(fontSize: 16.sp, color: Colors.black),
        decoration: _buildInputDecoration(label, hintText, null),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item, style: AppTextStyles.poppins(fontSize: 15.sp)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// ── Shared UI Helpers ──
Widget _buildContainer({required Widget child}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12.r),
      border: Border.all(color: Colors.grey[300]!, width: 1.0),
      boxShadow: const [
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.05), // Soft shadow from design
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}

InputDecoration _buildInputDecoration(String label, String hint, Color? labelColor) {
  return InputDecoration(
    labelText: label,
    labelStyle: AppTextStyles.poppins(
      fontSize: 15.sp,
      color: labelColor ?? AppColors.grey163,
      fontWeight: FontWeight.w400,
    ),
    hintText: hint,
    hintStyle: AppTextStyles.poppins(
      fontSize: 15.sp,
      color: AppColors.grey163,
    ),
    floatingLabelBehavior: FloatingLabelBehavior.always,
    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
    border: InputBorder.none,
  );
}