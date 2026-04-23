import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/features/support/presentation/widgets/support_option_tile.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(252, 254, 253, 1),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        leading: GestureDetector(
          onTap: ()=>context.pop(),
          child: Icon(
            Icons.arrow_back_ios_new,
            size: 18.r,
            color: AppColors.grey143,
          ),
        ),
        centerTitle: true,
        title: Text(
          "Help & Support",
          style: AppTextStyles.roboto(
            color: AppColors.orange248,
            fontSize: 24.sp,
            height: 1,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          children: [
            SizedBox(height: 40.h),
            Image.asset(
              'assets/Images/profile/help_support.jpg',
              height: 179.h,
            ), 
            SizedBox(height: 40.h),
            SupportOptionTile(
              title: "Report an Error",
              icon: Icons.error_outline,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
