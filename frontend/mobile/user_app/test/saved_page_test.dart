import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/features/preview/figma_widgets.dart';
import 'package:user_app/features/preview/preview_data.dart';
import 'package:user_app/features/preview/profile_design.dart';
import 'package:user_app/features/preview/saved_leads_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('ProfileMontserrat');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/Montserrat-$weight.ttf'));
    }
    await loader.load();
  });
  setUp(() {
    final fatal = WidgetController.hitTestWarningShouldBeFatal;
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = fatal);
  });
  Future<(PreviewStore, Set<String>)> mount(
    WidgetTester tester, {
    double scale = 1,
    ValueChanged<PreviewLead>? onLead,
    ValueChanged<String>? onCategory,
  }) async {
    tester.view.physicalSize = scale == 1
        ? const Size(393, 1029)
        : const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = PreviewStore();
    addTearDown(store.dispose);
    store.leads = [
      PreviewLead(
        id: 'interior',
        title: '2 BHK Interior Work',
        category: 0,
        city: 'Baner, Pune',
        state: 'Maharashtra',
        budget: 250000,
        budgetLabel: '₹1.5L–₹2.5L',
        fee: 500,
        description: '',
        saved: true,
      ),
      PreviewLead(
        id: 'painting',
        title: 'Exterior Painting',
        category: 2,
        city: 'Wakad, Pune',
        state: 'Maharashtra',
        budget: 60000,
        budgetLabel: '₹35,000 – ₹60,000',
        fee: 200,
        description: '',
        saved: true,
      ),
    ];
    final categories = {'Interior Design', 'Painting'};
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
            key: const ValueKey('saved-capture'),
            child: Scaffold(
              backgroundColor: profileBackground,
              body: SavedLeadsScreen(
                store: store,
                savedCategories: categories,
                onBack: () {},
                onWallet: () {},
                onNotifications: () {},
                onLead: onLead ?? (_) {},
                onCategory: onCategory ?? (_) {},
                onCategoriesChanged: () {},
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
      final context = tester.element(find.byType(SavedLeadsScreen));
      await precacheImage(
        const AssetImage('assets/figma/profile-logo.png'),
        context,
      );
      for (final name in ['interior', 'painting']) {
        await precacheImage(
          ResizeImage(AssetImage('assets/figma/saved-$name.png'), width: 96),
          context,
        );
      }
    });
    await tester.pumpAndSettle();
    return (store, categories);
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder.hitTestable(),
      200,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(finder.hitTestable());
    await tester.pumpAndSettle();
  }

  testWidgets('saved design supports search, view lead and unsave', (
    tester,
  ) async {
    PreviewLead? opened;
    final (store, _) = await mount(tester, onLead: (lead) => opened = lead);
    expect(tester.takeException(), isNull);
    if (const bool.fromEnvironment('UPDATE_SAVED_PREVIEW')) {
      await tester.runAsync(() async {
        final image = await tester
            .renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('saved-capture')),
            )
            .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '../../../.tmp/saved-implemented.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    expect(find.text('Leads (2)'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'painting');
    await tester.pumpAndSettle();
    expect(find.text('2 BHK Interior Work'), findsNothing);
    await tapVisible(tester, find.text('View Lead').first);
    expect(opened?.id, 'painting');
    await tapVisible(tester, find.byTooltip('Remove saved lead').first);
    expect(store.leads.last.saved, isFalse);
    expect(find.text('No saved leads found.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'category tab preserves navigation, removal and category management',
    (tester) async {
      String? opened;
      final (_, categories) = await mount(
        tester,
        onCategory: (name) => opened = name,
      );
      await tester.tap(find.text('Categories (2)'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.widgetWithText(ListTile, 'Painting'));
      expect(opened, 'Painting');
      await tapVisible(tester, find.byTooltip('Remove category').first);
      expect(categories, {'Painting'});
      await tapVisible(tester, find.text('Manage ›'));
      expect(find.text('Save categories'), findsOneWidget);
      await tester.tap(
        find.widgetWithText(CheckboxListTile, 'Interior Design'),
      );
      await tester.tap(find.text('Save categories'));
      await tester.pumpAndSettle();
      expect(categories, {'Painting', 'Interior Design'});
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('narrow saved layout handles enlarged text', (tester) async {
    await mount(tester, scale: 1.4);
    expect(tester.takeException(), isNull);
    await tapVisible(tester, find.text('View Lead').first);
    expect(tester.takeException(), isNull);
    await tapVisible(tester, find.text('Manage ›'));
    expect(find.text('Save categories'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
