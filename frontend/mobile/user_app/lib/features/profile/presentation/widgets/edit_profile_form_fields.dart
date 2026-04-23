import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import '../../domain/edit_profile_model.dart';

// ── Section label ─────────────────────────────────────────────────────────────
class FormLabel extends StatelessWidget {
  final String text;
  const FormLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 24.w, bottom: 8.h),
      child: Text(
        text,
        style: AppTextStyles.poppins(
          fontSize: 18.sp,
          fontWeight: FontWeight.w500,
          color: AppColors.grey77,
          height: 20 / 18,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

// ── Plain text field ──────────────────────────────────────────────────────────
class ProfileTextField extends StatelessWidget {
  final String hint;
  final String initialValue;
  final ValueChanged<String>? onChanged;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final bool readOnly;

  const ProfileTextField({
    super.key,
    required this.hint,
    required this.initialValue,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        initialValue: initialValue,
        onChanged: onChanged,
        keyboardType: keyboardType,
        obscureText: obscureText,
        readOnly: readOnly,
        style: AppTextStyles.poppins(
          fontSize: 15.sp,
          color: AppColors.grey163,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.poppins(
            fontSize: 15.sp,
            color: AppColors.grey163.withOpacity(0.7),
            fontWeight: FontWeight.w400,
          ),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 20.w,
            vertical: 16.h,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.r),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

// ── Mobile field with country code prefix ─────────────────────────────────────
class MobileNumberField extends StatelessWidget {
  final String countryCode;
  final String phone;
  final ValueChanged<String> onPhoneChanged;
  final ValueChanged<String> onCodeChanged;

  const MobileNumberField({
    super.key,
    required this.countryCode,
    required this.phone,
    required this.onPhoneChanged,
    required this.onCodeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showCodePicker(context),
            child: Container(
              constraints: BoxConstraints(minWidth: 72.w),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.grey.shade100, width: 1.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    (countryCode.isEmpty) ? "+91" : countryCode,
                    style: AppTextStyles.poppins(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey163,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18.r,
                    color: AppColors.grey163,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              key: ValueKey(phone),
              initialValue: phone,
              onChanged: (v) {
                if (v.length <= 10) onPhoneChanged(v);
              },
              // maxLength: 10
              keyboardType: TextInputType.phone,
              style: AppTextStyles.poppins(
                color: AppColors.grey163,
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Enter phone number',
                hintStyle: TextStyle(
                  color: Colors.grey.shade300,
                  fontSize: 14.sp,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCodePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) => ListView(
        shrinkWrap: true,
        children: ['+91', '+1', '+44', '+971'].map((code) {
          return ListTile(
            title: Text(code, style: AppTextStyles.poppins(fontSize: 14.sp)),
            onTap: () {
              onCodeChanged(code);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }
}

// ── City dropdown ─────────────────────────────────────────────────────────────
class CityDropdown extends StatelessWidget {
  final String selectedCity;
  final ValueChanged<String> onChanged;

  const CityDropdown({
    super.key,
    required this.selectedCity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: kAvailableCities.contains(selectedCity)
              ? selectedCity
              : kAvailableCities.first,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey[600],
            size: 20.r,
          ),
          style: TextStyle(fontSize: 14.sp, color: Colors.black87),
          items: kAvailableCities
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }
}
