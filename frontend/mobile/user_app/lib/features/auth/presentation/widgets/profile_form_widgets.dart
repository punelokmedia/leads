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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── External Label ──
        Padding(
          padding: EdgeInsets.only(left: 12.w, bottom: 6.h),
          child: Text(
            label,
            style: AppTextStyles.poppins(
              fontSize: 16.sp,
              color: floatingLabelColor ?? AppColors.grey198, 
              fontWeight: FontWeight.w500,
              height: 20/16,
              letterSpacing: 0.01
            ),
          ),
        ),
        // ── Input Box ──
        _buildContainer(
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: AppTextStyles.poppins(
              fontSize: 16.sp, 
              color: Colors.grey[800], // Darker text for input value
              fontWeight: FontWeight.w500,
            ),
            decoration: _buildInputDecoration(hintText),
          ),
        ),
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── External Label ──
        Padding(
          padding: EdgeInsets.only(left: 12.w, bottom: 6.h),
          child: Text(
            label,
            style: AppTextStyles.poppins(
              fontSize: 14.sp,
              color: AppColors.grey163, 
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // ── Input Box ──
        _buildContainer(
          child: DropdownButtonFormField<String>(
            value: value,
            icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600], size: 24.r),
            style: AppTextStyles.poppins(
              fontSize: 16.sp, 
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
            decoration: _buildInputDecoration(hintText),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: AppTextStyles.poppins(fontSize: 15.sp)),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// ── Shared UI Helpers ──
Widget _buildContainer({required Widget child}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20.r),
      border: Border.all(color:Color.fromRGBO(221,221,221,1), width: 1), // Distinct light grey border
      boxShadow: const [
        BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.25), // Very soft, smooth shadow from design
          blurRadius: 4,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}

InputDecoration _buildInputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: AppTextStyles.poppins(
      fontSize: 15.sp,
      color: AppColors.grey163,
      fontWeight: FontWeight.w400,
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
    border: InputBorder.none, // Hide default border since we use the Container's border
  );
}