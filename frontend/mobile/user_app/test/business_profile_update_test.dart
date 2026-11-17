import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/core/location/startup_location.dart';
import 'package:user_app/core/network/dio_provider.dart';
import 'package:user_app/features/payments/presentation/widgets/wallet_card.dart';
import 'package:user_app/features/preview/business_details_page.dart';
import 'package:user_app/features/preview/live_store.dart';

const location = StartupLocation(
  placemark: Placemark(
    street: 'Baner Road',
    subLocality: 'Baner',
    locality: 'Pune',
    administrativeArea: 'Maharashtra',
    postalCode: '411045',
  ),
);

void main() {
  late Dio dio;
  late LiveStore store;
  late Map<String, dynamic> saved;
  bool reject = false;
  setUp(() {
    saved = {};
    reject = false;
    dio = Dio();
    store = LiveStore(dio, signedIn: true);
    // Existing personal fields must not block an unrelated business update.
    store.profile = {
      'Full name': 'Vendor',
      'Email': '',
      'Phone': '',
      'Business name': 'Service Co',
      'City': '',
      'Business address': '',
      'Service area': '',
      'Years in business': '5+ years',
    };
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          expect(request.method, 'PUT');
          saved = Map<String, dynamic>.from(request.data as Map);
          for (final key in [
            'firstname',
            'lastname',
            'email',
            'phoneNumber',
            'workType',
          ]) {
            expect(saved.containsKey(key), isFalse, reason: key);
          }
          if (reject) {
            handler.reject(
              DioException(
                requestOptions: request,
                type: DioExceptionType.badResponse,
                response: Response(
                  requestOptions: request,
                  statusCode: 400,
                  data: {'message': 'Business update needs review'},
                ),
              ),
            );
          } else {
            handler.resolve(
              Response(
                requestOptions: request,
                data: {
                  'success': true,
                  'data': {
                    'firstname': 'Vendor',
                    'lastname': '',
                    'email': '',
                    'phoneNumber': '',
                    ...saved,
                  },
                },
              ),
            );
          }
        },
      ),
    );
  });
  tearDown(() {
    store.dispose();
    dio.close();
  });

  Future<void> mount(WidgetTester tester, Future<StartupLocation> gps) async {
    tester.view.physicalSize = const Size(393, 1184);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dioProvider.overrideWithValue(dio),
          startupLocationProvider.overrideWith((ref) => gps),
          walletProvider.overrideWith((ref) async => {'balancePaise': 0}),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => EditProfilePreview(store: store),
                  ),
                ),
                child: const Text('Open business'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open business'));
    await tester.pumpAndSettle();
  }

  String text(WidgetTester tester, String label) => tester
      .widget<TextFormField>(find.byKey(ValueKey(label)))
      .controller!
      .text;

  testWidgets(
    'GPS area names fill business form and business-only update succeeds',
    (tester) async {
      await mount(tester, Future.value(location));
      expect(
        text(tester, 'Business address'),
        'Baner Road, Baner, Pune, Maharashtra, 411045',
      );
      expect(text(tester, 'City'), 'Pune');
      expect(text(tester, 'Service area'), 'Baner');
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(find.text('Open business'), findsOneWidget);
      expect(saved['businessAddress'], contains('Baner'));
      expect(saved['city'], 'Pune');
      expect(saved['state'], 'Maharashtra');
      expect(store.profile['Business address'], contains('Baner'));
      expect(store.profile['Business name'], 'Service Co');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'late GPS preserves entered address; explicit location replaces it',
    (tester) async {
      final gps = Completer<StartupLocation>();
      await mount(tester, gps.future);
      await tester.ensureVisible(
        find.byKey(const ValueKey('Business address')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('Business address')),
        'My office',
      );
      gps.complete(location);
      await tester.pumpAndSettle();
      expect(text(tester, 'Business address'), 'My office');
      await tester.ensureVisible(
        find.byKey(const ValueKey('Use current location')),
      );
      await tester.tap(find.byKey(const ValueKey('Use current location')));
      await tester.pumpAndSettle();
      expect(text(tester, 'Business address'), contains('Baner Road'));
    },
  );

  testWidgets('server save error is shown and business draft stays editable', (
    tester,
  ) async {
    reject = true;
    await mount(tester, Future.value(location));
    await tester.ensureVisible(find.text('Save Changes'));
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
    expect(find.text('Business update needs review'), findsOneWidget);
    expect(find.byType(EditProfilePreview), findsOneWidget);
    expect(text(tester, 'Business address'), contains('Baner'));
    expect(store.profile['Business address'], isEmpty);
  });

  test(
    'location labels never use raw coordinates and rural city uses district',
    () {
      const gps = StartupLocation(
        placemark: Placemark(
          street: '18.500, 73.800',
          subLocality: 'Baner',
          subAdministrativeArea: 'Pune',
          administrativeArea: 'Maharashtra',
        ),
      );
      expect(gps.addressText, 'Baner, Pune, Maharashtra');
      expect(gps.cityName, 'Pune');
      expect(isCoordinateText('Latitude: 18.500, Longitude: 73.800'), isTrue);
    },
  );
}
