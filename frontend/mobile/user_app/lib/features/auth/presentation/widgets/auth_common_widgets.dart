import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';

// ── Logo ──────────────────────────────────────────────────────────────────────
class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key});

  @override
  Widget build(BuildContext context) => Container(
        width: 296.w,
        height: 99.h,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/Images/home/logo_leads.png'),
            fit: BoxFit.contain,
          ),
        ),
      );
}

// ── Primary amber button ──────────────────────────────────────────────────────
class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: isLoading ? null : onTap,
        child: Container(
          width: double.infinity,
          height: 56.h,
          decoration: BoxDecoration(
            color: AppColors.purple73,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Color.fromRGBO(248,182,31,0.58)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4522C2).withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Center(
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                : Text(
                    label,
                    style: AppTextStyles.poppins(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      );
}

// ── Google sign-in button ─────────────────────────────────────────────────────
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onTap;
  const GoogleSignInButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(30.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/Images/login/google.png',
                  height: 19.r,
                  errorBuilder: (_, __, ___) => Icon(
                      Icons.g_mobiledata_rounded, size: 19.r, color: Colors.red)),
              SizedBox(width: 8.w),
              Text('Google',
                  style: AppTextStyles.poppins(
                      fontSize: 16.sp, fontWeight: FontWeight.w500,
                      color: AppColors.grey77, height: 20 / 16, letterSpacing: 0.1)),
            ],
          ),
        ),
      );
}

// ── Or divider ────────────────────────────────────────────────────────────────
class OrDivider extends StatelessWidget {
  final String text;
  const OrDivider({super.key, this.text = 'Or Sign in With'});

  static const _dividerColor = Color.fromRGBO(176, 176, 176, 1);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Expanded(child: Divider(color: _dividerColor, thickness: 1)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Text(text,
                style: AppTextStyles.poppins(
                    fontSize: 14.sp, color: AppColors.grey77,
                    fontWeight: FontWeight.w400, height: 20 / 14, letterSpacing: 0.1)),
          ),
          const Expanded(child: Divider(color: _dividerColor, thickness: 1)),
        ],
      );
}

// ── Error banner ──────────────────────────────────────────────────────────────
class AuthErrorBanner extends StatelessWidget {
  final String message;
  const AuthErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Text(message,
            style: AppTextStyles.poppins(
                fontSize: 14.sp, color: AppColors.red223,
                fontWeight: FontWeight.w500, height: 20 / 14, letterSpacing: 0.1)),
      );
}