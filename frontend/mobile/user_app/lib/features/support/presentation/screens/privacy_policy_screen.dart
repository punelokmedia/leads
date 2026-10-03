import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/features/support/presentation/widgets/terms_content_section.dart';
import 'package:user_app/features/support/data/privacy_policy.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        elevation: 0.4,
        leading: GestureDetector(
          onTap: () {
            if (context.canPop()) context.pop();
          },
          child: Icon(
            Icons.arrow_back_ios_new,
            size: 18.r,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          'Privacy Policy',
          style: AppTextStyles.roboto(
            color: Theme.of(context).colorScheme.primary,
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
            children: [
              for (final section in privacyPolicySections)
                TermsContentSection(
                  title: section.title,
                  content: section.content,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
