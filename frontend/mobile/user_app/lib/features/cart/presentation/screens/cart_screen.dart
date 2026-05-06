import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/core/utils/snackbar_helper.dart';
import 'package:user_app/features/auth/shared/auth_providers.dart';
import 'package:user_app/features/profile/shared/profile_providers.dart';
import '../../shared/cart_providers.dart';
import '../widgets/cart_item_card.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cartControllerProvider.notifier).loadCart();
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // ── PAYMENT HANDLERS ───────────────────────────────────────────────────────

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final internalId = await ref
        .read(cartControllerProvider.notifier)
        .verifyFinalPayment(response);

    if (internalId != null && mounted) {
      context.go(AppRouter.paymentsuccessPath, extra: internalId);
    } else if (mounted) {
      _showSnack("Payment verification failed", isError: true);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _showSnack("Payment failed: ${response.message}", isError: true);
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (isError) {
      SnackbarHelper.showError(context, msg);
    } else {
      SnackbarHelper.showSuccess(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(cartIsLoadingProvider);
    final items = ref.watch(cartItemsProvider);
    final error = ref.watch(cartErrorProvider);
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final notifier = ref.read(cartControllerProvider.notifier);

    final profileState = ref.watch(profileControllerProvider);
    final userProfile = profileState.profile;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18.r,
            color: Colors.black87,
          ),
        ),
        title: Text(
          'Cart',
          style: AppTextStyles.poppins(
            fontSize: 24.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
            letterSpacing: 0.01,
            height: 20 / 24,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: SvgPicture.asset(
              "assets/Icons/svg/home/search_icon.svg",
              height: 19.h,
              width: 19.w,
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFC107)),
            )
          : error != null
          ? Center(
              child: Text(
                error,
                style: AppTextStyles.poppins(
                  fontSize: 13.sp,
                  color: Colors.red,
                ),
              ),
            )
          : items.isEmpty
          ? _EmptyCartView()
          : ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              itemCount: items.length,
              itemBuilder: (_, i) => CartItemCard(
                item: items[i],
                onToggleSelect: () => notifier.toggleSelect(items[i].id),
                onDelete: () => notifier.deleteItem(items[i].id),
                onAddToCart: () => notifier.addToCart(items[i].id),
              ),
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                child: Container(
                  width: double.infinity,
                  height: 60.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.r),
                    color: AppColors.purple73,
                    // gradient: const LinearGradient(
                    //   begin: Alignment.topCenter,
                    //   end: Alignment.bottomCenter,
                    //   colors: [Color(0xFFFFD54F), Color(0xFFF8B020)],
                    // ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      // 1. Auth Guard
                      if (!isLoggedIn) {
                        context.push(AppRouter.login);
                        return;
                      }

                      // 2. Local check (Are any items selected?)
                      final selected = items
                          .where((e) => e.isSelected)
                          .toList();
                      if (selected.isEmpty) {
                        _showSnack(
                          "Please select at least one lead",
                          isError: true,
                        );
                        return;
                      }

                      // 3. Start Razorpay Process
                      await notifier.startPaymentProcess(
                        onError: (msg) => _showSnack(msg, isError: true),
                        onOrderCreated: (data) {
                          String rawPhone = userProfile?.phoneNumber ?? '';
                          // Remove all spaces, dashes, parentheses, etc.
                          String cleanPhone = rawPhone.replaceAll(
                            RegExp(r'[^\d+]'),
                            '',
                          );

                          if (cleanPhone.startsWith('+91')) {
                            cleanPhone = cleanPhone.substring(3);
                          } else if (cleanPhone.startsWith('91') &&
                              cleanPhone.length == 12) {
                            cleanPhone = cleanPhone.substring(2);
                          }

                          var options = {
                            'key': 'rzp_test_SeWKWcDgYE86DN',
                            'amount': data['amount'],
                            'name': 'Leads Sell',
                            'order_id': data['razorpayOrderId'],
                            'currency': 'INR',
                            'timeout': 300,
                            'prefill': {
                              'name': userProfile?.fullName ?? '',
                              'email': userProfile?.email ?? '',
                              'contact': cleanPhone,
                            },
                          };
                          try {
                            _razorpay.open(options);
                          } catch (e) {
                            debugPrint("Error opening Razorpay: $e");
                            _showSnack(
                              "Unable to launch payment gateway",
                              isError: true,
                            );
                          }
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                    ),
                    child: Text(
                      'Proceed to Pay',
                      style: AppTextStyles.poppins(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                        height: 1.0,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _EmptyCartView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            "assets/Icons/svg/home/cart_icon.svg",
            height: 100.h,
            width: 100.h,
          ),
          SizedBox(height: 10.h),
          Text(
            'Your cart is empty',
            style: AppTextStyles.poppins(fontSize: 18.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
