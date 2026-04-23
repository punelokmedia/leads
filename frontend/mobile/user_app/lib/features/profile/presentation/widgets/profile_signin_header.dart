import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';

class ProfileSignInHeader extends StatelessWidget {
  const ProfileSignInHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: 60.h, bottom: 30.h, left: 24.w, right: 24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.orange236, AppColors.orange248],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32.r)),
      ),
      child: Column(
        children: [
          Text(
            'My Account',
            style: AppTextStyles.poppins(
              fontSize: 24.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
              height: 20 / 24,
            ),
          ),
          SizedBox(height: 52.h),
          Text(
            'Log in or sign up to view your complete profile',
            textAlign: TextAlign.center,
            style: AppTextStyles.roboto(
              color: AppColors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
              height: 11/16,
              letterSpacing: 0
            ),
          ),
          SizedBox(height: 24.h),
          // Continue to Sign In Button
          ElevatedButton(
            onPressed: () => context.push(AppRouter.login),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.orange248,
              minimumSize: Size(double.infinity, 53.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.r),
              ),
              elevation: 0,
            ),
            child: Text(
              'Continue to sign in',
              style: AppTextStyles.poppins(fontSize: 20.sp, fontWeight: FontWeight.w600,height: 11/20,),
            ),
          ),
        ],
      ),
    );
  }
}