import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/core/utils/intl_helper.dart';
import 'package:user_app/features/cart/presentation/screens/download_leads.dart';
import 'package:user_app/features/cart/presentation/widgets/payment_widgets.dart';
import 'package:user_app/features/cart/shared/cart_providers.dart';

class PaymentSuccessScreen extends ConsumerWidget {
  final String orderId;
  const PaymentSuccessScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Accessing the lastOrderDetails from the CartState
    final cartState = ref.watch(cartControllerProvider);
    final details = cartState.lastOrderDetails;

    // Use your custom utility function to format the date from the state
    // We provide a fallback if the date is null or not a string
    final String displayDate = formatIsoDate(
      details?['date']?.toString() ?? '',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1), 
      body: Stack(
        children: [
          Column(
            children: [
              const PaymentSuccessHeader(),

              SizedBox(height: 40.h),
              PaymentInfoSection(
                amount: '${details?['amount'] ?? '0.00'}',
                paidTo: 'Leads Solution .in',
                upiId: '${details?['paymentId'] ?? 'N/A'}',
                dateTime: displayDate,
              ),

              SizedBox(height: 50.h),

              // 3. Action Button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 40.h),
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          DownloadLeadsDialog(orderId: orderId),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 60.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8B020),
                      borderRadius: BorderRadius.circular(30.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Download your Leads',
                      style: AppTextStyles.poppins(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          //  CLOSE BUTTON (TOP RIGHT)
          Positioned(
            top: 60.h,
            right: 30.w,
            child: GestureDetector(
              onTap: () {
                context.go(AppRouter.homePath); 
              },
              child: SizedBox(
                width: 40.r,
                height: 40.r,

                child: Icon(Icons.close, size: 30.r, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
