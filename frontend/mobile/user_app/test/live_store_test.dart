import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/preview/live_store.dart';
import 'package:user_app/features/preview/preview_app.dart';

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
      };
      rejectSave = true;
      await expectLater(store.saveProfile(edit), throwsA(isA<DioException>()));
      expect(store.profile['Full name'], 'Real Vendor');
      rejectSave = false;
      await store.saveProfile(edit);
      expect(store.profile['Full name'], 'New Vendor');
      expect(requests.last.data['businessName'], 'New Solar Co');
    },
  );

  testWidgets('live empty home renders without preview fixtures', (
    tester,
  ) async {
    final store = LiveStore(dio, signedIn: false);
    addTearDown(store.dispose);
    await tester.pumpWidget(MaterialApp(home: PreviewHome(store: store)));
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
    await tester.pumpWidget(
      MaterialApp(
        home: LeadDetailsPreview(lead: store.leads.first, store: store),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Client Contact'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Paid client'), findsOneWidget);
    expect(find.textContaining('Demo Client'), findsNothing);
    expect(
      find.text('Up to 5 vendors can access client details'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
