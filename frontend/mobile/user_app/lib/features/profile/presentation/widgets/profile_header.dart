import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import '../../domain/profile_model.dart';

class ProfileHeader extends StatelessWidget {
  final ProfileModel profile;
  final VoidCallback onEditProfile;

  const ProfileHeader({
    super.key,
    required this.profile,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: 50.h,
        left: 16.w,
        right: 16.w,
        bottom: 20.h,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.orange236, AppColors.orange248],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30.r),
          bottomRight: Radius.circular(30.r),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Title
          Text(
            "My Account",
            style: AppTextStyles.poppins(
              fontSize: 24.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
              height: 20 / 24,
            ),
          ),

          SizedBox(height: 25.h),

          // 🔹 Profile Row
          Padding(
            padding: EdgeInsets.only(left: 38.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _AvatarCircle(avatarUrl: profile.avatarUrl),

                SizedBox(width: 12.w),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                          height: 27 / 16,
                        ),
                      ),

                      Text(
                        profile.email,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.poppins(
                          fontSize: 12.sp,
                          color: AppColors.white,
                          height: 17 / 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      SizedBox(height: 10.h),

                      _EditProfileButton(onTap: onEditProfile),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final String? avatarUrl;
  const _AvatarCircle({this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80.r, 
      height: 80.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.grey229,
        border: Border.all(color: AppColors.grey77, width: 2),
      ),
    
          child:SvgPicture.asset(
              "assets/Icons/svg/navbar/profile.svg", 
              height: 40.h,
              width: 40.w,
              colorFilter: ColorFilter.mode(
                AppColors.grey77, 
                BlendMode.srcIn,
              ),
            ),
    );
  }
}

class _EditProfileButton extends StatelessWidget {
  final VoidCallback onTap;
  const _EditProfileButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34.h,

        constraints: BoxConstraints(minWidth: 90.w),

        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit, size: 12.r, color: AppColors.red237),
            SizedBox(width: 5.w),
            Text(
              'Edit Profile',
              style: AppTextStyles.roboto(
                fontSize: 14.sp,
                color: AppColors.red237,
                fontWeight: FontWeight.w400,
                height: 11 / 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
