import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';

class TermsContentSection extends StatelessWidget {
  final String title;
  final String content;

  const TermsContentSection({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.roboto(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            content,
            style: AppTextStyles.roboto(
              fontSize: 14.sp,
              color: AppColors.grey94,
              height: 1.34, 
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}