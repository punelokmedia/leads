import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/core/theme/app_page_transition.dart';
import 'package:user_app/core/theme/app_theme.dart';
import 'package:user_app/features/preview/preview_app.dart';
import 'package:user_app/features/preview/preview_data.dart';
import 'package:user_app/features/preview/my_leads_page.dart';
import 'package:user_app/features/preview/membership_dashboard.dart';
import 'package:user_app/features/preview/figma_widgets.dart';
import 'package:user_app/features/preview/live_home.dart';
import 'package:user_app/features/preview/live_store.dart';
import 'package:user_app/features/cart/presentation/screens/cart_screen.dart';
import 'package:user_app/features/cart/infra/cart_controller.dart';
import 'package:user_app/features/cart/infra/cart_repository.dart';
import 'package:user_app/features/cart/shared/cart_providers.dart';
import 'package:user_app/features/payments/presentation/widgets/wallet_card.dart';
import 'package:user_app/features/home/presentation/widgets/home_banner_carousel.dart';
import 'package:user_app/core/network/dio_provider.dart';
import 'package:user_app/app/app_router.dart';

void main() {
  testWidgets('Home to My Leads to Cart to Membership opens Membership', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('razorpay_flutter'),
      (_) async => null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('razorpay_flutter'),
        null,
      ),
    );
    final dio = Dio();
    final store = LiveStore(dio, signedIn: false);
    addTearDown(dio.close);
    addTearDown(store.dispose);
    final repository = CartRepository(dio, const FlutterSecureStorage());
    final router = GoRouter(
      initialLocation: AppRouter.homePath,
      routes: [
        GoRoute(path: AppRouter.homePath, builder: (_, _) => const LiveHome()),
        GoRoute(
          path: AppRouter.leadsPath,
          builder: (_, _) => const LiveHome(initialPage: 1),
        ),
        GoRoute(
          path: AppRouter.membershipPath,
          builder: (_, _) => const LiveHome(initialPage: 4),
        ),
        GoRoute(
          path: AppRouter.profilePath,
          builder: (_, _) => const LiveHome(initialPage: 3),
        ),
        GoRoute(
          path: AppRouter.cartPath,
          builder: (_, _) => const CartScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dioProvider.overrideWithValue(dio),
          liveStoreProvider.overrideWithValue(store),
          walletProvider.overrideWith((ref) async => {'balancePaise': 0}),
          homeBannersProvider.overrideWith((ref) async => []),
          cartControllerProvider.overrideWith(
            (ref) => CartController(repository, false),
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Leads').last);
    await tester.pumpAndSettle();
    expect(find.byType(MyLeadsPage), findsOneWidget);
    await tester.tap(find.text('Cart').last);
    await tester.pumpAndSettle();
    expect(find.byType(CartScreen), findsOneWidget);
    await tester.tap(find.text('Membership').last);
    await tester.pumpAndSettle();
    expect(find.byType(NextLeadMembership), findsOneWidget);
    expect(find.byType(MyLeadsPage), findsNothing);
    expect(
      router.routeInformationProvider.value.uri.path,
      AppRouter.membershipPath,
    );
    expect(
      tester.widget<FigmaBottomNav>(find.byType(FigmaBottomNav)).selected,
      3,
    );
  });

  testWidgets(
    'reused home state honours membership destination after My Leads',
    (tester) async {
      final store = PreviewStore();
      addTearDown(store.dispose);
      Future<void> mount(int page) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.light,
              home: PreviewHome(
                key: const ValueKey('shared-home'),
                store: store,
                initialPage: page,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await mount(0);
      await tester.tap(find.text('My Leads').last);
      await tester.pumpAndSettle();
      expect(find.byType(MyLeadsPage), findsOneWidget);
      await mount(4);
      expect(find.byType(NextLeadMembership), findsOneWidget);
      expect(find.byType(MyLeadsPage), findsNothing);
      expect(
        tester.widget<FigmaBottomNav>(find.byType(FigmaBottomNav)).selected,
        3,
      );
      await mount(1);
      expect(find.byType(MyLeadsPage), findsOneWidget);
      await mount(0);
      expect(
        tester.widget<FigmaBottomNav>(find.byType(FigmaBottomNav)).selected,
        0,
      );
    },
  );

  testWidgets(
    'every tab change animates and rapid taps end on the selected tab',
    (tester) async {
      await tester.pumpWidget(const PreviewApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('My Leads').last);
      await tester.pump(const Duration(milliseconds: 70));
      expect(find.byType(FadeTransition), findsWidgets);
      expect(find.byType(SlideTransition), findsWidgets);
      await tester.tap(find.text('Membership').last);
      await tester.pump(const Duration(milliseconds: 70));
      await tester.tap(find.text('Home').last);
      await tester.pump(const Duration(milliseconds: 70));
      await tester.tap(find.text('Membership').last);
      await tester.pumpAndSettle();
      expect(find.byType(NextLeadMembership), findsOneWidget);
      expect(find.byType(MyLeadsPage), findsNothing);
      expect(
        tester.widget<FigmaBottomNav>(find.byType(FigmaBottomNav)).selected,
        3,
      );
    },
  );

  testWidgets('shared page transitions respect reduced motion', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) => AppPageTransitionsBuilder.transition(
              context,
              const AlwaysStoppedAnimation(0.5),
              const AlwaysStoppedAnimation(0),
              const Text('Page'),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Page'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('Page'),
        matching: find.byType(SlideTransition),
      ),
      findsNothing,
    );
  });
}
