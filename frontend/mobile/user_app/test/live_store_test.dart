import 'package:user_app/features/preview/lead_filters_sheet.dart';
import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:user_app/features/home/presentation/widgets/home_banner_carousel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/preview/live_store.dart';
import 'package:user_app/features/preview/preview_app.dart';
import 'package:user_app/features/preview/lead_details_page.dart';

void main() {
  late Dio dio;
  late List<RequestOptions> requests;
  bool fail = false;
  bool rejectSave = false;
  Map<String, dynamic> lead(String id, {bool purchased = false}) => {
    '_id': id,
    'leadDisplayId': 'NL$id',
    'title': 'Real project $id',
    'category': {'_id': 'custom', 'name': 'Solar installation'},
    'city': 'Delhi',
    'state': 'Delhi',
    'price': 275.50,
    'budget': {'min': 10000, 'max': 80000},
    'buyersCount': 2,
    'maxBuyers': 5,
    'status': 'ACTIVE',
    'isPurchased': purchased,
    'expiresAt': '2099-01-01T00:00:00Z',
  };
  final profile = {
    'firstname': 'Real',
    'lastname': 'Vendor',
    'email': 'real@example.com',
    'phoneNumber': '9876543210',
    'businessName': 'Solar Co',
    'workType': 'Solar installation',
    'city': 'Delhi',
    'state': 'Delhi',
  };
  setUp(() {
    fail = false;
    rejectSave = false;
    requests = [];
    dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          requests.add(request);
          if (fail || rejectSave && request.method == 'PUT') {
            handler.reject(DioException(requestOptions: request));
            return;
          }
          dynamic data;
          Map<String, dynamic>? pagination;
          if (request.path.endsWith('get-all-categories')) {
            data = [
              {'_id': 'custom', 'name': 'Solar installation'},
            ];
          } else if (request.path.endsWith('get-all-cities')) {
            data = [
              {'name': 'Delhi'},
            ];
          } else if (request.path.endsWith('get-all-leads')) {
            final page = request.queryParameters['page'];
            data = [lead('$page', purchased: page == 1)];
            pagination = {'totalPages': 2};
          } else if (request.path.contains('get-lead/')) {
            data = {
              ...lead('1', purchased: true),
              'customerName': 'Paid client',
              'primaryPhone': '9123456789',
            };
          } else if (request.path.endsWith('update-profile')) {
            data = request.data;
          } else if (request.path.endsWith('profile')) {
            data = profile;
          } else if (request.path.endsWith('history')) {
            data = [
              {
                'orderId': 'order-1',
                'totalAmount': 275,
                'items': [
                  {'leadId': '1'},
                ],
              },
            ];
          } else {
            throw StateError('Unexpected endpoint: ${request.path}');
          }
          handler.resolve(
            Response(
              requestOptions: request,
              data: {'success': true, 'data': data, 'pagination': pagination},
            ),
          );
        },
      ),
    );
  });

  test(
    'first lead page starts before metadata and concurrent refresh is deduplicated',
    () async {
      final metadata = Completer<void>(), firstPage = Completer<void>();
      dio.interceptors.insert(
        0,
        InterceptorsWrapper(
          onRequest: (request, handler) async {
            if (request.path.endsWith('get-all-categories')) {
              await metadata.future;
            }
            if (request.path.endsWith('get-all-leads') &&
                !firstPage.isCompleted) {
              firstPage.complete();
            }
            handler.next(request);
          },
        ),
      );
      final store = LiveStore(dio, signedIn: false);
      addTearDown(store.dispose);
      final refresh = store.refresh();
      try {
        await firstPage.future.timeout(const Duration(seconds: 2));
        expect(metadata.isCompleted, isFalse);
        await store.refresh();
      } finally {
        metadata.complete();
        await refresh;
      }
      expect(store.error, isNull);
      expect(
        requests
            .where(
              (r) =>
                  r.path.endsWith('get-all-leads') &&
                  r.queryParameters['page'] == 1,
            )
            .length,
        1,
      );
    },
  );

  test(
    'purchased contact loading is bounded to four requests and preserves order',
    () async {
      var active = 0, peak = 0, contacts = 0;
      dio.interceptors.insert(
        0,
        InterceptorsWrapper(
          onRequest: (request, handler) async {
            if (request.path.endsWith('get-all-leads')) {
              handler.resolve(
                Response(
                  requestOptions: request,
                  data: {
                    'success': true,
                    'data': List.generate(
                      7,
                      (i) => lead('$i', purchased: true),
                    ),
                    'pagination': {'totalPages': 1},
                  },
                ),
              );
            } else if (request.path.contains('get-lead/')) {
              active++;
              contacts++;
              if (active > peak) peak = active;
              await Future<void>.delayed(const Duration(milliseconds: 1));
              active--;
              final id = request.path.split('/').last;
              handler.resolve(
                Response(
                  requestOptions: request,
                  data: {
                    'success': true,
                    'data': {
                      ...lead(id, purchased: true),
                      'primaryPhone': '9123456789',
                    },
                  },
                ),
              );
            } else {
              handler.next(request);
            }
          },
        ),
      );
      final store = LiveStore(dio, signedIn: true);
      addTearDown(store.dispose);
      await store.refresh();
      expect(store.error, isNull);
      expect(peak, 4);
      expect(contacts, 7);
      expect(
        store.leads.map((lead) => lead.backendId),
        List.generate(7, (i) => '$i'),
      );
      expect(
        store.leads.every((lead) => lead.contact.contains('9123456789')),
        isTrue,
      );
    },
  );

  test(
    'applied filters reach every API page using backend category IDs',
    () async {
      final store = LiveStore(dio, signedIn: false);
      addTearDown(store.dispose);
      await store.refresh();
      requests.clear();
      await store.applyFilters(
        const LeadFilters(
          city: 'Delhi',
          category: 0,
          minBudget: 10000,
          maxBudget: 90000,
          minArea: 500,
          maxArea: 2000,
          timeline: 'Within 1 Month',
          postedDays: 1,
        ),
      );
      final calls = requests
          .where((r) => r.path.endsWith('get-all-leads'))
          .toList();
      expect(calls.length, 2);
      for (final call in calls) {
        expect(call.queryParameters['city'], 'Delhi');
        expect(call.queryParameters['category'], 'custom');
        expect(call.queryParameters['budgetMin'], 10000);
        expect(call.queryParameters['budgetMax'], 90000);
        expect(call.queryParameters['areaMin'], 500);
        expect(call.queryParameters['areaMax'], 2000);
        expect(call.queryParameters['timeline'], 'Within 1 Month');
        expect(
          DateTime.parse(call.queryParameters['postedSince']).isUtc,
          isTrue,
        );
      }
      expect(store.filteredLeads!.length, 2);
      expect(store.filtering, isFalse);
      fail = true;
      await expectLater(
        store.applyFilters(const LeadFilters(city: 'Pune')),
        throwsA(isA<DioException>()),
      );
      expect(store.filteredLeads!.length, 2);
      expect(store.filtering, isFalse);
      fail = false;
      await store.applyFilters(const LeadFilters());
      final cleared = requests.last.queryParameters;
      expect(cleared.containsKey('city'), isFalse);
      expect(cleared.containsKey('category'), isFalse);
      expect(cleared.containsKey('budgetMin'), isFalse);
    },
  );

  test(
    'loads every page, backend categories, limits and purchased contacts',
    () async {
      final store = LiveStore(dio, signedIn: true);
      addTearDown(store.dispose);
      await store.refresh();
      expect(store.error, isNull);
      expect(store.leads.length, 2);
      expect(store.categories.single.name, 'Solar installation');
      expect(store.leads.first.maxBuyers, 5);
      expect(store.leads.first.fee, 275.50);
      expect(store.leads.first.closed, isFalse);
      expect(store.leads.first.contact, contains('9123456789'));
      expect(store.leads.last.joined, isFalse);
      expect(store.receipts.single.leadId, 'order-1');
      expect(store.profile['Full name'], 'Real Vendor');
      expect(requests.where((r) => r.path.contains('get-lead/')).length, 1);
      expect(() => store.purchase(store.leads.last), throwsStateError);
      store.toggleSaved(store.leads.last);
      await store.refresh();
      expect(store.leads.last.saved, isTrue);
    },
  );

  test('failed load does not fall back to sample data and can retry', () async {
    final store = LiveStore(dio, signedIn: false);
    addTearDown(store.dispose);
    fail = true;
    await store.refresh();
    expect(store.error, isNotNull);
    expect(store.leads, isEmpty);
    expect(store.categories, isEmpty);
    expect(store.profile['Full name'], isEmpty);
    fail = false;
    await store.refresh();
    expect(store.error, isNull);
    expect(
      requests.any(
        (r) => r.path.endsWith('profile') || r.path.endsWith('history'),
      ),
      isFalse,
    );
  });

  test('location preferences persist only after server success', () async {
    final store = LiveStore(dio, signedIn: true);
    addTearDown(store.dispose);
    await store.refresh();
    rejectSave = true;
    await expectLater(
      store.saveLocation('Pune', 50, ['Baner']),
      throwsA(isA<DioException>()),
    );
    expect(store.profile['City'], 'Delhi');
    expect(store.serviceRadiusKm, 25);
    rejectSave = false;
    await store.saveLocation('Pune', 50, ['Baner']);
    expect(requests.last.data['serviceRadiusKm'], 50);
    expect(store.profile['City'], 'Pune');
    expect(store.profile['State'], isEmpty);
    expect(store.serviceRadiusKm, 50);
    expect(store.additionalAreas, ['Baner']);
  });

  test(
    'service selections save category IDs only after backend success',
    () async {
      final store = LiveStore(dio, signedIn: true);
      addTearDown(store.dispose);
      await store.refresh();
      rejectSave = true;
      await expectLater(
        store.saveServiceCategories({'Solar installation'}),
        throwsA(isA<DioException>()),
      );
      expect(store.serviceCategories, isEmpty);
      rejectSave = false;
      await store.saveServiceCategories({'Solar installation'});
      expect(requests.last.data, {
        'categories': ['custom'],
      });
      expect(store.serviceCategories, {'Solar installation'});
    },
  );

  test(
    'profile updates wait for backend success and preserve data on failure',
    () async {
      final store = LiveStore(dio, signedIn: true);
      addTearDown(store.dispose);
      await store.refresh();
      final edit = {
        ...store.profile,
        'Full name': 'New Vendor',
        'Business name': 'New Solar Co',
        'Business type': 'Partnership',
        'GST number': '27ABCDE1234F1Z5',
        'Business address': '42 Park Road',
        'Service area': 'Delhi and nearby areas',
        'Years in business': '3–5 years',
        'Website': 'https://solar.example.com',
      };
      rejectSave = true;
      await expectLater(store.saveProfile(edit), throwsA(isA<DioException>()));
      expect(store.profile['Full name'], 'Real Vendor');
      rejectSave = false;
      await store.saveProfile(edit);
      expect(store.profile['Full name'], 'New Vendor');
      expect(requests.last.data['businessName'], 'New Solar Co');
      expect(requests.last.data['businessAddress'], '42 Park Road');
      expect(requests.last.data['gstNumber'], '27ABCDE1234F1Z5');
      expect(store.profile['Business type'], 'Partnership');
      expect(store.profile['Service area'], 'Delhi and nearby areas');
      expect(store.profile['Years in business'], '3–5 years');
      expect(store.profile['Website'], 'https://solar.example.com');
    },
  );

  testWidgets('live empty home renders without preview fixtures', (
    tester,
  ) async {
    final store = LiveStore(dio, signedIn: false);
    addTearDown(store.dispose);
    await pumpScoped(tester, MaterialApp(home: PreviewHome(store: store)));
    expect(find.text('Explore your first lead'), findsNothing);
    expect(find.textContaining('TEST MODE'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('live purchased details show backend contact and vendor limit', (
    tester,
  ) async {
    final store = LiveStore(dio, signedIn: true);
    addTearDown(store.dispose);
    await tester.runAsync(store.refresh);
    await pumpScoped(
      tester,
      MaterialApp(
        home: LeadDetailsPreview(lead: store.leads.first, store: store),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Paid client'), findsNothing);
    expect(find.textContaining('Demo Client'), findsNothing);
    expect(find.text('Lead Unlocked'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> pumpScoped(WidgetTester tester, Widget child) => tester.pumpWidget(
  ProviderScope(
    overrides: [homeBannersProvider.overrideWith((ref) async => [])],
    child: child,
  ),
);
