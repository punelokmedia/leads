import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/core/network/api_endpoints.dart';
import 'package:user_app/core/network/dio_provider.dart';
import 'package:user_app/features/payments/presentation/widgets/wallet_card.dart';
import 'package:user_app/features/profile/presentation/screens/change_password_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Dio dio;
  late List<RequestOptions> requests;
  var fail = false;
  setUpAll(() async {
    final loader = FontLoader('ProfileMontserrat');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/Montserrat-$weight.ttf'));
    }
    await loader.load();
  });
  setUp(() {
    fail = false;
    requests = [];
    dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          requests.add(request);
          if (fail) {
            handler.reject(
              DioException(
                requestOptions: request,
                response: Response(
                  requestOptions: request,
                  statusCode: 400,
                  data: {'message': 'Current password is incorrect'},
                ),
              ),
            );
          } else {
            handler.resolve(
              Response(requestOptions: request, data: {'success': true}),
            );
          }
        },
      ),
    );
    addTearDown(dio.close);
  });

  Future<void> mount(WidgetTester tester, {double scale = 1}) async {
    tester.view.physicalSize = scale == 1
        ? const Size(393, 913)
        : const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/password'),
              child: const Text('Account'),
            ),
          ),
        ),
        GoRoute(
          path: '/password',
          builder: (_, _) => const RepaintBoundary(
            key: ValueKey('password-capture'),
            child: ChangePasswordScreen(),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dioProvider.overrideWithValue(dio),
          walletProvider.overrideWith((ref) async => {'balancePaise': 50000}),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/figma/profile-logo.png'),
        tester.element(find.byType(ChangePasswordScreen)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder.hitTestable());
    await tester.pumpAndSettle();
  }

  testWidgets(
    'redesign preserves password validation and visibility controls',
    (tester) async {
      await mount(tester);
      expect(tester.takeException(), isNull);
      expect(requests, isEmpty);
      if (const bool.fromEnvironment('UPDATE_PASSWORD_PREVIEW')) {
        await tester.runAsync(() async {
          final image = await tester
              .renderObject<RenderRepaintBoundary>(
                find.byKey(const ValueKey('password-capture')),
              )
              .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            '../../../.tmp/password-implemented.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tapVisible(tester, find.text('Update Password'));
      expect(find.text('Required'), findsNWidgets(3));
      await tester.enterText(find.byType(TextFormField).at(0), 'Oldsecret1');
      await tester.enterText(find.byType(TextFormField).at(1), '12345');
      await tester.enterText(find.byType(TextFormField).at(2), '12345');
      await tapVisible(tester, find.text('Update Password'));
      expect(find.text('Min 6 characters'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).at(1), 'Strong123');
      await tapVisible(tester, find.text('Update Password'));
      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(requests, isEmpty);
      await tapVisible(tester, find.byTooltip('Show password').first);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).first)
            .obscureText,
        isFalse,
      );
    },
  );

  testWidgets('existing password API payload and error retry remain intact', (
    tester,
  ) async {
    await mount(tester);
    for (var i = 0; i < 3; i++) {
      await tester.enterText(
        find.byType(TextFormField).at(i),
        i == 0 ? 'Oldsecret1' : 'Strong123',
      );
    }
    fail = true;
    await tapVisible(tester, find.text('Update Password'));
    expect(find.text('Current password is incorrect'), findsOneWidget);
    expect(find.byType(ChangePasswordScreen), findsOneWidget);
    expect(requests.single.path, ApiEndpoints.changePassword);
    expect(requests.single.method, 'POST');
    expect(requests.single.data, {
      'oldPassword': 'Oldsecret1',
      'newPassword': 'Strong123',
      'confirmPassword': 'Strong123',
    });
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    fail = false;
    await tapVisible(tester, find.text('Update Password'));
    expect(find.byType(ChangePasswordScreen), findsNothing);
    expect(requests.length, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'large-text narrow screen supports Cancel without changing backend behavior',
    (tester) async {
      await mount(tester, scale: 1.4);
      expect(tester.takeException(), isNull);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);
      await tapVisible(tester, find.text('Cancel'));
      expect(find.byType(ChangePasswordScreen), findsNothing);
      expect(requests, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
