import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/core/utils/snackbar_helper.dart';
import 'package:user_app/features/support/presentation/widgets/support_option_tile.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFEFD),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0.4,
        leading: GestureDetector(
          onTap: () => context.pop(),
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
            color: AppColors.purple75,
            fontSize: 22.sp,
            height: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 28.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset(
                'assets/Images/profile/help_support.jpg',
                height: 150.h,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              "How can we help you?",
              style: AppTextStyles.poppins(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              "Quickly get help for payments, orders, account access and technical issues.",
              style: AppTextStyles.poppins(
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.grey117,
                height: 1.4,
              ),
            ),
            SizedBox(height: 18.h),
            SupportOptionTile(
              title: "Report an Error",
              subtitle: "Share screenshots and issue details",
              icon: Icons.bug_report_outlined,
              onTap: () {
                SnackbarHelper.showWarning(
                  context,
                  "Error report feature will be available soon.",
                );
              },
            ),
            SizedBox(height: 12.h),
            SupportOptionTile(
              title: "Payment / Refund Help",
              subtitle: "Raise issue for failed or pending payment",
              icon: Icons.payments_outlined,
              onTap: () {
                SnackbarHelper.showSuccess(
                  context,
                  "Please share your order ID with support team.",
                );
              },
            ),
            SizedBox(height: 12.h),
            SupportOptionTile(
              title: "Account & Login Help",
              subtitle: "Password reset and account access support",
              icon: Icons.lock_outline_rounded,
              onTap: () {
                SnackbarHelper.showWarning(
                  context,
                  "Use Forgot Password from login screen for quick reset.",
                );
              },
            ),
            SizedBox(height: 12.h),
            SupportOptionTile(
              title: "Terms & Privacy",
              subtitle: "Read policy and terms for your account",
              icon: Icons.verified_user_outlined,
              onTap: () => context.push(AppRouter.termsPath),
            ),
            SizedBox(height: 20.h),
            _InfoCard(
              title: "Support Availability",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    label: "Working Hours",
                    value: "Mon - Sat, 10:00 AM to 7:00 PM",
                  ),
                  SizedBox(height: 8.h),
                  _InfoRow(label: "Email", value: "support@leadssell.com"),
                  SizedBox(height: 8.h),
                  _InfoRow(
                    label: "Response Time",
                    value: "Usually within 24 hours",
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              "Frequently Asked Questions",
              style: AppTextStyles.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
            SizedBox(height: 8.h),
            const _FaqTile(
              title: "I completed payment but history is empty.",
              body:
                  "Pull to refresh on History tab. If issue remains, contact support with order ID.",
            ),
            const _FaqTile(
              title: "Why can't I download leads again?",
              body:
                  "For security and data policy, lead file download is allowed one time per paid order.",
            ),
            const _FaqTile(
              title: "How can I change my city filter?",
              body:
                  "Open category or search section and clear selected city chip to load all leads again.",
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.grey229),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.poppins(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          SizedBox(height: 10.h),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: AppTextStyles.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.grey117,
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Text(
            value,
            style: AppTextStyles.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String title;
  final String body;

  const _FaqTile({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey229),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
        childrenPadding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h),
        iconColor: AppColors.grey117,
        collapsedIconColor: AppColors.grey117,
        title: Text(
          title,
          style: AppTextStyles.poppins(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        children: [
          Text(
            body,
            style: AppTextStyles.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.grey117,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
