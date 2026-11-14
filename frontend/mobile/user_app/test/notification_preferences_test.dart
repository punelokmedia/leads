import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/core/network/dio_provider.dart';
import 'package:user_app/features/payments/presentation/widgets/wallet_card.dart';
import 'package:user_app/features/preview/preview_data.dart';
import 'package:user_app/features/support/presentation/screens/notification_preferences_page.dart';

class _LiveStore extends PreviewStore {
  @override
  bool get isLive => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Dio dio;
  late Map<String, bool> server;
  late List<RequestOptions> requests;
  bool failLoad = false, failSave = false;
  setUpAll(() async {
    final loader = FontLoader('ProfileMontserrat');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/Montserrat-$weight.ttf'));
    }
    await loader.load();
  });
  setUp(() {
    final wasFatal = WidgetController.hitTestWarningShouldBeFatal;
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = wasFatal);
    failLoad = failSave = false;
    server = {
      'newLeads': true,
      'leadUpdates': true,
      'payments': true,
      'membership': true,
      'referrals': true,
      'announcements': false,
      'whatsapp': false,
    };
    requests = [];
    dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          requests.add(request);
          if (request.method == 'GET' && failLoad ||
              request.method == 'PATCH' && failSave) {
            handler.reject(DioException(requestOptions: request));
            return;
          }
          if (request.method == 'PATCH') {
            server.addAll(Map<String, bool>.from(request.data));
          }
          handler.resolve(
            Response(
              requestOptions: request,
              data: {'success': true, 'data': Map.of(server)},
            ),
          );
        },
      ),
    );
    addTearDown(dio.close);
  });

  Future<PreviewStore> mount(
    WidgetTester tester, {
    double scale = 1,
    bool live = true,
  }) async {
    tester.view.physicalSize = scale == 1
        ? const Size(393, 1144)
        : const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = live ? _LiveStore() : PreviewStore();
    addTearDown(store.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dioProvider.overrideWithValue(dio),
          walletProvider.overrideWith((ref) async => {'balancePaise': 50000}),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => RepaintBoundary(
                      key: const ValueKey('preferences-capture'),
                      child: NotificationPreferencesPage(store: store),
                    ),
                  ),
                ),
                child: const Text('Open preferences'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open preferences'));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/figma/profile-logo.png'),
        tester.element(find.byType(NotificationPreferencesPage)),
      ),
    );
    await tester.pumpAndSettle();
    return store;
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder.hitTestable(),
      250,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(finder.hitTestable());
    await tester.pumpAndSettle();
  }

  testWidgets(
    'preferences cache loads, patch sends changes only, cancel discards edits',
    (tester) async {
      final store = await mount(tester);
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('UPDATE_PREFERENCES_PREVIEW')) {
        await tester.runAsync(() async {
          final image = await tester
              .renderObject<RenderRepaintBoundary>(
                find.byKey(const ValueKey('preferences-capture')),
              )
              .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            '../../../.tmp/preferences-implemented.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.tap(find.byKey(const ValueKey('preference-newLeads')));
      await tester.pumpAndSettle();
      expect(store.notificationPreferences!['newLeads'], isTrue);
      await tapVisible(tester, find.text('Save Preferences'));
      expect(requests.where((r) => r.method == 'PATCH').single.data, {
        'newLeads': false,
      });
      expect(store.notificationPreferences!['newLeads'], isFalse);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open preferences'));
      await tester.pumpAndSettle();
      expect(requests.where((r) => r.method == 'GET').length, 1);
      await tester.tap(find.byKey(const ValueKey('preference-newLeads')));
      await tapVisible(tester, find.text('Cancel'));
      expect(find.byType(NotificationPreferencesPage), findsNothing);
      expect(store.notificationPreferences!['newLeads'], isFalse);
      expect(requests.where((r) => r.method == 'PATCH').length, 1);
    },
  );

  testWidgets('load retry and save failure preserve the draft', (tester) async {
    failLoad = true;
    final store = await mount(tester);
    expect(find.text('Could not load preferences.'), findsOneWidget);
    failLoad = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('preference-newLeads')));
    failSave = true;
    await tapVisible(tester, find.text('Save Preferences'));
    expect(store.notificationPreferences!['newLeads'], isTrue);
    expect(find.byType(NotificationPreferencesPage), findsOneWidget);
    failSave = false;
    await tapVisible(tester, find.text('Save Preferences'));
    expect(store.notificationPreferences!['newLeads'], isFalse);
  });

  testWidgets(
    'large text on narrow screens preserves preview save functionality',
    (tester) async {
      final store = await mount(tester, scale: 1.4, live: false);
      expect(tester.takeException(), isNull);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('preference-whatsapp')),
      );
      await tapVisible(tester, find.text('Save Preferences'));
      expect(store.notificationPreferences!['whatsapp'], isTrue);
      expect(requests, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
