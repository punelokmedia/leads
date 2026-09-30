import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/support/presentation/screens/live_support_screen.dart';

void main() {
  testWidgets('Live support keeps failed text and reuses request ID on retry', (
    tester,
  ) async {
    final dio = Dio();
    final sent = <Map<String, dynamic>>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          if (request.method == 'GET') {
            handler.resolve(
              Response(
                requestOptions: request,
                data: {'success': true, 'data': <dynamic>[]},
              ),
            );
          } else {
            sent.add(Map<String, dynamic>.from(request.data));
            if (sent.length == 1) {
              handler.reject(DioException(requestOptions: request));
            } else {
              handler.resolve(
                Response(
                  requestOptions: request,
                  data: {
                    'success': true,
                    'data': {
                      '_id': 'message1',
                      'sender': 'user',
                      'text': request.data['text'],
                    },
                  },
                ),
              );
            }
          }
        },
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: LiveSupportScreen(dio: dio, signedIn: true, signIn: () {}),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Where is my receipt?');
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Message not confirmed'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Where is my receipt?',
    );
    await tester.tap(find.byTooltip('Send message'));
    await tester.pumpAndSettle();
    expect(sent[0]['clientId'], sent[1]['clientId']);
    expect(find.text('You: Where is my receipt?'), findsOneWidget);
    expect(find.textContaining('simulation'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    dio.close();
  });

  testWidgets('Guests must sign in before sending support messages', (
    tester,
  ) async {
    var signedIn = false;
    final dio = Dio();
    await tester.pumpWidget(
      MaterialApp(
        home: LiveSupportScreen(
          dio: dio,
          signedIn: false,
          signIn: () => signedIn = true,
        ),
      ),
    );
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('Sign in to contact support'));
    expect(signedIn, isTrue);
    await tester.pumpWidget(const SizedBox());
    dio.close();
  });
}
