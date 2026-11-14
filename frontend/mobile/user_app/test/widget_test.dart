import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/app/user_app.dart';
import 'package:user_app/app/app_router.dart';

void main() {
  testWidgets('App starts with the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: UserApp()));
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
      'NextLead',
    );
    expect(
      AppRouter.router.routeInformationProvider.value.uri.path,
      AppRouter.splashPath,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });
}
