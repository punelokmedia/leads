import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';

class SupportOptionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const SupportOptionTile({
    super.key, 
    required this.title, 
    required this.icon, 
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0,0,0,0.25), 
              blurRadius: 4,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            
            Container(
              width: 54.r,
              height: 54.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE8E8E8), 
                border: Border.all(
                  color: const Color(0xFFF8B020), 
                  width: 1.2,
                ),
              ),
              child: Icon(
                icon, 
                color: const Color(0xFF636363), 
                size: 28.r,
              ),
            ),
            SizedBox(width: 16.w),
          
            Expanded(
              child: Text(
                title, 
                style: AppTextStyles.poppins(
                  fontSize: 22.sp, 
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}