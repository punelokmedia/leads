import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/features/preview/all_categories_page.dart';
import 'package:user_app/features/preview/figma_widgets.dart';
import 'package:user_app/features/preview/home_dashboard.dart';
import 'package:user_app/features/preview/lead_filters_sheet.dart';
import 'package:user_app/features/preview/my_leads_page.dart';
import 'package:user_app/features/preview/preview_data.dart';
import 'package:user_app/features/splash/presentation/splash_screen.dart';
import 'package:user_app/features/splash/presentation/onboarding_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final scenario in [
    (
      name: 'fresh install shows starting screens then login',
      seen: false,
      token: '',
      path: '/onboarding',
    ),
    (
      name: 'returning signed-out user opens login',
      seen: true,
      token: '',
      path: '/login',
    ),
    (
      name: 'saved sign-in session opens home',
      seen: true,
      token: 'saved-session',
      path: '/home',
    ),
  ]) {
    testWidgets(scenario.name, (tester) async {
      FlutterSecureStorage.setMockInitialValues({
        if (scenario.token.isNotEmpty) 'auth_token': scenario.token,
      });
      SharedPreferences.setMockInitialValues({
        'has_seen_onboarding': scenario.seen,
      });
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
          GoRoute(
            path: '/onboarding',
            builder: (_, _) => const OnboardingScreen(),
          ),
          GoRoute(
            path: '/login',
            builder: (_, _) => const Scaffold(body: Text('Login and sign up')),
          ),
          GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(body: Text('Public home')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      expect(find.byType(SplashScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, scenario.path);
      if (!scenario.seen) {
        expect(find.byType(OnboardingScreen), findsOneWidget);
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();
        expect(find.text('Login and sign up'), findsOneWidget);
        expect(
          (await SharedPreferences.getInstance()).getBool(
            'has_seen_onboarding',
          ),
          isTrue,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  test('filters combine ranges, city, category, saved and posted date', () {
    final lead = PreviewLead(
      id: 'new',
      title: 'Painting enquiry',
      category: 2,
      city: 'Pune',
      state: 'Maharashtra',
      budget: 50000,
      fee: 100,
      description: '',
      area: '1,200 sq ft',
      timeline: 'Within 1 Month',
      saved: true,
      postedAt: DateTime.now(),
    );
    expect(
      const LeadFilters(
        city: 'Pune',
        category: 2,
        minBudget: 10000,
        maxBudget: 50000,
        minArea: 1000,
        maxArea: 1500,
        timeline: 'Within 1 Month',
        savedOnly: true,
        postedDays: 1,
      ).matches(lead),
      isTrue,
    );
    expect(const LeadFilters(maxBudget: 49999).matches(lead), isFalse);
    expect(const LeadFilters(city: 'Mumbai').matches(lead), isFalse);
    expect(const LeadFilters(minArea: 1500).matches(lead), isFalse);
    expect(const LeadFilters(category: 0).matches(lead), isFalse);
  });

  test('unknown or old posted dates are not treated as recent', () {
    PreviewLead lead(DateTime? date) => PreviewLead(
      id: 'old',
      title: '',
      category: 0,
      city: '',
      state: '',
      budget: 0,
      fee: 0,
      description: '',
      postedAt: date,
    );
    expect(const LeadFilters(postedDays: 7).matches(lead(null)), isFalse);
    expect(
      const LeadFilters(
        postedDays: 7,
      ).matches(lead(DateTime.now().subtract(const Duration(days: 8)))),
      isFalse,
    );
    expect(const LeadFilters().matches(lead(null)), isTrue);
  });

  for (final width in [320.0, 393.0, 480.0]) {
    testWidgets('mobile home and categories fit at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = PreviewStore();
      addTearDown(store.dispose);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              backgroundColor: figmaBackground,
              bottomNavigationBar: FigmaBottomNav(
                selected: 0,
                onSelect: (_) {},
              ),
              body: NextLeadDashboard(
                store: store,
                leads: store.leads,
                city: 'All Cities',
                category: null,
                onSearch: (_) {},
                onCategory: (_) {},
                onFilters: () {},
                onCategories: () {},
                onNotifications: () {},
                onExplore: () {},
                onLead: (_) {},
                onWallet: () {},
                onSaved: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Latest Leads'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        MaterialApp(
          home: CategoryPreview(store: store, onSelect: (_) {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('All Categories'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('My Leads contains only unlocked leads', (tester) async {
    final store = PreviewStore.empty();
    addTearDown(store.dispose);
    PreviewLead lead(String id, bool joined) => PreviewLead(
      id: id,
      title: id,
      category: 0,
      city: 'Pune',
      state: '',
      budget: 100,
      fee: 10,
      description: '',
      joined: joined,
    );
    store.leads = [
      lead('Unlocked project', true),
      lead('Locked project', false),
    ];
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: MyLeadsPage(
              store: store,
              onWallet: () {},
              onNotifications: () {},
              onLead: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Unlocked project'), findsOneWidget);
    expect(find.text('Locked project'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
