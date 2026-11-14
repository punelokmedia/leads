import 'package:user_app/features/preview/figma_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/preview/preview_app.dart';
import 'package:user_app/features/preview/lead_details_page.dart';
import 'package:user_app/features/preview/preview_data.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  testWidgets('Home cards open details and return to home', (tester) async {
    await tester.pumpWidget(const PreviewApp());
    await tester.pumpAndSettle();
    final firstLead = tester
        .widget<PreviewHome>(find.byType(PreviewHome))
        .store
        .leads
        .first;
    await tester.scrollUntilVisible(
      find.byWidgetPredicate(
        (widget) => widget is FigmaLeadCard && widget.lead.id == firstLead.id,
      ),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('home-leads-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FigmaLeadCard).first);
    await tester.pumpAndSettle();
    expect(find.byType(LeadDetailsPreview), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Latest Leads'),
      -300,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('home-leads-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Latest Leads'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Business profile edits save, cancel and reset correctly', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = PreviewStore();
    final originalProfile = Map<String, String>.from(store.profile);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: PreviewHome(store: store)),
      ),
    );
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('Business name')),
      'Pune Interiors',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('Business address')));
    await tester.enterText(
      find.byKey(const ValueKey('Business address')),
      '42 Park Road',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('Years in business')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('Years in business')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3–5 years').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save Changes'));
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
    expect(store.profile['Business name'], 'Pune Interiors');
    expect(store.profile['Full name'], originalProfile['Full name']);
    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Pune Interiors'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('Business name')),
      'Unsaved business',
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(store.profile['Business name'], 'Pune Interiors');
    store.reset();
    await tester.pumpAndSettle();
    expect(find.text('Demo Vendor'), findsOneWidget);
    expect(store.profile, originalProfile);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });

  test(
    'Purchase reserves one slot, unlocks contact and records one receipt',
    () {
      final store = PreviewStore();
      final lead = store.leads.first;
      final receipts = store.receipts.length;
      expect(store.purchase(lead), isTrue);
      expect(lead.buyers, 2);
      expect(lead.joined, isTrue);
      expect(lead.closed, isTrue);
      expect(store.receipts.length, receipts + 1);
      expect(store.purchase(lead), isFalse);
      expect(store.receipts.length, receipts + 1);
      expect(store.purchase(store.leads[2]), isFalse);
      store.reset();
      expect(store.leads.first.buyers, 1);
      expect(store.leads.first.joined, isFalse);
      store.dispose();
    },
  );

  testWidgets('Mobile home, filters and categories render without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const PreviewApp());
    await tester.pumpAndSettle();
    expect(find.text('Latest Leads'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('More').first);
    await tester.pumpAndSettle();
    expect(find.text('All Categories'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Filter leads'));
    await tester.pumpAndSettle();
    expect(find.text('Filters'), findsOneWidget);
    expect(find.textContaining('Show Leads ('), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cancellation preserves slots; unlock purchases once', (
    tester,
  ) async {
    final store = PreviewStore();
    addTearDown(store.dispose);
    final lead = store.leads.first;
    final buyers = lead.buyers;
    await tester.pumpWidget(
      MaterialApp(
        home: LeadDetailsPreview(lead: lead, store: store),
      ),
    );
    await tester.tap(find.textContaining('Unlock Lead').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(lead.buyers, buyers);
    expect(lead.joined, isFalse);
    await tester.tap(find.textContaining('Unlock Lead').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();
    expect(lead.buyers, buyers + 1);
    expect(lead.joined, isTrue);
    expect(find.text('Lead Unlocked'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
