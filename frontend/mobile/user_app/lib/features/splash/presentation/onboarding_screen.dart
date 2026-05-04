import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/flutter_svg.dart'; // ✅ Added flutter_svg import
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 34.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 40.h),

              // ── Title ──
              Text(
                "High Quality Leads &\nValue Projects",
                textAlign: TextAlign.center,
                style: AppTextStyles.poppins(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.normal,
                  color: AppColors.black,
                  height: 37 / 32,
                ),
              ),

              SizedBox(height: 40.h),

              // ── Illustration ──
              Image.asset(
                'assets/Images/login/onboard_illustration.png',
                height: 163.h,
                fit: BoxFit.contain,
              ),

              SizedBox(height: 21.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ✅ Converted to SVG (Update path to your shield/security svg)
                  SvgPicture.asset(
                    'assets/Icons/svg/onboard/security.svg',
                    height: 22.sp,
                    width: 22.sp,
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    "Only 2 Vendors per Lead",
                    style: AppTextStyles.poppins(
                      fontSize: 16.sp,
                      color: AppColors.purple73,
                      fontWeight: FontWeight.w400,
                      height: 34 / 16,
                      letterSpacing: 0.01,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 50.h),

              // ── Feature List ──
              // ✅ Updated to pass SVG paths instead of Icons
              _buildFeatureItem(
                'assets/Icons/svg/onboard/globe.svg',
                "1000+ Cities Coverage",
              ),
              _buildFeatureItem(
                'assets/Icons/svg/onboard/vendors.svg',
                "Trusted by 10.000+ Vendors",
              ),
              _buildFeatureItem(
                'assets/Icons/svg/onboard/quality.svg',
                "High Quality Leads",
              ),
              _buildFeatureItem(
                'assets/Icons/svg/onboard/roi.png',
                "Better ROI",
              ),

              const Spacer(),

              // ── Get Started Button ──
              SizedBox(
                width: double.infinity,
                height: 67.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple73,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  onPressed: () async {
                    //  1. Mark onboarding as complete in local storage
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('has_seen_onboarding', true);

                    // 2. Navigate to Login screen
                    if (context.mounted) {
                      context.go(AppRouter.login);
                    }
                  },
                  child: Text(
                    "Get Started",
                    style: AppTextStyles.poppins(
                      color: Colors.white,
                      fontSize: 24.sp,
                      height: 34 / 24,
                      letterSpacing: 0.01,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String imagePath, String text) {
    // Check if the file is an SVG
    final isSvg = imagePath.toLowerCase().endsWith('.svg');

    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Row(
        children: [
          isSvg
              ? SvgPicture.asset(
                  imagePath,
                  height: 28.r,
                  width: 28.r,
                  // Uncomment the line below if you want to force the SVGs to be grey
                  // colorFilter: ColorFilter.mode(Colors.grey[500]!, BlendMode.srcIn),
                )
              : Image.asset(
                  imagePath,
                  height: 28.r,
                  width: 28.r,
                  fit: BoxFit
                      .contain, // Ensures normal images fit perfectly in the 28x28 box
                ),
          SizedBox(width: 16.w),

          Expanded(
            // Added Expanded to prevent text overflow on smaller screens
            child: Text(
              text,
              style: AppTextStyles.poppins(
                fontSize: 20.sp,
                color: AppColors.grey77,
                fontWeight: FontWeight.w400,
                height: 33 / 20,
                letterSpacing: 0.01,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
