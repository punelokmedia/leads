import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/support/presentation/screens/support_chat_view.dart';

void main() {
  for (final width in [390.0, 320.0]) {
    testWidgets('chat design and topic actions fit width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final input = TextEditingController();
      addTearDown(input.dispose);
      String? selected;
      var sends = 0;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(width == 320 ? 1.4 : 1)),
            child: child!,
          ),
          home: SupportChatView(
            messages: const [],
            input: input,
            loading: false,
            sending: false,
            signedIn: true,
            hasOlder: false,
            showTopics: true,
            error: null,
            status: 'NextLead Support',
            send: () => sends++,
            refresh: () {},
            older: () {},
            signIn: () {},
            tickets: () {},
            wallet: const SizedBox.shrink(),
            topic: (code, _) => selected = code,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Today'), findsOneWidget);
      final other = find.text('Other issue').hitTestable();
      await tester.scrollUntilVisible(
        other,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(other);
      expect(selected, 'OTHER');
      await tester.tap(find.byTooltip('Support options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Talk to a human'));
      await tester.pumpAndSettle();
      expect(selected, 'HUMAN');
      await tester.enterText(find.byType(TextField), 'Please help');
      await tester.tap(find.byTooltip('Send message'));
      expect(sends, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
