import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';

// ── Generic menu row ──────────────────────────────────────────────────────────
class ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool hasBorder;

  const ProfileMenuTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 62.h,
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: AppColors.grey198),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.25),
              blurRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 24.r, color: AppColors.grey102),
            SizedBox(width: 24.w),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey102,
                  height: 13 / 18,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 24.r,
              color: AppColors.grey102,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Log Out tile (red accent) ─────────────────────────────────────────────────
class ProfileLogoutTile extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;
  final bool isEnabled;

  const ProfileLogoutTile({
    super.key,
    required this.onTap,
    this.isLoading = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: (isLoading || !isEnabled) ? null : onTap,
        child: Container(
          height: 62.h,
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(color: AppColors.grey198),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(0, 0, 0, 0.25),
                blurRadius: 4,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                size: 24.r,

                color: isEnabled ? AppColors.red237 : Colors.grey,
              ),
              SizedBox(width: 20.w),
              Expanded(
                child: Text(
                  'Log Out',
                  style: AppTextStyles.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,

                    color: isEnabled ? AppColors.red237 : Colors.grey,
                    height: 13 / 18,
                  ),
                ),
              ),
              if (isLoading)
                SizedBox(
                  width: 18.r,
                  height: 18.r,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.red[400],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shimmer skeleton for header + menu ────────────────────────────────────────
class ProfileShimmer extends StatefulWidget {
  const ProfileShimmer({super.key});

  @override
  State<ProfileShimmer> createState() => _ProfileShimmerState();
}

class _ProfileShimmerState extends State<ProfileShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _box({double? width, required double height, bool circle = false}) =>
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: circle ? null : BorderRadius.circular(6.r),
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Opacity(
        opacity: _anim.value,
        child: Column(
          children: [
            // Header skeleton
            Container(
              height: 210.h,
              color: AppColors.grey198,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _box(width: 72.r, height: 72.r, circle: true),
                    SizedBox(height: 10.h),
                    _box(width: 130.w, height: 14.h),
                    SizedBox(height: 6.h),
                    _box(width: 190.w, height: 11.h),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),
            for (int i = 0; i < 3; i++) ...[
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: _box(width: double.infinity, height: 14.h),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
