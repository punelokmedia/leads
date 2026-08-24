// features/auth/presentation/screens/complete_payment_screen.dart

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
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
  ConsumerState<CompletePaymentScreen> createState() =>
      _CompletePaymentScreenState();
}

class _CompletePaymentScreenState extends ConsumerState<CompletePaymentScreen> {
  late Razorpay _razorpay;

  // ✅ Local loading flag — avoids conflicts with controller's isLoading
  bool _isPaymentInitializing = false;

  @override
  void initState() {
    super.initState();
    _initRazorpay();
  }

  void _initRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // ── Razorpay Success Handler ──
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final orderId = response.orderId;
    final paymentId = response.paymentId;
    final signature = response.signature;

    if (orderId == null || paymentId == null || signature == null) {
      SnackbarHelper.showError(
        context,
        'Payment succeeded but details are incomplete. Please contact support.',
      );
      return;
    }

    final draft = ref.read(profileDraftProvider);
    final user = ref.read(authControllerProvider).user;
    final city = draft.cityId.isNotEmpty ? draft.cityId : draft.city;
    final fullName = draft.fullName.isNotEmpty
        ? draft.fullName
        : (user?.fullName ?? '');
    final email = draft.email.isNotEmpty ? draft.email : (user?.email ?? '');

    ref.read(authControllerProvider.notifier).verifyPayment(
      orderId: orderId,
      paymentId: paymentId,
      signature: signature,
      fullName: fullName,
      email: email,
      city: city,
      categories: draft.categories,
      businessName: draft.businessName,
      workType: draft.workType,
      onSuccess: () {
        ref.read(authControllerProvider.notifier).clearError();
        ref.read(profileDraftProvider.notifier).clearDraft();
        SnackbarHelper.showSuccess(
          context,
          'Payment Verified & Profile Created!',
        );
        context.go(AppRouter.homePath);
      },
    );
  }

  // ── Razorpay Error Handler ──
  void _handlePaymentError(PaymentFailureResponse response) {
    // ✅ Code 0 = dismissed by user, not a real error
    if (response.code == Razorpay.PAYMENT_CANCELLED) {
      SnackbarHelper.showWarning(context, "Payment cancelled.");
    } else {
      SnackbarHelper.showError(context, "Payment Failed: ${response.message}");
    }
  }

  // ── Razorpay External Wallet Handler ──
  void _handleExternalWallet(ExternalWalletResponse response) {
    SnackbarHelper.showWarning(
      context,
      "External Wallet selected: ${response.walletName}",
    );
  }

  Future<void> _startPayment() async {
    if (_isPaymentInitializing) return;
    setState(() => _isPaymentInitializing = true);

    try {
      final orderData = await ref
          .read(authControllerProvider.notifier)
          .createPaymentOrder();

      if (!mounted) return;
      if (orderData == null) return;

      final user = ref.read(authControllerProvider).user;

      final keyId = orderData['keyId']?.toString();
      // Backend registration order returns `orderId`; cart orders return `razorpayOrderId`.
      final orderId =
          (orderData['orderId'] ?? orderData['razorpayOrderId'])?.toString();
      final currency = orderData['currency']?.toString() ?? 'INR';

      // Registration API already returns amount in paise.
      final rawAmount = orderData['amount'];
      final int amount = (rawAmount is int)
          ? rawAmount
          : (rawAmount is double)
          ? rawAmount.toInt()
          : int.tryParse(rawAmount.toString()) ?? 0;

      log("=== RAZORPAY OPTIONS ===");
      log("key: $keyId");
      log("orderId: $orderId");
      log("amount: $amount (type: ${amount.runtimeType})");
      log("currency: $currency");
      log("=======================");

      if (keyId == null ||
          keyId.isEmpty ||
          orderId == null ||
          orderId.isEmpty ||
          amount == 0) {
        SnackbarHelper.showError(
          context,
          "Invalid order data. Please try again.",
        );
        return;
      }

      // ✅ Validate orderId format — must start with 'order_'
      if (!orderId.startsWith('order_')) {
        SnackbarHelper.showError(context, "Invalid Razorpay order ID format.");
        return;
      }

      final options = <String, dynamic>{
        'key': keyId,
        'amount': amount,
        'currency': currency,
        'name': 'Next Leads',
        'description': 'Registration Fee',
        'order_id': orderId,
        'prefill': <String, dynamic>{
          'contact': user?.phone ?? user?.phoneNumber ?? '',
          'email': user?.email ?? '',
        },
        'retry': <String, dynamic>{'enabled': false},
        'send_sms_hash': true,
        'theme': <String, dynamic>{'color': '#4522C2'},
      };

      // ✅ Re-init Razorpay fresh every time — prevents stale listener issues
      _razorpay.clear();
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;

      _razorpay.open(options);
    } catch (e) {
      debugPrint('Razorpay launch error: $e');
      if (mounted) {
        SnackbarHelper.showError(
          context,
          "Could not initiate payment. Please try again.",
        );
      }
    } finally {
      if (mounted) setState(() => _isPaymentInitializing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    // ✅ Combined loading state — either controller is working OR we're initializing
    final bool showLoader = isLoading || _isPaymentInitializing;

    ref.listen(authControllerProvider, (previous, next) {
      if (next.error != null &&
          next.error!.isNotEmpty &&
          previous?.error != next.error) {
        SnackbarHelper.showError(context, next.error!);
        Future.microtask(
          () => ref.read(authControllerProvider.notifier).clearError(),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.grey102,
            size: 25.r,
          ),
          // ✅ Disable back during payment init to prevent broken states
          onPressed: showLoader ? null : () => context.pop(),
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
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple73,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        elevation: 4,
                      ),
                      onPressed: showLoader ? null : _startPayment,
                      child: showLoader
                          ? SizedBox(
                              height: 24.r,
                              width: 24.r,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
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
