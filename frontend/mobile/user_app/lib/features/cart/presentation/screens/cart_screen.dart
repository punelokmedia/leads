import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/errors/error_handler.dart';
import 'package:user_app/core/utils/snackbar_helper.dart';
import 'package:user_app/features/auth/shared/auth_providers.dart';
import 'package:user_app/features/cart/domain/cart_model.dart';
import 'package:user_app/features/payments/presentation/widgets/wallet_card.dart';

import '../../shared/cart_providers.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});
  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  static const blue = Color(0xFF0066FF);
  static const navy = Color(0xFF081744);
  static const muted = Color(0xFF7484A7);
  bool purchasing = false, clearing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(cartControllerProvider.notifier).loadCart(),
    );
  }

  String money(num? value) => '₹ ${(value ?? 0).toStringAsFixed(0)}';
  void message(String text, {bool error = false}) => error
      ? SnackbarHelper.showError(context, text)
      : SnackbarHelper.showSuccess(context, text);

  Future<void> clear(List<CartLead> items) async {
    if (clearing) return;
    setState(() => clearing = true);
    try {
      final controller = ref.read(cartControllerProvider.notifier);
      for (final item in List<CartLead>.of(items)) {
        await controller.deleteItem(item.id);
      }
      if (mounted) message('Cart cleared');
    } catch (error) {
      if (mounted) message(ErrorHandler.handle(error).message, error: true);
    } finally {
      if (mounted) setState(() => clearing = false);
    }
  }

  Future<void> checkout(List<CartLead> items) async {
    final selected = items.where((item) => item.isSelected).toList();
    if (selected.isEmpty) {
      message('Please select at least one lead', error: true);
      return;
    }
    if (!ref.read(isLoggedInProvider)) {
      context.push(AppRouter.login);
      return;
    }
    if (purchasing) return;
    setState(() => purchasing = true);
    try {
      final orderId = await ref
          .read(cartRepositoryProvider)
          .purchaseSelected(selected);
      ref.invalidate(walletProvider);
      await ref.read(cartControllerProvider.notifier).loadCart();
      if (mounted) context.go(AppRouter.paymentsuccessPath, extra: orderId);
    } catch (error) {
      await ref.read(cartControllerProvider.notifier).loadCart();
      if (mounted) message(ErrorHandler.handle(error).message, error: true);
    } finally {
      if (mounted) setState(() => purchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(cartIsLoadingProvider);
    final items = ref.watch(cartItemsProvider);
    final error = ref.watch(cartErrorProvider);
    final notices = ref.watch(cartControllerProvider).availabilityMessages;
    final total = items
        .where((item) => item.isSelected)
        .fold<num>(0, (sum, item) => sum + ((item.price ?? 0) * item.quantity));
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFF),
      body: SafeArea(
        bottom: false,
        child: loading && items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : error != null && items.isEmpty
            ? _error(error)
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 7, 16, 126),
                children: [
                  _header(),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cart',
                              style: TextStyle(
                                color: navy,
                                fontSize: 29,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Review the selected leads before purchasing.',
                              style: TextStyle(color: muted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (items.isNotEmpty)
                        TextButton.icon(
                          onPressed: clearing ? null : () => clear(items),
                          icon: const Icon(Icons.delete_outline, size: 19),
                          label: Text(clearing ? 'Clearing...' : 'Clear Cart'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFFF4E60),
                            backgroundColor: const Color(0xFFFFEFF2),
                          ),
                        ),
                    ],
                  ),
                  if (notices.isNotEmpty) _notice(notices),
                  const SizedBox(height: 16),
                  if (items.isEmpty)
                    const _EmptyCartView()
                  else ...[
                    for (final item in items) _card(item),
                    _coupon(),
                    const SizedBox(height: 16),
                    _price(items.length, total),
                  ],
                ],
              ),
      ),
      bottomNavigationBar: items.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                color: Colors.white,
                child: SizedBox(
                  height: 53,
                  child: FilledButton(
                    onPressed: purchasing || loading
                        ? null
                        : () => checkout(items),
                    style: FilledButton.styleFrom(backgroundColor: blue),
                    child: purchasing
                        ? const SizedBox(
                            width: 23,
                            height: 23,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Proceed to Checkout',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 12),
                              Icon(Icons.arrow_forward_rounded),
                            ],
                          ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _header() => Row(
    children: [
      Image.asset(
        'assets/branding/nextlead_wordmark.webp',
        width: 145,
        height: 48,
      ),
      const Spacer(),
      Consumer(
        builder: (context, ref, _) => OutlinedButton.icon(
          onPressed: () => ref.invalidate(walletProvider),
          icon: const Icon(
            Icons.account_balance_wallet_outlined,
            color: blue,
            size: 19,
          ),
          label: ref
              .watch(walletProvider)
              .when(
                data: (data) => Text(
                  money((data['balancePaise'] as num? ?? 0) / 100),
                  style: const TextStyle(color: navy),
                ),
                loading: () => const Text('...', style: TextStyle(color: navy)),
                error: (_, _) =>
                    const Text('Wallet', style: TextStyle(color: navy)),
              ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFDCE6F8)),
          ),
        ),
      ),
      IconButton(
        tooltip: 'Notifications',
        onPressed: () => context.push(AppRouter.notificationPath),
        icon: const Icon(Icons.notifications_outlined, color: navy),
      ),
    ],
  );

  Widget _notice(List<String> values) => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7E7),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      'Unavailable leads were removed. ${values.join(' ')}',
      key: const Key('cart-availability-notice'),
      style: const TextStyle(color: Color(0xFF8A5B00)),
    ),
  );

  Widget _card(CartLead item) => Container(
    margin: const EdgeInsets.only(bottom: 11),
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFEDF2FA)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _image(item),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        color: navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    money(item.price),
                    style: const TextStyle(
                      color: navy,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove from cart',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => ref
                        .read(cartControllerProvider.notifier)
                        .deleteItem(item.id),
                    icon: const Icon(Icons.close, color: muted),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _detail(Icons.location_on_outlined, item.location),
              const SizedBox(height: 5),
              Wrap(
                spacing: 11,
                children: [
                  _detail(
                    Icons.home_outlined,
                    item.address.isEmpty ? 'Project lead' : item.address,
                  ),
                  _detail(Icons.people_outline, '${item.sharingCount} slots'),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                'Selected for checkout',
                style: TextStyle(
                  color: item.isSelected ? const Color(0xFF00A45C) : muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _image(CartLead item) => ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: SizedBox(
      width: 91,
      height: 110,
      child: item.imageUrl?.isNotEmpty == true
          ? Image.network(
              item.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallback(),
            )
          : _fallback(),
    ),
  );
  Widget _fallback() => Container(
    color: const Color(0xFFE8F1FF),
    child: const Icon(Icons.home_work_outlined, color: blue, size: 38),
  );
  Widget _detail(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: muted, size: 15),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: muted, fontSize: 12),
        ),
      ),
    ],
  );

  Widget _coupon() => InkWell(
    onTap: () =>
        message('Coupon codes are not available for this checkout yet.'),
    borderRadius: BorderRadius.circular(13),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(0xFFD4E9FF),
            child: Icon(Icons.percent_rounded, color: blue),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Using a coupon code?',
                  style: TextStyle(color: navy, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Enter your code to get a discount on your purchase.',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            'Apply Code ›',
            style: TextStyle(color: blue, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );

  Widget _price(int count, num total) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFEDF2FA)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Price Details',
          style: TextStyle(
            color: navy,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 17),
        _priceRow('Total Leads ($count)', money(total)),
        const SizedBox(height: 10),
        _priceRow('Discount', '− ₹ 0', color: const Color(0xFF00A45C)),
        const Divider(height: 25),
        _priceRow('Total Amount', money(total), bold: true),
      ],
    ),
  );
  Widget _priceRow(
    String label,
    String value, {
    Color? color,
    bool bold = false,
  }) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: muted,
            fontSize: bold ? 17 : 15,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
      Text(
        value,
        style: TextStyle(
          color: color ?? navy,
          fontSize: bold ? 19 : 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
  Widget _error(String error) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: () =>
                ref.read(cartControllerProvider.notifier).loadCart(),
            child: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 110),
    child: Column(
      children: [
        Icon(
          Icons.shopping_cart_outlined,
          color: _CartScreenState.blue,
          size: 76,
        ),
        SizedBox(height: 12),
        Text(
          'Your cart is empty',
          style: TextStyle(
            color: _CartScreenState.navy,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Add leads to review them here.',
          style: TextStyle(color: _CartScreenState.muted),
        ),
      ],
    ),
  );
}
