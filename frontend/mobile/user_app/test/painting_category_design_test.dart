import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/features/preview/category_leads_page.dart';
import 'package:user_app/features/preview/figma_widgets.dart';
import 'package:user_app/features/preview/preview_data.dart';
import 'package:user_app/features/preview/profile_design.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('ProfileMontserrat');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/Montserrat-$weight.ttf'));
    }
    await loader.load();
  });
  Future<PreviewStore> mount(
    WidgetTester tester, {
    double scale = 1,
    ValueChanged<PreviewLead>? onLead,
  }) async {
    tester.view.physicalSize = scale == 1
        ? const Size(393, 1388)
        : const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = PreviewStore();
    addTearDown(store.dispose);
    const titles = [
      '2 BHK Interior Painting',
      'Exterior House Painting',
      'Full Building Painting (4 Floors)',
      '1 BHK Wall Painting',
      'Terrace & Exterior Painting',
    ];
    const budgets = [
      '₹15 – 25 Lakh',
      '₹30 – 50 Lakh',
      '₹50 Lakh+',
      '₹8 – 15 Lakh',
      '₹20 – 35 Lakh',
    ];
    store.leads = List.generate(
      5,
      (i) => PreviewLead(
        id: 'p$i',
        title: titles[i],
        category: 2,
        city: 'Pune',
        state: 'Maharashtra',
        budget: (i + 1) * 100000,
        budgetLabel: budgets[i],
        fee: 100,
        description: '',
        area: '1200 sq ft',
        timeline: 'Within 1 Month',
        propertyType: i == 2 ? 'Apartment' : 'Residential',
        postedAt: DateTime.now().subtract(Duration(hours: i + 2)),
      ),
    );
    var query = '', tab = 'All';
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: RepaintBoundary(
            key: const ValueKey('painting-capture'),
            child: Scaffold(
              backgroundColor: profileBackground,
              body: StatefulBuilder(
                builder: (context, update) => CategoryLeadsPage(
                  store: store,
                  leads: store.leads
                      .where(
                        (lead) => lead.title.toLowerCase().contains(
                          query.toLowerCase(),
                        ),
                      )
                      .toList(),
                  category: 2,
                  city: 'Pune',
                  query: query,
                  tab: tab,
                  onBack: () {},
                  onWallet: () {},
                  onSaved: () {},
                  onNotifications: () {},
                  onFilters: () {},
                  onSearch: (value) => update(() => query = value),
                  onTab: (value) => update(() => tab = value),
                  onLead: onLead ?? (_) {},
                ),
              ),
              bottomNavigationBar: FigmaBottomNav(
                selected: -1,
                onSelect: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final context = tester.element(find.byType(CategoryLeadsPage));
      await precacheImage(
        const AssetImage('assets/figma/profile-logo.png'),
        context,
      );
      for (var i = 0; i < 5; i++) {
        await precacheImage(
          ResizeImage(
            AssetImage('assets/figma/painting-lead-$i.png'),
            width: 96,
          ),
          context,
        );
      }
    });
    await tester.pumpAndSettle();
    return store;
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    final scrollable = find
        .descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      finder.hitTestable(),
      220,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    await tester.tap(finder.hitTestable());
    await tester.pumpAndSettle();
  }

  testWidgets(
    'category redesign preserves budget filtering, saving and viewing leads',
    (tester) async {
      PreviewLead? opened;
      final store = await mount(tester, onLead: (lead) => opened = lead);
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('UPDATE_PAINTING_PREVIEW')) {
        await tester.runAsync(() async {
          final image = await tester
              .renderObject<RenderRepaintBoundary>(
                find.byKey(const ValueKey('painting-capture')),
              )
              .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            '../../../.tmp/painting-implemented.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      expect(find.text('5 Leads Available'), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Budget'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, '₹30 – 50 Lakh'));
      await tester.pumpAndSettle();
      expect(find.text('1 Leads Found'), findsOneWidget);
      await tapVisible(tester, find.byTooltip('Save lead'));
      expect(store.leads[1].saved, isTrue);
      await tapVisible(tester, find.text('View Lead'));
      expect(opened?.id, 'p1');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('search and enlarged text work on narrow screens', (
    tester,
  ) async {
    await mount(tester, scale: 1.4);
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextFormField), 'Terrace');
    await tester.pumpAndSettle();
    expect(find.text('1 Leads Found'), findsOneWidget);
    await tapVisible(tester, find.text('View Lead'));
    expect(tester.takeException(), isNull);
  });
}
