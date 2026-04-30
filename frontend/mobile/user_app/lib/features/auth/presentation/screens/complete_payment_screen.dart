// features/auth/presentation/screens/complete_payment_screen.dart

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart'; // ✅ Import Razorpay
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/core/utils/snackbar_helper.dart';
import 'package:user_app/features/auth/presentation/widgets/payment_widgets.dart';
import 'package:user_app/features/auth/shared/profile_draft_provider.dart';
import '../../shared/auth_providers.dart';

class CompletePaymentScreen extends ConsumerStatefulWidget {
  const CompletePaymentScreen({super.key});

  @override
  ConsumerState<CompletePaymentScreen> createState() => _CompletePaymentScreenState();
}

class _CompletePaymentScreenState extends ConsumerState<CompletePaymentScreen> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    
    // Attach Razorpay Event Listeners
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear(); // Remove listeners when screen is destroyed
    super.dispose();
  }

  // ── Razorpay Success Handler ──
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    // ✅ 1. Read all the data collected from the previous screens!
    final draft = ref.read(profileDraftProvider);

    // ✅ 2. Call the verify API with BOTH payment and profile details
    ref.read(authControllerProvider.notifier).verifyPayment(
      orderId: response.orderId!,
      paymentId: response.paymentId!,
      signature: response.signature!,
      fullName: draft.fullName,
      email: draft.email,
      city: draft.city,
      categories: draft.categories,
      businessName: draft.businessName,
      workType: draft.workType,
      onSuccess: () {
        ref.read(authControllerProvider.notifier).clearError();
        
        // ✅ 3. ONLY clear the draft once payment is 100% verified
        ref.read(profileDraftProvider.notifier).clearDraft(); 
        
        SnackbarHelper.showSuccess(context, "Payment Verified & Profile Created!");
        context.go(AppRouter.homePath); 
      },
    );
  }

  // ── Razorpay Error Handler ──
  void _handlePaymentError(PaymentFailureResponse response) {
    SnackbarHelper.showError(context, "Payment Failed: ${response.message}");
  }

  // ── Razorpay External Wallet Handler ──
  void _handleExternalWallet(ExternalWalletResponse response) {
    SnackbarHelper.showWarning(context, "External Wallet selected: ${response.walletName}");
  }

  // ── Main Payment Flow ──
  Future<void> _startPayment() async {
    // 1. Call API to get Order ID & Keys
    final orderData = await ref.read(authControllerProvider.notifier).createPaymentOrder();
    
    if (orderData == null) return; // Error is already handled by the controller

    // Optional: Pre-fill user data if available in your user state
    final user = ref.read(authControllerProvider).user;
    log("User No: ${user!.phone}");
    log("User Number: ${user.phoneNumber}");

    // 2. Setup Razorpay Options
    var options = {
      'key': orderData['keyId'],
      'amount': orderData['amount'],
      'currency': orderData['currency'],
      'name': 'Next Leads',
      'description': 'Registration Fee',
      'order_id': orderData['orderId'],
      'prefill': {
        'contact': user?.phone ?? '', 
        'email': user?.email ?? '',
      },
      'theme': {
        'color': '#4522C2'
      }
    };

    // 3. Open Checkout
    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error launching Razorpay: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    // Listen for backend errors globally
    ref.listen(authControllerProvider, (previous, next) {
      if (next.error != null && next.error!.isNotEmpty && previous?.error != next.error) {
        SnackbarHelper.showError(context, next.error!);
        Future.microtask(() => ref.read(authControllerProvider.notifier).clearError());
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.grey102, size: 25.r),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Complete Payment',
          style: AppTextStyles.poppins(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
            height: 20 / 24,
            letterSpacing: 0.01,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: Column(
                  children: [
                    const PricingCardWidget(),
                    SizedBox(height: 24.h),
                    const PaymentSummaryWidget(),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),

            // ── Bottom Footer ──
            Container(
              padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 20.h),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Payment Button
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple73,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        elevation: 4,
                      ),
                      // ✅ Trigger Payment Flow
                      onPressed: isLoading ? null : _startPayment,
                      child: isLoading 
                          ? SizedBox(height: 24.r, width: 24.r, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              "Pay  ₹499 Securely",
                              style: AppTextStyles.poppins(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                height: 20 / 16,
                                letterSpacing: 0.01,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Trust Badges
                  const TrustBadgesRow(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}