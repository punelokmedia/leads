import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/app/user_app.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(const UserApp());
    expect(find.text('Leads Sell'), findsOneWidget);
  });
}
