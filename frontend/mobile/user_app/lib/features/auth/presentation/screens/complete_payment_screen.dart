import 'package:user_app/core/network/dio_provider.dart';
import 'package:user_app/features/payments/presentation/widgets/wallet_card.dart';
// features/auth/presentation/screens/complete_payment_screen.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/core/utils/snackbar_helper.dart';
import 'package:user_app/features/auth/presentation/widgets/payment_widgets.dart';
import '../../shared/auth_providers.dart';

class CompletePaymentScreen extends ConsumerStatefulWidget {
  const CompletePaymentScreen({super.key});

  @override
  ConsumerState<CompletePaymentScreen> createState() =>
      _CompletePaymentScreenState();
}

class _CompletePaymentScreenState extends ConsumerState<CompletePaymentScreen> {
  bool _isPaymentInitializing = false;

  Future<void> _startPayment() async {
    if (_isPaymentInitializing) return;
    setState(() => _isPaymentInitializing = true);
    try {
      await ref.read(dioProvider).post('api/v1/wallet/membership');
      ref.invalidate(walletProvider);
      if (!mounted) return;
      SnackbarHelper.showSuccess(context, 'Lifetime membership activated!');
      context.go(AppRouter.cartPath);
    } catch (_) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'Add sufficient money to your wallet, then retry.',
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
          'Lifetime membership',
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
                    const WalletCard(),
                    const Text(
                      'Pay ₹1 once before your first lead purchase. Lifetime access with no recurring subscription. Lead prices are separate.',
                    ),
                    SizedBox(height: 16.h),
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
                    color: Colors.black.withValues(alpha: 0.05),
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
                              'Pay ₹1 from wallet',
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
