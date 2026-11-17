import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/core/location/startup_location.dart';
import 'package:user_app/features/cart/infra/cart_repository.dart';
import 'package:user_app/features/cart/shared/cart_providers.dart';
import 'package:user_app/features/preview/live_home.dart';
import 'package:user_app/features/preview/live_store.dart';
import 'package:user_app/features/preview/preview_data.dart';
import 'package:user_app/features/cart/domain/cart_model.dart';
import 'package:user_app/features/preview/lead_details_page.dart';

class CheckoutStore extends LiveStore {
  CheckoutStore() : super(Dio(), signedIn: true) {
    loading = true;
  }
  @override
  Future<void> refresh() async {}
}

class CheckoutRepository extends CartRepository {
  CheckoutRepository() : super(Dio(), const FlutterSecureStorage());
  final added = <String>[];
  Completer<void>? pending;
  bool fail = false;
  String? purchaseError;
  final purchased = <String>[];
  Completer<void>? purchasePending;
  @override
  Future<String> purchaseSelected(List<CartLead> selection) async {
    purchased.addAll(selection.map((item) => item.id));
    await purchasePending?.future;
    if (purchaseError != null) {
      throw DioException(
        requestOptions: RequestOptions(),
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 409,
          data: {'code': purchaseError, 'message': 'Purchase failed'},
        ),
      );
    }
    return 'paid-order';
  }

  @override
  Future<String> addToCartRemote(String id, int quantity) async {
    added.add(id);
    await pending?.future;
    if (fail) throw StateError('Add failed');
    return 'Added';
  }
}

PreviewLead lead(String id) => PreviewLead(
  id: id,
  backendId: id,
  title: 'Project',
  category: 0,
  city: 'Pune',
  state: 'Maharashtra',
  budget: 1000,
  fee: 100,
  description: 'Project',
);

void main() {
  for (final errorCode in <String?>[
    null,
    'INSUFFICIENT_BALANCE',
    'MEMBERSHIP_REQUIRED',
  ]) {
    testWidgets(
      'direct unlock handles ${errorCode ?? 'successful payment'} without opening cart',
      (tester) async {
        final store = CheckoutStore();
        final repository = CheckoutRepository()..purchaseError = errorCode;
        repository.purchasePending = Completer<void>();
        final selected = lead('direct');
        late BuildContext homeContext;
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) {
                homeContext = context;
                return const LiveHome();
              },
            ),
            GoRoute(
              path: AppRouter.paymentsPath,
              builder: (_, _) =>
                  const Scaffold(body: Text('Recharge destination')),
            ),
            GoRoute(
              path: AppRouter.membershipPath,
              builder: (_, _) =>
                  const Scaffold(body: Text('Membership destination')),
            ),
            GoRoute(
              path: AppRouter.paymentsuccessPath,
              builder: (_, state) =>
                  Scaffold(body: Text('Payment success: ${state.extra}')),
            ),
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              liveStoreProvider.overrideWithValue(store),
              cartRepositoryProvider.overrideWithValue(repository),
              startupLocationProvider.overrideWith(
                (ref) async => const StartupLocation(),
              ),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pump();
        unawaited(
          Navigator.of(homeContext).push(
            MaterialPageRoute<void>(
              builder: (_) => LeadDetailsPreview(lead: selected, store: store),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Add to Cart'), findsOneWidget);
        expect(
          tester.getTopLeft(find.text('Add to Cart')).dy,
          greaterThan(tester.getTopLeft(find.text('Unlock Lead')).dy),
        );
        await tester.tap(find.text('Unlock Lead'));
        await tester.pump();
        expect(store.leadActionBusy, isTrue);
        expect(find.text('Processing…'), findsOneWidget);
        expect(repository.added, ['direct']);
        expect(repository.purchased, ['direct']);
        repository.purchasePending!.complete();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(store.leadActionBusy, isFalse);
        if (errorCode == null) {
          expect(selected.joined, isTrue);
          await tester.pumpAndSettle();
          expect(find.text('Payment success: paid-order'), findsOneWidget);
          expect(find.byType(AlertDialog), findsNothing);
        } else {
          expect(selected.joined, isFalse);
          await tester.tap(
            find.text(
              errorCode == 'INSUFFICIENT_BALANCE'
                  ? 'Add Money'
                  : 'Activate Membership',
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          expect(
            find.text(
              errorCode == 'INSUFFICIENT_BALANCE'
                  ? 'Recharge destination'
                  : 'Membership destination',
            ),
            findsOneWidget,
          );
        }
        await tester.pumpWidget(const SizedBox());
        router.dispose();
        store.dispose();
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'unlock works again while earlier cart navigation is still pending',
    (tester) async {
      final store = CheckoutStore();
      final repository = CheckoutRepository();
      late BuildContext homeContext;
      var cartVisits = 0;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) {
              homeContext = context;
              return const LiveHome();
            },
          ),
          GoRoute(
            path: AppRouter.cartPath,
            builder: (context, state) {
              cartVisits++;
              return const Scaffold(body: Text('Cart destination'));
            },
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            liveStoreProvider.overrideWithValue(store),
            cartRepositoryProvider.overrideWithValue(repository),
            startupLocationProvider.overrideWith(
              (ref) async => const StartupLocation(),
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();

      repository.pending = Completer<void>();
      final first = store.checkout!(homeContext, lead('first'));
      await tester.pump();
      expect(store.openingCheckout, isTrue);
      await store.checkout!(homeContext, lead('duplicate'));
      expect(repository.added, ['first']);

      repository.pending!.complete();
      repository.pending = null;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Cart destination'), findsOneWidget);
      expect(store.openingCheckout, isFalse);
      var firstReturned = false;
      unawaited(
        first.then((_) {
          firstReturned = true;
        }),
      );
      expect(firstReturned, isFalse);

      final second = store.checkout!(homeContext, lead('second'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(repository.added, ['first', 'second']);
      expect(cartVisits, greaterThanOrEqualTo(2));
      expect(store.openingCheckout, isFalse);

      await tester.pumpWidget(const SizedBox());
      router.dispose();
      unawaited(second);
      store.dispose();
      expect(tester.takeException(), isNull);
    },
  );
}
