import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Added
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/features/support/shared/custom_pill_button.dart';
import 'package:user_app/features/support/shared/support_provider.dart';

class TermsConditionsScreen extends ConsumerWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAgreed = ref.watch(termsAgreementProvider);

    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Icon(
            Icons.arrow_back_ios_new,
            size: 18.r,
            color: AppColors.purple86,
          ),
        ),
        title: Text(
          "Terms & Conditions",
          style: AppTextStyles.roboto(
            color: AppColors.purple86,
            fontWeight: FontWeight.w600,
            fontSize: 24.sp,
            height: 1,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      "1. Acceptance of Terms",
                      "By using this website or service, you agree to comply with and be bound by these terms and conditions. if you do not agree to these terms, please do not use this website or service.",
                    ),
                    _buildSection(
                      "2. Use of the Service",
                      "You agree to use this website or service only for lawful purposes and in a way that does not infringe upon the rights of others or restricts or inhabit anyone else’s use and enjoyment of the website or service.",
                    ),
                    _buildSection(
                      "3. User Account",
                      "Some features of this website or service may require you to create a user account. You are responsible for maintaining the confidentiality of your account information and for all activities that occur under your account.",
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Checkbox(
                  value: isAgreed,
                  onChanged: (v) =>
                      ref.read(termsAgreementProvider.notifier).state = v!,
                  activeColor: AppColors.purple72,
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: "I agree all the ",
                      style: AppTextStyles.roboto(
                        fontSize: 16.sp,
                        color: AppColors.black,
                        fontWeight: FontWeight.w400,
                        height: 1.34,
                      ),
                      children: [
                        TextSpan(
                          text: "Terms & Conditions",
                          style: AppTextStyles.roboto(
                            color: AppColors.purple75,
                            fontWeight: FontWeight.w400,
                            fontSize: 16.sp,
                            height: 1.34,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              debugPrint("Terms clicked");
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            CustomPillButton(
              text: "Learn More",
              isEnabled: isAgreed,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String body) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h, right: 10.h, left: 10.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.roboto(
              fontWeight: FontWeight.w600,
              fontSize: 18.sp,
              height: 1.34,
              color: AppColors.black,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            body,
            style: AppTextStyles.roboto(
              color: AppColors.grey94,
              fontSize: 16.sp,
              fontWeight: FontWeight.w400,
              height: 1.34,
            ),
          ),
        ],
      ),
    );
  }
}
