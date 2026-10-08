import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/core/theme/app_theme.dart';
import 'package:user_app/features/auth/infra/category_repository.dart';
import 'package:user_app/features/auth/infra/city_repository.dart';
import 'package:user_app/features/auth/presentation/screens/tell_us_about_yourself_screen.dart';

double contrast(Color a, Color b) {
  final x = a.computeLuminance();
  final y = b.computeLuminance();
  return x > y ? (x + 0.05) / (y + 0.05) : (y + 0.05) / (x + 0.05);
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  for (final brightness in Brightness.values) {
    testWidgets('Profile form text and hints are readable in $brightness', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            citiesProvider.overrideWith((ref) async => []),
            categoriesProvider.overrideWith((ref) async => []),
          ],
          child: ScreenUtilPlusInit(
            designSize: const Size(390, 844),
            builder: (_, child) => MaterialApp(
              theme: brightness == Brightness.dark
                  ? AppTheme.dark
                  : AppTheme.light,
              home: const TellUsAboutYourselfScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final inputs = find.byType(TextField);
      expect(inputs, findsNWidgets(4));
      for (final input in tester.widgetList<TextField>(inputs)) {
        final background = input.decoration!.fillColor!;
        expect(
          contrast(input.style!.color!, background),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(input.decoration!.hintStyle!.color!, background),
          greaterThanOrEqualTo(4.5),
        );
        expect(input.decoration!.focusedBorder, isA<OutlineInputBorder>());
      }
      await tester.enterText(inputs.first, 'Readable full name');
      await tester.pump();
      expect(find.text('Readable full name'), findsOneWidget);
      final dropdowns = tester.widgetList<DropdownButton<String>>(
        find.byType(DropdownButton<String>),
      );
      expect(dropdowns.length, 2);
      for (final dropdown in dropdowns) {
        expect(
          contrast(dropdown.style!.color!, dropdown.dropdownColor!),
          greaterThanOrEqualTo(4.5),
        );
        final hint = dropdown.hint! as Text;
        expect(
          contrast(hint.style!.color!, dropdown.dropdownColor!),
          greaterThanOrEqualTo(4.5),
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
}
