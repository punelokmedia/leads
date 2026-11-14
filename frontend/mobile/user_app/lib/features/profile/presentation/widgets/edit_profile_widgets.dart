import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';

class EditProfileAvatar extends StatelessWidget {
  const EditProfileAvatar({super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: CircleAvatar(
      radius: 48.r,
      child: Icon(Icons.person, size: 48.r),
    ),
  );
}

class UpdateButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;

  const UpdateButton({super.key, required this.onTap, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 57.h,
        decoration: BoxDecoration(
          color: AppColors.orange248,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.orange255),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.25),
              offset: Offset(0, 4.h),
              blurRadius: 4.r,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  height: 24.h,
                  width: 24.h,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Update',
                  style: AppTextStyles.poppins(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                    letterSpacing: 0.1,
                    height: 20 / 20,
                  ),
                ),
        ),
      ),
    );
  }
}

class ChangePasswordField extends StatefulWidget {
  const ChangePasswordField({
    super.key,
    required this.controller,
    required this.hintText,
    this.validator,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;
  final bool enabled;

  @override
  State<ChangePasswordField> createState() => _ChangePasswordFieldState();
}

class _ChangePasswordFieldState extends State<ChangePasswordField> {
  bool _obscure = true;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    obscureText: _obscure,
    enabled: widget.enabled,
    validator: widget.validator,
    autocorrect: false,
    enableSuggestions: false,
    style: const TextStyle(
      fontFamily: 'ProfileMontserrat',
      fontSize: 13,
      color: Color(0xFF0F172A),
    ),
    decoration: InputDecoration(
      hintText: widget.hintText,
      hintStyle: const TextStyle(
        fontFamily: 'ProfileMontserrat',
        fontSize: 13,
        color: Color(0xFF9CA3AF),
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      prefixIcon: Padding(
        padding: const EdgeInsets.all(12),
        child: SvgPicture.asset(
          'assets/figma/password-lock.svg',
          width: 20,
          height: 20,
        ),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 44, maxWidth: 44),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0066FF), width: 1.5),
      ),
      suffixIcon: IconButton(
        tooltip: _obscure ? 'Show password' : 'Hide password',
        onPressed: widget.enabled
            ? () => setState(() => _obscure = !_obscure)
            : null,
        icon: _obscure
            ? SvgPicture.asset(
                'assets/figma/password-eye-off.svg',
                width: 20,
                height: 20,
              )
            : const Icon(
                Icons.visibility_outlined,
                size: 20,
                color: Color(0xFF0F172A),
              ),
      ),
    ),
  );
}
