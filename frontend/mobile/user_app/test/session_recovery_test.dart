import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/app/app_router.dart';
import 'package:user_app/app/user_app.dart';
import 'package:user_app/core/network/dio_provider.dart';
import 'package:user_app/core/network/session_events.dart';
import 'package:user_app/features/auth/shared/auth_providers.dart';

void main() {
  testWidgets('session rejection routes to login and clears signed-in state', (tester) async {
    FlutterSecureStorage.setMockInitialValues({'auth_token': 'expired-token'});
    final container = ProviderContainer(overrides: [dioProvider.overrideWithValue(Dio())]);
    addTearDown(container.dispose);
    await container.read(isLoggedInProvider.notifier).checkAuthStatus();
    expect(container.read(isLoggedInProvider), isTrue);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const UserApp()));
    container.read(sessionExpiredProvider.notifier).state++;
    await tester.pump();
    expect(container.read(isLoggedInProvider), isFalse);
    expect(AppRouter.router.routeInformationProvider.value.uri.path, AppRouter.login);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });
}
