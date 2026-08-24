import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/core/utils/snackbar_helper.dart';
import 'package:user_app/features/auth/shared/auth_providers.dart';
import 'package:user_app/features/cart/shared/cart_providers.dart';
import 'package:user_app/features/home/domain/leads_model.dart';

class LeadPaymentBottomBar extends ConsumerStatefulWidget {
  final LeadModel lead;
  const LeadPaymentBottomBar({super.key, required this.lead});

  @override
  ConsumerState<LeadPaymentBottomBar> createState() =>
      _LeadPaymentBottomBarState();
}

class _LeadPaymentBottomBarState extends ConsumerState<LeadPaymentBottomBar> {
  bool _isAdding = false;

  Future<void> _onPayTap() async {
    if (_isAdding) return;

    final isLoggedIn = ref.read(isLoggedInProvider);
    if (!isLoggedIn) {
      context.push(AppRouter.login);
      return;
    }

    setState(() => _isAdding = true);
    try {
      final message = await ref
          .read(cartControllerProvider.notifier)
          .addLeadToCart(widget.lead);

      if (!mounted) return;

      if (message != null && message.toLowerCase().contains('fail')) {
        SnackbarHelper.showError(context, message);
        return;
      }

      context.push(AppRouter.cartPath);
    } catch (_) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'Unable to start payment. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5DFFF),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Lead Access Cost',
                      style: AppTextStyles.poppins(
                        fontSize: 11.sp,
                        color: const Color(0xFF4224C4),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '₹${widget.lead.originalPrice.toInt()}',
                      style: AppTextStyles.poppins(
                        fontSize: 18.sp,
                        color: const Color(0xFF4224C4),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              flex: 3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton.icon(
                      onPressed: _isAdding ? null : _onPayTap,
                      icon: _isAdding
                          ? SizedBox(
                              width: 18.r,
                              height: 18.r,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(Icons.lock, size: 18.r, color: Colors.white),
                      label: Text(
                        _isAdding ? 'Please wait' : 'Accept & View Contact',
                        style: AppTextStyles.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4224C4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Pay to unlock client contact details',
                    style: AppTextStyles.poppins(
                      fontSize: 9.sp,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
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
