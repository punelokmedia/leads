import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/preview/preview_app.dart';
import 'package:user_app/features/preview/preview_data.dart';

void main() {
  testWidgets('Feature prompt opens details and swipes away over home', (
    tester,
  ) async {
    await tester.pumpWidget(const PreviewApp());
    await tester.pumpAndSettle();
    expect(find.text('High Quality Leads'), findsOneWidget);
    await tester.tap(find.text('Explore your first lead'));
    await tester.pumpAndSettle();
    expect(find.byType(LeadDetailsPreview), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('feature-prompt')),
      const Offset(-700, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Explore your first lead'), findsNothing);
    expect(find.text('High Quality Leads'), findsOneWidget);
    await tester.tap(find.byTooltip('My profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    expect(find.text('Explore your first lead'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile edits save, cancel and reset correctly', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = PreviewStore();
    await tester.pumpWidget(MaterialApp(home: PreviewHome(store: store)));
    await tester.tap(find.byTooltip('My profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit personal details'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Priya Sharma');
    await tester.scrollUntilVisible(
      find.text('Save details'),
      250,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Save details'));
    await tester.pumpAndSettle();
    expect(find.text('Priya Sharma'), findsOneWidget);
    await tester.tap(find.text('Edit personal details'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Unsaved name');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Priya Sharma'), findsOneWidget);
    store.reset();
    await tester.pumpAndSettle();
    expect(find.text('Demo Vendor'), findsOneWidget);
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
    expect(
      find.text('TEST MODE • Sample data • No real charges'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('All Categories'));
    await tester.pumpAndSettle();
    expect(find.text('Pan India Coverage'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('1 available test leads'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leads').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Filter leads'));
    await tester.pumpAndSettle();
    expect(find.text('Apply filters'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Failure and cancellation preserve slots; success unlocks contact',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = PreviewStore();
      final lead = store.leads.first;
      await tester.pumpWidget(
        MaterialApp(
          home: LeadDetailsPreview(lead: lead, store: store),
        ),
      );
      await tester.tap(find.text('Accept Lead & View Contact'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simulate failure'));
      await tester.pumpAndSettle();
      expect(lead.buyers, 1);
      expect(lead.joined, isFalse);
      await tester.tap(find.text('Accept Lead & View Contact'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(lead.buyers, 1);
      await tester.tap(find.text('Accept Lead & View Contact'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simulate success'));
      await tester.pumpAndSettle();
      expect(lead.buyers, 2);
      expect(find.text('Contact Unlocked'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Save lead'));
      await tester.pumpAndSettle();
      expect(lead.saved, isTrue);
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    },
  );
}
