import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/features/preview/preview_data.dart';
import 'package:user_app/features/preview/service_categories_page.dart';

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
        ? const Size(393, 845)
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
                      key: const ValueKey('service-capture'),
                      child: ServiceCategoriesPage(store: store),
                    ),
                  ),
                ),
                child: const Text('Open categories'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open categories'));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/figma/profile-logo.png'),
        tester.element(find.byType(ServiceCategoriesPage)),
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets(
    'service search, selection, removal and save preserve draft until success',
    (tester) async {
      final store = await mount(tester);
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('UPDATE_SERVICE_PREVIEW')) {
        await tester.runAsync(() async {
          final image = await tester
              .renderObject<RenderRepaintBoundary>(
                find.byKey(const ValueKey('service-capture')),
              )
              .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            '../../../.tmp/service-implemented.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.tap(find.text('Painting'));
      expect(store.serviceCategories, {'Interior Design', 'Painting'});
      await tester.enterText(find.byType(TextField), 'plumb');
      await tester.pumpAndSettle();
      expect(find.text('Civil Work'), findsNothing);
      await tester.tap(find.text('Plumbing'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save Categories'));
      await tester.tap(find.text('Save Categories'));
      await tester.pumpAndSettle();
      expect(store.serviceCategories, {'Interior Design', 'Plumbing'});
      expect(find.text('Open categories'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'large text fits narrow screen and cancel preserves saved categories',
    (tester) async {
      final store = await mount(tester, scale: 1.4);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Painting'));
      await tester.tap(find.text('Painting'));
      await tester.ensureVisible(find.text('Cancel'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(store.serviceCategories, {'Interior Design', 'Painting'});
      expect(tester.takeException(), isNull);
    },
  );
}
