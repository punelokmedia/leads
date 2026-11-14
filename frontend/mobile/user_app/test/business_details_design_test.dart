import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/features/preview/business_details_page.dart';
import 'package:user_app/features/preview/preview_data.dart';

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
    WidgetTester tester,
    Size size, {
    double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = PreviewStore();
    store.profile = {
      ...store.profile,
      'Business name': '',
      'City': 'Pune, Maharashtra',
    };
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
                      key: const ValueKey('business-capture'),
                      child: EditProfilePreview(store: store),
                    ),
                  ),
                ),
                child: const Text('Open business'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open business'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/figma/profile-logo.png'),
        tester.element(find.byType(EditProfilePreview)),
      );
    });
    await tester.pumpAndSettle();
    return store;
  }

  testWidgets('business SVG layout renders and saves every business field', (
    tester,
  ) async {
    final store = await mount(tester, const Size(393, 1163));
    expect(tester.takeException(), isNull);
    if (const bool.fromEnvironment('UPDATE_BUSINESS_PREVIEW')) {
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('business-capture')),
        );
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '../../../.tmp/business-implemented.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    Future<void> enter(String key, String text) async {
      await tester.ensureVisible(find.byKey(ValueKey(key)));
      await tester.enterText(find.byKey(ValueKey(key)), text);
    }

    await enter('Business name', 'Pune Interiors');
    await enter('GST number', '27ABCDE1234F1Z5');
    await enter('Business address', '42 Park Road');
    await enter('Service area', 'Pune and nearby areas');
    await enter('Website', 'https://pune.example.com');
    tester.testTextInput.hide();
    await tester.ensureVisible(find.byKey(const ValueKey('Years in business')));
    await tester.tap(find.byKey(const ValueKey('Years in business')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3–5 years').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save Changes'));
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
    expect(find.text('Open business'), findsOneWidget);
    expect(store.profile['Business name'], 'Pune Interiors');
    expect(store.profile['Business type'], 'Sole proprietorship');
    expect(store.profile['GST number'], '27ABCDE1234F1Z5');
    expect(store.profile['Business address'], '42 Park Road');
    expect(store.profile['City'], 'Pune, Maharashtra');
    expect(store.profile['Service area'], 'Pune and nearby areas');
    expect(store.profile['Years in business'], '3–5 years');
    expect(store.profile['Website'], 'https://pune.example.com');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'business form supports narrow screens and cancel discards changes',
    (tester) async {
      final store = await mount(tester, const Size(320, 700), scale: 1.4);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(const ValueKey('Business name')));
      await tester.enterText(
        find.byKey(const ValueKey('Business name')),
        'Unsaved',
      );
      tester.testTextInput.hide();
      await tester.ensureVisible(find.text('Cancel'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(store.profile['Business name'], isEmpty);
      expect(find.text('Open business'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
