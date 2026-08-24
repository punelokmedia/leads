import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/features/support/presentation/widgets/terms_content_section.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFEFD),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0.4,
        leading: GestureDetector(
          onTap: () {
            if (context.canPop()) context.pop();
          },
          child: Icon(
            Icons.arrow_back_ios_new,
            size: 18.r,
            color: AppColors.purple86,
          ),
        ),
        title: Text(
          'Privacy Policy',
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              TermsContentSection(
                title: '1. Information We Collect',
                content:
                    'We collect information you provide when you create an account, complete your profile, request leads, or contact support. This may include your name, phone number, email, business details, and location.',
              ),
              TermsContentSection(
                title: '2. How We Use Your Information',
                content:
                    'We use your information to provide leads, process payments, verify your account, improve the app, and send important updates related to your orders and account activity.',
              ),
              TermsContentSection(
                title: '3. Sharing of Information',
                content:
                    'We do not sell your personal information. We may share data with payment partners, service providers, or when required by law to operate and protect the platform.',
              ),
              TermsContentSection(
                title: '4. Data Security',
                content:
                    'We take reasonable steps to protect your information. You are responsible for keeping your account and device secure.',
              ),
              TermsContentSection(
                title: '5. Contact Us',
                content:
                    'If you have questions about this Privacy Policy, please reach out through Help & Support in the app.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
