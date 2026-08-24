import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/core/widgets/app_network_image.dart';

class EditProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final VoidCallback onEditTap;

  const EditProfileAvatar({super.key, this.avatarUrl, required this.onEditTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Main Circle Avatar
          Container(
            width: 91.r,
            height: 91.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.grey229,
              border: Border.all(
                color: AppColors.orange248,
                width: 2, 
              ),
            ),
            child: Center(
              child: avatarUrl != null && avatarUrl!.trim().isNotEmpty
                  ? ClipOval(
                      child: AppNetworkImage(
                        url: avatarUrl,
                        width: 91.r,
                        height: 91.r,
                        fit: BoxFit.cover,
                        errorWidget: SvgPicture.asset(
                          "assets/Icons/svg/navbar/profile.svg",
                          height: 48.75.h,
                          width: 39.w,
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
                  : SvgPicture.asset(
                      "assets/Icons/svg/navbar/profile.svg",
                      height: 48.75.h, 
                      width: 39.w,
                      fit: BoxFit.contain,
                    ),
            ),
          ),
          SizedBox(height:10.h),
        ],
      ),
    );
  }
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
          border: Border.all(
            color: AppColors.orange255,
          ),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0,0,0,0.25), 
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
                    height: 20/20
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
  });

  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;

  @override
  State<ChangePasswordField> createState() => _ChangePasswordFieldState();
}

class _ChangePasswordFieldState extends State<ChangePasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: widget.controller,
        obscureText: _obscure,
        validator: widget.validator,
        style: TextStyle(fontSize: 14.sp, color: Colors.black87),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide:
                const BorderSide(color: Color(0xFFFFC107), width: 1.5),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.grey[400],
              size: 20.r,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
      ),
    );
  }
}
