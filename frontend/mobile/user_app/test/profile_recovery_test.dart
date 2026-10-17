import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/core/network/dio_provider.dart';
import 'package:user_app/core/theme/app_theme.dart';
import 'package:user_app/features/profile/infra/profile_controller.dart';
import 'package:user_app/features/profile/presentation/screens/profile_screen.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets(
    'profile timeout offers retry and recovers without clearing login',
    (tester) async {
      tester.view.physicalSize = const Size(412, 917);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      FlutterSecureStorage.setMockInitialValues({
        'auth_token': 'saved-session',
      });
      final dio = Dio();
      var profileRequests = 0;
      var failProfile = true;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.endsWith('/profile')) {
              profileRequests++;
              if (failProfile) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    type: DioExceptionType.receiveTimeout,
                  ),
                );
                return;
              }
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'data': {
                      '_id': 'existing-user',
                      'firstname': 'Existing',
                      'lastname': 'User',
                      'email': 'test@example.com',
                      'city': 'Delhi',
                      'address': {'street': 'Main Road', 'city': 'Delhi'},
                      'businessName': 'Existing Business',
                    },
                  },
                ),
              );
            } else {
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {'success': true, 'data': <String, dynamic>{}},
                ),
              );
            }
          },
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileRepositoryProvider.overrideWithValue(ProfileRepository(dio)),
            dioProvider.overrideWithValue(dio),
          ],
          child: ScreenUtilPlusInit(
            designSize: const Size(412, 917),
            builder: (_, child) =>
                MaterialApp(theme: AppTheme.dark, home: const ProfileScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Sign in again'), findsOneWidget);
      expect(
        await const FlutterSecureStorage().read(key: 'auth_token'),
        'saved-session',
      );
      final title = tester.widget<Text>(find.text('My Profile'));
      expect(title.style!.color, AppTheme.dark.colorScheme.onSurface);
      final failedRequests = profileRequests;
      failProfile = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Existing Business'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
      expect(profileRequests, failedRequests + 1);
      expect(tester.takeException(), isNull);
    },
  );
}
