import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_router.dart';
import '../../core/network/dio_provider.dart';
import '../../core/errors/error_handler.dart';
import '../auth/shared/auth_providers.dart';
import '../cart/shared/cart_providers.dart';
import 'live_store.dart';
import 'preview_app.dart';
import '../support/presentation/screens/live_support_screen.dart';

import 'package:dio/dio.dart';
import '../cart/domain/cart_model.dart';
import '../payments/presentation/widgets/wallet_card.dart' show walletProvider;

final liveStoreProvider = Provider.autoDispose<LiveStore>((ref) {
  final store = LiveStore(
    ref.watch(dioProvider),
    signedIn: ref.watch(isLoggedInProvider),
  );
  ref.onDispose(store.dispose);
  store.refresh();
  return store;
});

class LiveHome extends ConsumerWidget {
  final int initialPage;
  const LiveHome({super.key, this.initialPage = 0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(liveStoreProvider);

    store.support = (supportContext) => Navigator.of(supportContext).push(
      MaterialPageRoute<void>(
        builder: (chatContext) => LiveSupportScreen(
          dio: store.dio,
          signedIn: store.signedIn,
          signIn: () {
            Navigator.pop(chatContext);
            context.push(AppRouter.login);
          },
        ),
      ),
    );
    store.account = (_) =>
        context.push(store.signedIn ? '/account' : AppRouter.login);
    store.checkout = (detailContext, lead) async {
      if (store.openingCheckout || store.leadActionBusy) return;
      if (!store.signedIn) {
        await context.push(AppRouter.login);
        return;
      }
      try {
        store.openingCheckout = true;
        store.setLeadActionBusy(true);
        try {
          await ref
              .read(cartRepositoryProvider)
              .addToCartRemote(lead.backendId, 1);
          ref.invalidate(cartControllerProvider);
        } finally {
          // Guard the add request only. A pushed cart can stay on the route
          // stack while bottom navigation opens Home or another lead.
          store.openingCheckout = false;
          store.setLeadActionBusy(false);
        }
        if (!context.mounted) return;
        await context.push(AppRouter.cartPath);
        await store.refresh();
        // Close the old detail object; refreshed cards reflect verified purchases.
        if (detailContext.mounted) Navigator.of(detailContext).pop();
      } catch (error) {
        if (detailContext.mounted) {
          ScaffoldMessenger.of(detailContext).showSnackBar(
            SnackBar(content: Text(ErrorHandler.handle(error).message)),
          );
        }
      }
    };
    store.unlock = (detailContext, lead) async {
      if (store.openingCheckout ||
          store.leadActionBusy ||
          lead.joined ||
          lead.closed)
        return;
      if (!store.signedIn) {
        await context.push(AppRouter.login);
        return;
      }
      store.setLeadActionBusy(true);
      String? orderId;
      Object? failure;
      try {
        final repository = ref.read(cartRepositoryProvider);
        // Checkout validates cart ownership; stage only this lead, then buy
        // only its ID without opening or purchasing the rest of the cart.
        await repository.addToCartRemote(lead.backendId, 1);
        ref.invalidate(cartControllerProvider);
        orderId = await repository.purchaseSelected([
          CartLead(
            id: lead.backendId,
            title: lead.title,
            location: lead.city,
            name: '',
            address: '',
            time: '',
            sharingCount: '',
            price: lead.fee,
          ),
        ]);
        lead.joined = true;
        ref.invalidate(walletProvider);
        ref.invalidate(cartControllerProvider);
      } catch (error) {
        failure = error;
      } finally {
        store.setLeadActionBusy(false);
      }
      if (!detailContext.mounted) return;
      if (failure == null && orderId != null) {
        detailContext.go(AppRouter.paymentsuccessPath, extra: orderId);
        return;
      }
      final data = failure is DioException
          ? (failure as DioException).response?.data
          : null;
      final code = data is Map ? data['code'] : null;
      if (code == 'INSUFFICIENT_BALANCE' || code == 'MEMBERSHIP_REQUIRED') {
        final needsMoney = code == 'INSUFFICIENT_BALANCE';
        final proceed = await showDialog<bool>(
          context: detailContext,
          builder: (dialogContext) => AlertDialog(
            icon: Icon(
              needsMoney
                  ? Icons.account_balance_wallet_outlined
                  : Icons.workspace_premium_outlined,
              color: const Color(0xFF0066FF),
              size: 56,
            ),
            title: Text(
              needsMoney ? 'Recharge your wallet' : 'Membership is not active',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
            content: Text(
              needsMoney
                  ? 'Your wallet balance is too low to unlock this lead. Add money to your wallet, then try again.'
                  : 'Your Pro membership is not active. Activate your membership to unlock and purchase leads.',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Not now'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(needsMoney ? 'Add Money' : 'Activate Membership'),
              ),
            ],
          ),
        );
        if (proceed == true && detailContext.mounted) {
          await detailContext.push(
            needsMoney ? AppRouter.paymentsPath : AppRouter.membershipPath,
          );
        }
      } else {
        ScaffoldMessenger.of(detailContext).showSnackBar(
          SnackBar(content: Text(ErrorHandler.handle(failure).message)),
        );
      }
    };
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        if (store.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (store.error != null) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(store.error!, textAlign: TextAlign.center),
                    FilledButton(
                      onPressed: store.refresh,
                      child: const Text('Retry'),
                    ),
                    TextButton(
                      onPressed: () => store.account?.call(context),
                      child: const Text('Account / Sign in'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return PreviewHome(
          key: ValueKey((store, initialPage)),
          store: store,
          initialPage: initialPage,
        );
      },
    );
  }
}
