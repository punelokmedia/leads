import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/core/utils/snackbar_helper.dart';

class PaymentBottomSheet extends StatefulWidget {
  final VoidCallback onPaymentSuccess;
  final String userPhone;
  final String userEmail;

  const PaymentBottomSheet({
    super.key,
    required this.onPaymentSuccess,
    required this.userPhone,
    required this.userEmail,
  });

  @override
  State<PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<PaymentBottomSheet> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear(); // Removes all listeners
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    // 1. Close the bottom sheet
    Navigator.pop(context);
    // 2. Trigger the actual registration backend call
    widget.onPaymentSuccess();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    // Payment failed or user cancelled. The bottom sheet stays open.
    SnackbarHelper.showError(
      context,
      "Payment failed: ${response.message ?? 'Cancelled'}",
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    SnackbarHelper.showWarning(context, "External wallet selected");
  }

  void _openRazorpay() {
    var options = {
      'key': 'rzp_test_YOUR_KEY_HERE', // ⚠️ Replace with your live/test key
      'amount': 49900, // Amount in paise (499.0 * 100)
      'name': 'Interior Wala',
      'description': 'One Time Entry Fee',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {'contact': widget.userPhone, 'email': widget.userEmail},
      'theme': {
        'color': '#0B3A3A', // Matches your Confirm button color
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border.all(color: AppColors.grey143),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.white, const Color(0xFFF9E899)],
          stops: const [0.0, 0.7, 1.0],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag Handle ──
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              SizedBox(height: 49.h),

              // ── Header Row ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Payment Process",
                    style: AppTextStyles.poppins(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                      height: 20 / 24,
                      letterSpacing: 0.01,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(4.r),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                      child: Icon(
                        Icons.close,
                        size: 16.r,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 54.h),

              // ── Illustration (Replace with your actual image path) ──
              Image.asset(
                "assets/Images/login/payment.png",
                height: 132.h,
                width: 224.w,
              ),
              // Icon(Icons.payments_outlined, size: 80.r, color: Colors.grey[400]),
              // Image.asset("assets/images/payment_illustration.png", height: 120.h),
              SizedBox(height: 16.h),

              // ── Description ──
              Text(
                "Thanks for choosing Interior wala App for \n the leads, please proceed with \n the payment to one time entry",
                textAlign: TextAlign.center,
                style: AppTextStyles.poppins(
                  fontSize: 16.sp,
                  color: AppColors.grey77,
                  height: 28 / 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 30.h),

              // ── Fee Breakdown Card ──
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: AppColors.grey175),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "One Time Entry Fee",
                          style: AppTextStyles.poppins(
                            color: AppColors.grey137,
                            fontSize: 16.sp,
                            height: 20 / 16,
                            letterSpacing: 0.01,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          "₹499.0",
                          style: AppTextStyles.poppins(
                            color: AppColors.grey137,
                            fontSize: 16.sp,
                            height: 20 / 16,
                            letterSpacing: 0.01,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "GST",
                          style: AppTextStyles.poppins(
                            color: AppColors.grey137,
                            fontSize: 16.sp,
                            height: 20 / 16,
                            letterSpacing: 0.01,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          "₹0.00",
                          style: AppTextStyles.poppins(
                            color: AppColors.grey137,
                            fontSize: 16.sp,
                            height: 20 / 16,
                            letterSpacing: 0.01,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: Divider(color: AppColors.grey175),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total Amount",
                          style: AppTextStyles.poppins(
                            color: AppColors.black,
                            fontSize: 20.sp,
                            height: 20 / 20,
                            letterSpacing: 0.01,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "₹499.0",
                          style: AppTextStyles.poppins(
                            fontWeight: FontWeight.w400,
                            fontSize: 24.sp,
                            color: Color.fromRGBO(49, 159, 67, 1),
                            height: 20 / 24,
                            letterSpacing: 0.01,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // ── Secure Transaction Banner ──
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F6F4),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Color.fromRGBO(175, 235, 240, 1)),
                ),
                child: Row(
                  children: [
                    SvgPicture.asset( 
                      "assets/Icons/svg/login/security.svg",
                      height:24.h,
                      width: 24.h,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Secure Transaction",
                            style: AppTextStyles.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.sp,
                            ),
                          ),
                          Text(
                            "Encrypted payment powered by Industry Standards",
                            style: AppTextStyles.poppins(
                              fontSize: 10.sp,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // ── Confirm & Pay Button ──
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: _openRazorpay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B3A3A), // Dark teal color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    "Confirm & Pay",
                    style: AppTextStyles.poppins(
                      fontSize: 16.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
