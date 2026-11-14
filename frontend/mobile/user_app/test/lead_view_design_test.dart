import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/preview/lead_details_page.dart';
import 'package:user_app/features/preview/preview_data.dart';

class _Store extends PreviewStore {
  final bool live;
  _Store({this.live = false}) : super.empty();
  @override
  bool get isLive => live;
  @override
  List<PreviewCategory> get categories => const [
    PreviewCategory('Civil Construction', '', '', Icons.home, Colors.blue),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('ProfileMontserrat');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/Montserrat-$weight.ttf'));
    }
    await loader.load();
  });

  Future<(_Store, PreviewLead)> mount(
    WidgetTester tester, {
    double scale = 1,
    bool live = false,
  }) async {
    tester.view.physicalSize = scale == 1
        ? const Size(393, 1204)
        : const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = _Store(live: live);
    addTearDown(store.dispose);
    final lead = PreviewLead(
      id: 'NL-1',
      title: 'New 2 BHK Residential House Construction',
      category: 0,
      city: 'Baner, Pune',
      state: 'Maharashtra',
      budget: 3500000,
      budgetLabel: '₹25 – 35 Lakh',
      fee: 99,
      propertyType: '2 BHK Home',
      area: '1200 sq ft',
      timeline: '6 – 8 Months',
      postedAt: DateTime.now().subtract(const Duration(hours: 2)),
      contact: 'Private Client\n9876543210',
      description:
          'Ground + 1 floor construction\nModern elevation design\nQuality material and civil work\nWilling to discuss project details with shortlisted vendors',
    );
    store.leads = [lead];
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: RepaintBoundary(
          key: const ValueKey('lead-view-capture'),
          child: LeadDetailsPreview(lead: lead, store: store),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final context = tester.element(find.byType(LeadDetailsPreview));
      await precacheImage(
        const AssetImage('assets/figma/profile-logo.png'),
        context,
      );
      for (var i = 0; i < 5; i++) {
        await precacheImage(
          ResizeImage(
            AssetImage('assets/figma/lead-view-$i.png'),
            height: i == 0 ? 112 : 78,
          ),
          context,
        );
      }
    });
    await tester.pumpAndSettle();
    return (store, lead);
  }

  testWidgets(
    'lead redesign keeps save, checkout cancellation and purchase behavior',
    (tester) async {
      final (store, lead) = await mount(tester);
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('UPDATE_LEAD_VIEW_PREVIEW')) {
        await tester.runAsync(() async {
          final image = await tester
              .renderObject<RenderRepaintBoundary>(
                find.byKey(const ValueKey('lead-view-capture')),
              )
              .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            '../../../.tmp/lead-view-implemented.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.tap(find.byTooltip('Save lead'));
      await tester.pumpAndSettle();
      expect(lead.saved, isTrue);
      await tester.tap(find.text('Unlock Lead'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(lead.joined, isFalse);
      await tester.tap(find.text('Unlock Lead'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();
      expect(lead.joined, isTrue);
      expect(store.receipts.length, 1);
      expect(find.text('Lead Unlocked'), findsOneWidget);
      expect(find.textContaining('Private Client'), findsNothing);
      expect(find.textContaining('9876543210'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'live lead keeps existing checkout callback and protected contact policy',
    (tester) async {
      final (store, lead) = await mount(tester, live: true);
      var calls = 0;
      store.checkout = (_, item) async {
        expect(item, same(lead));
        calls++;
      };
      await tester.tap(find.text('Unlock Lead'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(store.receipts, isEmpty);
      expect(lead.joined, isFalse);
      expect(find.textContaining('Private Client'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('large text fits narrow lead view and gallery opens and closes', (
    tester,
  ) async {
    await mount(tester, scale: 1.4);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byTooltip('View project images'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('View project images').hitTestable());
    await tester.pumpAndSettle();
    expect(find.byType(PageView), findsOneWidget);
    await tester.tap(find.byTooltip('Close gallery'));
    await tester.pumpAndSettle();
    expect(find.byType(PageView), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
