// features/auth/presentation/widgets/payment_widgets.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';

// ── 1. Pricing Card Widget ──
class PricingCardWidget extends StatelessWidget {
  const PricingCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          // Purple Header
          Container(
            padding: EdgeInsets.fromLTRB(22.w, 37.h, 22.w, 0),
            decoration: BoxDecoration(
              color: const Color(0xFF4522C2),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(top: 24.h, bottom: 16.h),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
              ),
              child: Column(
                children: [
                  Text(
                    '₹ 1',
                    style: AppTextStyles.poppins(
                      fontSize: 54.sp,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                      height: 1.0,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40.w,
                        height: 1.5,
                        color: const Color(0xFF4522C2),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Text(
                          'ONE TIME PAYMENT',
                          style: AppTextStyles.poppins(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        width: 40.w,
                        height: 1.5,
                        color: const Color(0xFF4522C2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20.h),
          const Divider(),

          // Features List
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20.r),
              ),
            ),
            child: Column(
              children: [
                _buildFeatureRow(context, "Lifetime Access", "No Expiry"),
                _buildFeatureRow(context, "High Quality Leads", "Better ROI"),
                _buildFeatureRow(
                  context,
                  "Trusted Platform",
                  "Verified Vendors",
                ),
                _buildFeatureRow(
                  context,
                  "24/7 Support",
                  "We are here to help",
                ),
                SizedBox(height: 10.h),

                // Best Value Box
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: AppColors.purple73, width: 1),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Best Value",
                            style: AppTextStyles.poppins(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.primary,
                              height: 20 / 16,
                              letterSpacing: 0.01,
                            ),
                          ),
                          Text(
                            "Pay Once, Use Forever !",
                            style: AppTextStyles.poppins(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                              height: 20 / 16,
                              letterSpacing: 0.01,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        height: 30.h,
                        width: 1.5,
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
                      ),
                      SizedBox(width: 12.w),
                      Icon(
                        Icons.verified_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28.r,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context, String title, String subtitle) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Theme.of(context).colorScheme.primary,
            size: 20.r,
          ),
          SizedBox(width: 12.w),
          Text(
            title,
            style: AppTextStyles.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
              height: 20 / 14,
              letterSpacing: 0.01,
            ),
          ),
          const Spacer(),
          Text(
            subtitle,
            style: AppTextStyles.poppins(
              fontSize: 12.sp,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w400,
              height: 20 / 12,
              letterSpacing: 0.01,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 2. Payment Summary Widget ──
class PaymentSummaryWidget extends StatelessWidget {
  const PaymentSummaryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(217, 206, 255, 1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
            ),
            child: Text(
              "Payment Summary",
              style: AppTextStyles.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
                height: 20 / 16,
                letterSpacing: 0.01,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Lifetime membership",
                      style: AppTextStyles.poppins(
                        fontSize: 14.sp,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 20 / 14,
                        letterSpacing: 0.01,
                      ),
                    ),
                    Text(
                      "₹ 1",
                      style: AppTextStyles.poppins(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).colorScheme.primary,
                        height: 20 / 12,
                        letterSpacing: 0.01,
                      ),
                    ),
                  ],
                ),
                Divider(
                  height: 24.h,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total Amount",
                      style: AppTextStyles.poppins(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                        height: 20 / 14,
                        letterSpacing: 0.01,
                      ),
                    ),
                    Text(
                      "₹ 1",
                      style: AppTextStyles.poppins(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                        height: 20 / 12,
                        letterSpacing: 0.01,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 3. Trust Badges Row ──
class TrustBadgesRow extends StatelessWidget {
  const TrustBadgesRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTrustBadge(Icons.lock_outline, "100% Secure\nPayment"),
        Container(
          height: 35.h,
          width: 1,
          color: Theme.of(context).colorScheme.surfaceContainerLow,
        ),
        _buildTrustBadge(
          Icons.currency_rupee,
          "No Hidden\nCharges",
          isOutlined: true,
        ),
        Container(
          height: 35.h,
          width: 1,
          color: Theme.of(context).colorScheme.surfaceContainerLow,
        ),
        _buildTrustBadge(Icons.language, "Trusted by\n10,000+ Vendors"),
      ],
    );
  }

  Widget _buildTrustBadge(
    IconData icon,
    String text, {
    bool isOutlined = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          isOutlined
              ? Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.blue34, width: 1.5),
                  ),
                  child: Icon(icon, color: AppColors.blue34, size: 16.r),
                )
              : Icon(icon, color: AppColors.blue34, size: 26.r),
          SizedBox(height: 6.h),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.poppins(
              fontSize: 10.sp,
              color: AppColors.blue36,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
