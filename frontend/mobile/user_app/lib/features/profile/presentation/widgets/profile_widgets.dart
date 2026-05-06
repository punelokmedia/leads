import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/features/profile/shared/profile_providers.dart'
    show profileControllerProvider;
import '../../domain/profile_model.dart';

class ProfileAppBar extends StatelessWidget {
  const ProfileAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 22.r,
              color: Colors.black87,
            ),
            onPressed: () {},
          ),
          Expanded(
            child: Center(
              child: Text(
                'My Profile',
                style: AppTextStyles.poppins(
                  fontSize: 24.sp,
                  height: 20 / 24,
                  letterSpacing: 0.01,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          SizedBox(width: 48.w),
        ],
      ),
    );
  }
}

class AvatarHeader extends StatelessWidget {
  final ProfileModel profile;
  const AvatarHeader({super.key, required this.profile});

  String get _initials {
    if (profile.firstname.isEmpty) return '';
    if (profile.lastname.isEmpty) return profile.firstname[0].toUpperCase();
    return '${profile.firstname[0]}${profile.lastname[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 45.r,
          backgroundColor: const Color(0xFFEEEDFE),
          child: Text(
            _initials,
            style: AppTextStyles.poppins(
              fontSize: 24.sp,
              fontWeight: FontWeight.w600,
              color: const Color.fromRGBO(83, 74, 183, 1),
            ),
          ),
        ),
        SizedBox(width: 20.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.fullName,
                style: AppTextStyles.roboto(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue28,
                  height: 1,
                  letterSpacing: 0.01,
                ),
              ),
              SizedBox(height: 9.h),
              Text(
                profile.phoneNumber,
                style: AppTextStyles.poppins(
                  fontSize: 14.sp,
                  color: AppColors.purple73,
                  height: 1,
                  letterSpacing: 0.01,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 5.h),
              Text(
                profile.email,
                style: AppTextStyles.poppins(
                  fontSize: 12.sp,
                  color: AppColors.grey137,
                  fontWeight: FontWeight.w500,
                  height: 20 / 12,
                  letterSpacing: 0.01,
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                profile.cityName,
                style: AppTextStyles.poppins(
                  fontSize: 12.sp,
                  color: AppColors.grey137,
                  letterSpacing: 0.01,
                  height: 14 / 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class EditButton extends StatelessWidget {
  const EditButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRouter.editProfilePath),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: AppColors.purple73,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 2.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Edit',
              style: AppTextStyles.roboto(
                color: Colors.white,
                fontSize: 16.sp,
                height: 20 / 16,
                letterSpacing: 0.01,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              Icons.mode_edit_outline_rounded,
              size: 15.r,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class LabeledCard extends StatelessWidget {
  final String label;
  final String value;
  const LabeledCard({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 6.h),
          child: Text(
            label,
            style: AppTextStyles.poppins(
              fontSize: 12.sp,
              color: AppColors.grey137,
              height: 20 / 12,
              letterSpacing: 0.01,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: Colors.grey.shade200, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(0, 0, 0, 0.25),
                blurRadius: 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            value,
            style: AppTextStyles.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              height: 20 / 16,
              color: const Color(0xFF424242),
            ),
          ),
        ),
      ],
    );
  }
}

class LogoutTile extends StatelessWidget {
  final VoidCallback onTap;
  const LogoutTile({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: Colors.grey.shade200, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.red237, size: 20.r),
            SizedBox(width: 12.w),
            Text(
              'Logout',
              style: AppTextStyles.poppins(
                color: AppColors.red237,
                fontSize: 20.sp,
                height: 1,
                letterSpacing: 0.01,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileIllustration extends StatelessWidget {
  const ProfileIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/Images/profile/profile_illustration.png',
        height: 170.h,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 170.h,
          width: 170.w,
          color: Colors.grey[300],
          child: Center(
            child: Text("Illustration", style: TextStyle(fontSize: 12.sp)),
          ),
        ),
      ),
    );
  }
}

class ProfileShimmerLoading extends StatelessWidget {
  const ProfileShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10.h),
            Row(
              children: [
                CircleAvatar(radius: 45.r, backgroundColor: Colors.white),
                SizedBox(width: 20.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 160.w,
                        height: 20.h,
                        color: Colors.white,
                      ),
                      SizedBox(height: 9.h),
                      Container(
                        width: 120.w,
                        height: 14.h,
                        color: Colors.white,
                      ),
                      SizedBox(height: 5.h),
                      Container(
                        width: 140.w,
                        height: 12.h,
                        color: Colors.white,
                      ),
                      SizedBox(height: 3.h),
                      Container(
                        width: 100.w,
                        height: 12.h,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            Divider(height: 2.h, thickness: 2.h, color: Colors.white),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 150.w, height: 22.h, color: Colors.white),
                Container(
                  width: 70.w,
                  height: 32.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            _buildShimmerField(),
            SizedBox(height: 16.h),
            _buildShimmerField(),
            SizedBox(height: 16.h),
            _buildShimmerField(),
            SizedBox(height: 30.h),
            Container(
              width: double.infinity,
              height: 50.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            SizedBox(height: 40.h),
            Container(
              width: double.infinity,
              height: 170.h,
              color: Colors.white,
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 100.w, height: 10.h, color: Colors.white),
        SizedBox(height: 6.h),
        Container(
          width: double.infinity,
          height: 50.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      ],
    );
  }
}

class LogoutConfirmationDialog extends ConsumerWidget {
  const LogoutConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
        // ✅ 3px border with specific color from your Figma
        side: BorderSide(color: const Color(0xFF8981A4), width: 3.w),
      ),
      backgroundColor: Colors.white,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 30.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Title ──
            Text(
              'Logout',
              style: AppTextStyles.poppins(
                fontSize: 24.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.black,
                height: 20 / 24,
                letterSpacing: 0.01,
              ),
            ),
            SizedBox(height: 20.h),

            // ── Illustration ──
            // Replace with your actual asset path for the lock/key illustration
            Image.asset(
              'assets/Images/profile/logout_illustrations.png',
              height: 120.h,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.lock_person_rounded,
                size: 80.r,
                color: const Color(0xFF4A2CD9),
              ),
            ),
            SizedBox(height: 20.h),

            // ── Subtitle ──
            Text(
              'Are you sure you want to\nlogout?',
              textAlign: TextAlign.center,
              style: AppTextStyles.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.grey102,
                height: 19/16,
                letterSpacing: 0.01
              ),
            ),
            SizedBox(height: 30.h),

            // ── Logout Button ──
            SizedBox(
              width: double.infinity,
              height: 44.h,
              child: OutlinedButton(
                onPressed: () {
                  ref.read(profileControllerProvider.notifier).logout(() {
                    Navigator.of(context).pop();
                    context.go(
                      AppRouter.login,
                    ); 
                  });
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: const Color(0xFFD32F2F),
                    width: 1.5.w,
                  ), // Red border
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  backgroundColor: Colors.white,
                ),
                child: Text(
                  'Logout',
                  style: AppTextStyles.poppins(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    height: 19/20,
                    letterSpacing: 0.01,
                    color: AppColors.red237,
                  ), // Red text
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
