import 'package:user_app/features/preview/figma_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/preview/preview_app.dart';
import 'package:user_app/features/preview/lead_details_page.dart';

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
    final firstLead = tester
        .widget<PreviewHome>(find.byType(PreviewHome))
        .store
        .leads
        .first;
    await tester.scrollUntilVisible(
      find.byWidgetPredicate(
        (widget) => widget is FigmaLeadCard && widget.lead.id == firstLead.id,
      ),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('home-leads-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FigmaLeadCard).first);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(LeadDetailsPreview), findsNothing);
    expect(find.text('Exit app?'), findsNothing);

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      tester.widget<FigmaBottomNav>(find.byType(FigmaBottomNav)).selected,
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
