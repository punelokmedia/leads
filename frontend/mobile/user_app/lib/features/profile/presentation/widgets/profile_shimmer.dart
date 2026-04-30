import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class ProfileHeaderShimmer extends StatelessWidget {
  const ProfileHeaderShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          top: 60.h,
          bottom: 30.h,
          left: 24.w,
          right: 24.w,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32.r)),
        ),
        child: Row(
          children: [
            // Avatar Circle
            Container(
              width: 80.r,
              height: 80.r,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 16.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name line
                Container(width: 120.w, height: 20.h, color: Colors.white),
                SizedBox(height: 8.h),
                // Email line
                Container(width: 150.w, height: 14.h, color: Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
