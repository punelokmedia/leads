// widgets/payment_success_header.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';

class PaymentSuccessHeader extends StatelessWidget {
  const PaymentSuccessHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280.h,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 240.h,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFBE48B),
                    Color(0xFFF1F1F1), 
                  ],
                  stops: [0.1,0.99]
                ),
              ),
            ),
          ),
          // Circular Checkmark
          Container(
            width: 127.r,
            height: 127.r,
            decoration: BoxDecoration(
              color: const Color(0xFFF8B020),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(0,0,0,0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.check_rounded,
              size: 80.r,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// widgets/payment_info_section.dart
class PaymentInfoSection extends StatelessWidget {
  final String amount;
  final String paidTo;
  final String upiId;
  final String dateTime;

  const PaymentInfoSection({
    super.key,
    required this.amount,
    required this.paidTo,
    required this.upiId,
    required this.dateTime,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Payment\nSuccessful',
          textAlign: TextAlign.center,
          style: AppTextStyles.roboto(
            fontSize: 36.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.orange248,
            height: 1,
            letterSpacing: 0.06
          ),
        ),
        SizedBox(height: 68.h),
        Text(
          '₹$amount',
          style: AppTextStyles.roboto(
            fontSize: 48.sp,
            height: 0.1,
            fontWeight: FontWeight.w600,
            color: AppColors.grey102,
          ),
        ),
        SizedBox(height: 43.h),
        Text(
          'Paid to',
          style: AppTextStyles.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.w400,
            color: AppColors.black,
            height: 1,

          ),
        ),
        SizedBox(height: 6.h),
        Text(
          paidTo,
          style: AppTextStyles.poppins(
            fontSize: 24.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.grey77,
            height: 1
          ),
        ),
        SizedBox(height: 26.h),
        Text(
          upiId,
          style: AppTextStyles.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.w400,
            color: AppColors.grey77,
            height: 0.144,
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          dateTime,
          style: AppTextStyles.poppins(
            fontSize: 20.sp,
            fontWeight: FontWeight.w400,
            color: AppColors.black,
            height: 1
          ),
        ),
      ],
    );
  }
}