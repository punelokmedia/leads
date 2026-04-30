import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/core/theme/app_text_styles.dart';

class _C {
  static const purpleLight = Color(0xFF5B34C9);
  static const inactiveColor = Color(0xFF9E9E9E);
}

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Matches the design: Home · Leads · Payments · Profile
  static const _items = [
    _NavItem(label: 'Home', iconData: Icons.home_rounded),
    _NavItem(label: 'Leads', iconData: Icons.leaderboard_rounded),
    _NavItem(label: 'Payments', iconData: Icons.credit_card_rounded),
    _NavItem(label: 'Profile', iconData: Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: navigationShell,
      extendBody: true,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, (12.h + bottomInset)),
        child: Container(
          height: 64.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: _C.purpleLight.withValues(alpha: 0.14),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: List.generate(_items.length, (i) {
              final selected = navigationShell.currentIndex == i;
              return _NavButton(
                item: _items[i],
                isSelected: selected,
                onTap: () => navigationShell.goBranch(
                  i,
                  initialLocation: i == navigationShell.currentIndex,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isSelected
                ? _C.purpleLight.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                child: item.iconPath != null
                    ? SvgPicture.asset(
                        item.iconPath!,
                        width: 22.w,
                        height: 22.h,
                        colorFilter: ColorFilter.mode(
                          isSelected ? _C.purpleLight : _C.inactiveColor,
                          BlendMode.srcIn,
                        ),
                      )
                    : Icon(
                        item.iconData,
                        size: 22.r,
                        color: isSelected ? _C.purpleLight : _C.inactiveColor,
                      ),
              ),
              SizedBox(height: 3.h),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: AppTextStyles.poppins(
                  fontSize: 10.sp,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected ? _C.purpleLight : _C.inactiveColor,
                ),
                child: Text(item.label, maxLines: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final String? iconPath;
  final IconData? iconData;

  const _NavItem({required this.label, this.iconData, this.iconPath});
}
