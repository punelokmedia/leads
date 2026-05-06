import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/core/utils/snackbar_helper.dart';
import 'package:user_app/features/home/domain/leads_model.dart';

class LeadPaymentBottomBar extends StatefulWidget {
  final LeadModel lead;
  const LeadPaymentBottomBar({super.key,required this.lead});

  @override
  State<LeadPaymentBottomBar> createState() => _LeadPaymentBottomBarState();
}

class _LeadPaymentBottomBarState extends State<LeadPaymentBottomBar> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    // ✅ Call your backend here to verify payment & unlock contact
    SnackbarHelper.showSuccess(context, "Payment Successful! Contact Unlocked.");
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    SnackbarHelper.showError(context, "Payment Failed: ${response.message}");
  }

  void _openRazorpay() {
    // ⚠️ Replace with order creation API call from your backend
    var options = {
      'key': 'rzp_test_YOUR_KEY_HERE', // Replace with your Razorpay Key
      'amount': '${widget.lead.originalPrice.toInt()}', // Amount in paise (500 * 100)
      'name': 'Lead Access',
      'description': 'Unlock client contact details',
      'prefill': {'contact': '9999999999', 'email': 'test@user.com'},
      'theme': {'color': '#4224C4'}
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // ── Left: Cost Box ──
            Expanded(
              flex: 2,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(color: const Color(0xFFE5DFFF), borderRadius: BorderRadius.circular(8.r)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Lead Access Cost', style: AppTextStyles.poppins(fontSize: 11.sp, color: const Color(0xFF4224C4), fontWeight: FontWeight.w700)),
                    SizedBox(height: 2.h),
                    Text('₹${widget.lead.originalPrice.toInt()}', style: AppTextStyles.poppins(fontSize: 18.sp, color: const Color(0xFF4224C4), fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
            SizedBox(width: 12.w),
            
            // ── Right: Pay Button ──
            Expanded(
              flex: 3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton.icon(
                      onPressed: _openRazorpay, // ✅ Triggers Razorpay
                      icon: Icon(Icons.lock, size: 18.r, color: Colors.white),
                      label: Text('Accept & View Contact', style: AppTextStyles.poppins(fontSize: 13.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4224C4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Pay to unlock client contact details',
                    style: AppTextStyles.poppins(fontSize: 9.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}