import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/core/network/dio_provider.dart';
import 'package:user_app/core/theme/app_theme.dart';
import 'package:user_app/features/auth/shared/auth_providers.dart';
import 'package:user_app/features/payments/presentation/widgets/wallet_card.dart';
import 'package:user_app/features/support/presentation/screens/notifications_page.dart';

void main() {
  for (final width in [320.0, 393.0]) {
    testWidgets('API notification filters and read status fit at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      FlutterSecureStorage.setMockInitialValues({'auth_token': 'test-token'});
      final requests = <String>[];
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            requests.add('${request.method} ${request.path}');
            handler.resolve(
              Response(
                requestOptions: request,
                data: request.method == 'GET'
                    ? {
                        'success': true,
                        'data': [
                          {
                            '_id': 'real-lead',
                            'type': 'NEW_LEAD',
                            'title': 'Server lead title',
                            'message': 'Server lead message',
                            'createdAt': DateTime.now()
                                .toUtc()
                                .toIso8601String(),
                            'readAt': null,
                          },
                          {
                            '_id': 'real-payment',
                            'type': 'PAYMENT_SUCCESS',
                            'title': 'Server payment title',
                            'message': 'Server payment message',
                            'createdAt': DateTime.now()
                                .toUtc()
                                .toIso8601String(),
                            'readAt': null,
                          },
                        ],
                        'nextCursor': null,
                      }
                    : {'success': true},
              ),
            );
          },
        ),
      );
      final container = ProviderContainer(
        overrides: [
          dioProvider.overrideWithValue(dio),
          walletProvider.overrideWith((ref) async => {'balancePaise': 0}),
        ],
      );
      addTearDown(container.dispose);
      await container.read(isLoggedInProvider.notifier).checkAuthStatus();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const NotificationScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Server lead title'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('2 BHK Interior Painting'), findsNothing);
      await tester.tap(find.text('Mark all as read \u2713'));
      await tester.pumpAndSettle();
      expect(requests, contains('PATCH api/v1/notifications/read-all'));
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Payments'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Payments'));
      await tester.pumpAndSettle();
      expect(find.text('Server lead title'), findsNothing);
      expect(find.text('Server payment title'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Empty inbox contains no sample messages', (tester) async {
    FlutterSecureStorage.setMockInitialValues({'auth_token': 'test-token'});
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) => handler.resolve(
            Response(
              requestOptions: request,
              data: {'success': true, 'data': [], 'nextCursor': null},
            ),
          ),
        ),
      );
    final container = ProviderContainer(
      overrides: [
        dioProvider.overrideWithValue(dio),
        walletProvider.overrideWith((ref) async => {'balancePaise': 0}),
      ],
    );
    addTearDown(container.dispose);
    await container.read(isLoggedInProvider.notifier).checkAuthStatus();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const NotificationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No notifications yet'), findsOneWidget);
    expect(find.text('Payment Successful'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
