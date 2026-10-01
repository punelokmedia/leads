import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/preview/preview_app.dart';

void main() {
  testWidgets('Back returns from details and tabs before confirming exit', (
    tester,
  ) async {
    var exits = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'SystemNavigator.pop') exits++;
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(const PreviewApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore your first lead'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LeadDetailsPreview), findsNothing);
    expect(find.text('Exit app?'), findsNothing);

    await tester.tap(find.byTooltip('My profile'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
    expect(find.text('Exit app?'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Exit app?'), findsOneWidget);
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    expect(exits, 0);
    expect(find.text('Exit app?'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(exits, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
