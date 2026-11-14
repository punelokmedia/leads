import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/features/preview/membership_dashboard.dart';
import 'package:user_app/features/preview/preview_app.dart';
import 'package:user_app/features/preview/preview_data.dart';

void main() {
  testWidgets(
    'New membership layout fits small phones and shows active status',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = PreviewStore()..activateMembership();
      addTearDown(store.dispose);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NextLeadMembership(
                store: store,
                onWallet: () {},
                onNotifications: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pro Membership Active'), findsOneWidget);
      await tester.ensureVisible(find.text('Pro Membership Active'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Pro Membership Active'),
            )
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Membership screen renders all required details and features', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = PreviewStore();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: NextLeadMembership(
              store: store,
              onWallet: () {},
              onNotifications: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Hero
    expect(find.text('Membership'), findsOneWidget);
    expect(find.text('Unlock the\nFull Potential'), findsOneWidget);

    // Verify Pro Membership details
    expect(find.text('Pro Membership'), findsOneWidget);
    expect(find.text('Most Popular'), findsOneWidget);
    expect(
      find.text('Full app access for growing businesses.'),
      findsOneWidget,
    );
    expect(find.text('₹ 499'), findsOneWidget);
    expect(find.text('App access only (not for leads)'), findsOneWidget);

    // Verify 4 Features
    expect(find.text('Premium & verified leads'), findsOneWidget);
    expect(find.text('Advanced filters'), findsOneWidget);
    expect(find.text('Priority support'), findsOneWidget);
    expect(find.text('Access to all app features'), findsOneWidget);

    // Verify Action Button
    expect(find.textContaining('Upgrade to Pro'), findsOneWidget);

    // The new design contains the referral card without a comparison section.
    expect(find.text('Compare Plans'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Refer & Earn'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Refer & Earn'), findsOneWidget);
    expect(
      find.text('Invite your friends and earn free app access benefits.'),
      findsOneWidget,
    );

    // Tap upgrade button to open sheet
    await tester.scrollUntilVisible(
      find.textContaining('Upgrade to Pro'),
      -250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.textContaining('Upgrade to Pro'));
    await tester.tap(find.textContaining('Upgrade to Pro'));
    await tester.pumpAndSettle();
    expect(find.text('NextLead Pro Membership'), findsOneWidget);
    expect(
      find.text(
        'Note: This is strictly the fee for app access. Leads are purchased separately.',
      ),
      findsOneWidget,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('Bottom navigation switches to Membership and highlights tab', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const PreviewApp());
    await tester.pumpAndSettle();

    // Verify initial Home tab is active
    expect(find.text('Home'), findsWidgets);
    expect(find.byType(NextLeadMembership), findsNothing);

    // Tap Membership in bottom bar
    await tester.tap(find.text('Membership').last);
    await tester.pumpAndSettle();

    // Verify Membership screen is now shown
    expect(find.byType(NextLeadMembership), findsOneWidget);
    expect(find.text('Pro Membership'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
