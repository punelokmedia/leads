import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/features/preview/preview_data.dart';
import 'package:user_app/features/preview/location_service_area_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('ProfileMontserrat');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/Montserrat-$weight.ttf'));
    }
    await loader.load();
  });
  Future<PreviewStore> mount(WidgetTester tester, {double scale = 1}) async {
    tester.view.physicalSize = scale == 1
        ? const Size(393, 1206)
        : const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = PreviewStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => RepaintBoundary(
                      key: const ValueKey('location-capture'),
                      child: LocationServiceAreaPage(store: store),
                    ),
                  ),
                ),
                child: const Text('Open location'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open location'));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/figma/profile-logo.png'),
        tester.element(find.byType(LocationServiceAreaPage)),
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('location edits save radius and localities with a map preview', (
    tester,
  ) async {
    final store = await mount(tester);
    expect(tester.takeException(), isNull);
    if (const bool.fromEnvironment('UPDATE_LOCATION_PREVIEW')) {
      await tester.runAsync(() async {
        final image = await tester
            .renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('location-capture')),
            )
            .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '../../../.tmp/location-implemented.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    expect(find.text('Map preview'), findsOneWidget);
    await tester.tap(find.text('Within 50 km'));
    await tester.pumpAndSettle();
    expect(find.text('50 km service radius'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove Wakad'));
    await tester.enterText(
      find.byKey(const ValueKey('Additional areas')),
      'Kothrud',
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Add area'));
    await tester.pumpAndSettle();
    expect(store.serviceRadiusKm, 25);
    expect(store.additionalAreas, contains('Wakad'));
    await tester.ensureVisible(find.text('Save Location & Area'));
    await tester.tap(find.text('Save Location & Area'));
    await tester.pumpAndSettle();
    expect(store.serviceRadiusKm, 50);
    expect(store.additionalAreas, ['Baner', 'Hinjawadi', 'Kothrud']);
    expect(find.text('Open location'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow layout supports large text and cancel discards edits', (
    tester,
  ) async {
    final store = await mount(tester, scale: 1.4);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Within 10 km'));
    await tester.tap(find.text('Within 10 km'));
    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(store.serviceRadiusKm, 25);
    expect(tester.takeException(), isNull);
  });
}
