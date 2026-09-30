import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/preview/preview_app.dart';

void main() {
  testWidgets('Phone theme changes update the running app and lead details', (
    tester,
  ) async {
    final platform = tester.binding.platformDispatcher;
    addTearDown(platform.clearPlatformBrightnessTestValue);
    platform.platformBrightnessTestValue = Brightness.light;
    await tester.pumpWidget(const PreviewApp());
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(PreviewHome))).brightness,
      Brightness.light,
    );

    platform.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    final dark = Theme.of(tester.element(find.byType(PreviewHome)));
    expect(dark.brightness, Brightness.dark);
    expect(
      dark.colorScheme.onSurface.computeLuminance(),
      greaterThan(dark.colorScheme.surface.computeLuminance()),
    );
    await tester.tap(find.text('Explore your first lead'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(LeadDetailsPreview))).brightness,
      Brightness.dark,
    );
    platform.platformBrightnessTestValue = Brightness.light;
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(LeadDetailsPreview))).brightness,
      Brightness.light,
    );
    expect(tester.takeException(), isNull);
  });
}
