import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/preview/lead_filters_sheet.dart';
import 'package:user_app/features/preview/preview_data.dart';

void main() {
  testWidgets('Filters limit initial choices and search the full catalog', (tester) async {
    final store = PreviewStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: LeadFiltersSheet(store: store, initial: const LeadFilters()))));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ActionChip, 'Waterproofing'), findsNothing);
    await tester.enterText(find.byKey(const ValueKey('category-search')), 'water');
    await tester.pump();
    expect(find.widgetWithText(ActionChip, 'Waterproofing'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'Painting'), findsNothing);
    expect(find.widgetWithText(ActionChip, 'All Categories'), findsNothing);
    final city = store.cities.last;
    await tester.ensureVisible(find.byKey(const ValueKey('city-search')));
    await tester.enterText(find.byKey(const ValueKey('city-search')), city);
    await tester.pump();
    expect(find.widgetWithText(ActionChip, city), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'All Cities'), findsNothing);
    await tester.enterText(find.byKey(const ValueKey('city-search')), 'no-such-city');
    await tester.pump();
    expect(find.text('No matching cities or locations'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
