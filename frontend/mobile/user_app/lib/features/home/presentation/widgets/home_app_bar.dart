import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int cartCount;
  final VoidCallback onCartTap;

  const HomeAppBar({
    super.key,
    required this.cartCount,
    required this.onCartTap,
  });

  @override
  Size get preferredSize => Size.fromHeight(56.h);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: _LogoTitle(),
      actions: [
        _CartButton(count: cartCount, onTap: onCartTap),
        SizedBox(width: 12.w),
      ],
    );
  }
}

class _LogoTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46.h,
      width: 139.w,
      child: Image.asset(
        "assets/Images/home/logo_leads.png",
        fit: BoxFit.cover,
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _CartButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 46.r,
            height: 45.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.red237, width: 1.5),
            ),
            child: Center(
              child: SvgPicture.asset(
                "assets/Icons/svg/home/cart_icon.svg",
                width: 24.w,
                height: 25.h,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(
                  AppColors.grey102,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),

          //  Badge
          if (count > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: EdgeInsets.all(3.r),
                decoration: const BoxDecoration(
                  color: Color(0xFFE53935),
                  shape: BoxShape.circle,
                ),
                constraints: BoxConstraints(minWidth: 16.r, minHeight: 16.r),
                child: Text(
                  '$count',
                  style: AppTextStyles.poppins(
                    color: Colors.white,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
