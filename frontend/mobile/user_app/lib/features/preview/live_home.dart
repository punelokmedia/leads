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
      if (store.openingCheckout) return;
      if (!store.signedIn) {
        await context.push(AppRouter.login);
        return;
      }
      try {
        store.openingCheckout = true;
        await ref
            .read(cartRepositoryProvider)
            .addToCartRemote(lead.backendId, 1);
        ref.invalidate(cartControllerProvider);
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
      } finally {
        store.openingCheckout = false;
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
          key: ObjectKey(store),
          store: store,
          initialPage: initialPage,
        );
      },
    );
  }
}
