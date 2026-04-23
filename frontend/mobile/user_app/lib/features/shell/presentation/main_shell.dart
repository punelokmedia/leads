import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;
  static const double _navDesignHeight = 74;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: navigationShell,
      extendBody: false,
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(10.w, 0, 10.w, (8.h + bottomInset)),
        child: Container(
          height: _navDesignHeight.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32.r),
            border: Border.all(color: const Color(0xFFFFB800), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 14,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildNavItem(
                index: 0,
                label: 'History',
                iconPath: "assets/Icons/svg/navbar/history.svg",
              ),
              _buildDivider(),
              _buildNavItem(
                index: 1,
                label: 'Home',
                iconPath: "assets/Icons/svg/navbar/home.svg",
              ),
              _buildDivider(),
              _buildNavItem(
                index: 2,
                label: 'My Account',
                iconPath: "assets/Icons/svg/navbar/profile.svg",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required String iconPath,
  }) {
    final bool isSelected = navigationShell.currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 24.w,
              height: 24.h,
              colorFilter: ColorFilter.mode(
                isSelected ? Colors.black87 : Colors.grey.shade600,
                BlendMode.srcIn,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.black87 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 2,
      height: 40.h,
      color: Colors.grey.shade300,
    );
  }
}