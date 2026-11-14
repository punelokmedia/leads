import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/profile/presentation/widgets/live_referral_section.dart';

void main() {
  for (final width in [393.0, 320.0]) {
    testWidgets('referral design keeps live data, copy and filters at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final requests = <RequestOptions>[];
      final dio = Dio();
      addTearDown(dio.close);
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            requests.add(request);
            handler.resolve(
              Response(
                requestOptions: request,
                data: request.path.endsWith('/me')
                    ? {
                        'success': true,
                        'data': {
                          'referralCode': 'REAL-CODE',
                          'referralLink': 'https://example.com/real',
                          'invited': 3,
                          'qualified': 1,
                          'pending': 2,
                        },
                      }
                    : {
                        'success': true,
                        'data': request.queryParameters['status'] == 'PENDING'
                            ? <dynamic>[]
                            : [
                                {
                                  '_id': 'REF-1',
                                  'status': 'QUALIFIED',
                                  'createdAt': '2026-11-01T10:00:00Z',
                                },
                              ],
                        'pagination': {
                          'total':
                              request.queryParameters['status'] == 'PENDING'
                              ? 0
                              : 1,
                        },
                      },
              ),
            );
          },
        ),
      );
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = call.arguments['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(width == 320 ? 1.4 : 1)),
            child: child!,
          ),
          home: Scaffold(
            backgroundColor: const Color(0xFFE3EDFF),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(19),
              child: LiveReferralSection(dio: dio),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('REAL-CODE'), findsOneWidget);
      await tester.ensureVisible(find.text('Copy code'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy code'));
      await tester.pumpAndSettle();
      expect(copied, 'REAL-CODE');
      await tester.ensureVisible(find.text('Share referral invite'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Share referral invite'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Join NextLead using my referral code REAL-CODE'),
        findsOneWidget,
      );
      await tester.tap(find.text('Copy invitation'));
      await tester.pumpAndSettle();
      expect(copied, contains('https://example.com/real'));
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(requests.where((r) => r.path.endsWith('/me')).length, 1);
      await tester.ensureVisible(find.text('Pending'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pending'));
      await tester.pumpAndSettle();
      expect(requests.last.queryParameters['status'], 'PENDING');
      expect(find.text('No pending referrals'), findsOneWidget);
      await tester.ensureVisible(find.text('Successful'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Successful'));
      await tester.pumpAndSettle();
      expect(requests.last.queryParameters['status'], 'QUALIFIED');
      expect(find.text('Referral REF-1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
