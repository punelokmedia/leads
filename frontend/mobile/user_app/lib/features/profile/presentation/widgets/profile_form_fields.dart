import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';

// ── Shared shadow decoration ──────────────────────────────────────────────────
BoxDecoration cardDeco({double radius = 24}) => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius.r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );

// ── Avatar ────────────────────────────────────────────────────────────────────
class EditProfileAvatar extends StatelessWidget {
  final String? avatarUrl;
  final VoidCallback onEditTap;
  const EditProfileAvatar({super.key, this.avatarUrl, required this.onEditTap});

  @override
  Widget build(BuildContext context) => Center(
        child: Stack(
          children: [
            CircleAvatar(
              radius: 48.r,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              backgroundColor: Colors.grey[200],
              child: avatarUrl == null
                  ? Icon(Icons.person, size: 48.r, color: Colors.grey)
                  : null,
            ),
            Positioned(
              bottom: 0, right: 0,
              child: GestureDetector(
                onTap: onEditTap,
                child: Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8B020), shape: BoxShape.circle),
                  child: Icon(Icons.edit, size: 16.r, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
}

// ── Form label ────────────────────────────────────────────────────────────────
class FormLabel extends StatelessWidget {
  final String text;
  const FormLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTextStyles.poppins(
          fontSize: 15.sp, fontWeight: FontWeight.w500, color: Colors.black87),
      );
}

// ── Update button ─────────────────────────────────────────────────────────────
class UpdateButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const UpdateButton({super.key, required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: isLoading ? null : onTap,
        child: Container(
          width: double.infinity,
          height: 52.h,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFECCC0D), Color(0xFFF8B020)]),
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(color: const Color(0xFFFFC107).withOpacity(0.4),
                  blurRadius: 12, offset: const Offset(0, 4))
            ],
          ),
          child: Center(
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : Text('Update',
                    style: AppTextStyles.poppins(
                      fontSize: 24.sp, fontWeight: FontWeight.w600,
                      color: AppColors.white)),
          ),
        ),
      );
}

// ── Add address row ───────────────────────────────────────────────────────────
class AddAddressRow extends StatelessWidget {
  final VoidCallback onTap;
  const AddAddressRow({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
          decoration: cardDeco(),
          child: Row(
            children: [
              Text('Add Address',
                  style: AppTextStyles.poppins(
                    fontSize: 15.sp, fontWeight: FontWeight.w500,
                    color: Colors.black87)),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 16.r, color: Colors.grey[400]),
            ],
          ),
        ),
      );
}

// ── Password + Change button ──────────────────────────────────────────────────
class PasswordWithChangeButton extends StatelessWidget {
  final bool obscure;
  final VoidCallback onChangeTap;
  const PasswordWithChangeButton({
    super.key, required this.obscure, required this.onChangeTap});

  @override
  Widget build(BuildContext context) => Container(
        decoration: cardDeco(),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: '',
                obscureText: obscure,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  hintStyle: AppTextStyles.poppins(
                    color: AppColors.grey163, fontSize: 20.sp),
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 20.w, vertical: 16.h),
                  border: InputBorder.none,
                ),
              ),
            ),
            GestureDetector(
              onTap: onChangeTap,
              child: Container(
                margin: EdgeInsets.only(right: 8.w),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF8B020), Color(0xFFFDCB52)]),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1),
                        blurRadius: 4, offset: const Offset(0, 2))
                  ],
                ),
                child: Text('Change Password',
                    style: AppTextStyles.poppins(
                      fontSize: 14.sp, color: AppColors.white)),
              ),
            ),
          ],
        ),
      );
}