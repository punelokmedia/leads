import 'package:user_app/core/network/dio_provider.dart';
import 'package:user_app/features/payments/presentation/widgets/wallet_card.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/theme/app_colors.dart';
import 'package:user_app/core/theme/app_text_styles.dart';
import 'package:user_app/core/utils/snackbar_helper.dart';
import 'package:user_app/features/auth/shared/auth_providers.dart';
import '../../shared/cart_providers.dart';
import '../widgets/cart_item_card.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cartControllerProvider.notifier).loadCart();
    });
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

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        elevation: 0.5,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18.r,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        title: Text(
          'Cart',
          style: AppTextStyles.poppins(
            fontSize: 24.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
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
              itemCount: items.length + 1,
              itemBuilder: (_, index) {
                if (index == 0) return const WalletCard();
                final i = index - 1;
                return CartItemCard(
                  item: items[i],
                  onToggleSelect: () => notifier.toggleSelect(items[i].id),
                  onDelete: () => notifier.deleteItem(items[i].id),
                  onAddToCart: () => notifier.addToCart(items[i].id),
                );
              },
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
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: (isLoading || _purchasing)
                        ? null
                        : () async {
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

                            if (_purchasing) return;
                            setState(() => _purchasing = true);
                            try {
                              final response = await ref
                                  .read(dioProvider)
                                  .post(
                                    'api/v1/wallet/purchase',
                                    data: {
                                      'leadIds': selected
                                          .map((e) => e.id)
                                          .toList(),
                                    },
                                  );
                              ref.invalidate(walletProvider);
                              await notifier.loadCart();
                              if (!mounted) return;
                              this.context.go(
                                AppRouter.paymentsuccessPath,
                                extra: response.data['data']['orderId']
                                    .toString(),
                              );
                            } catch (error) {
                              if (!mounted) return;
                              _showSnack(
                                'Purchase failed. Check membership and wallet balance, then refresh before retrying.',
                                isError: true,
                              );
                            } finally {
                              if (mounted) setState(() => _purchasing = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                    ),
                    child: Text(
                      'Pay from wallet',
                      style: AppTextStyles.poppins(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
            style: AppTextStyles.poppins(
              fontSize: 18.sp,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
