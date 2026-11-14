import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/core/network/dio_provider.dart';
import 'package:user_app/features/preview/owned_lead_details_page.dart';
import 'package:user_app/features/preview/preview_data.dart';

void main() {
  for (final scale in [1.0, 1.4]) {
    testWidgets(
      'owned lead persists contact status and retries at scale $scale',
      (tester) async {
        tester.view.physicalSize = scale == 1
            ? const Size(393, 1072)
            : const Size(320, 760);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final dio = Dio(), store = PreviewStore.empty();
        addTearDown(dio.close);
        addTearDown(store.dispose);
        String? timestamp;
        var patches = 0;
        final urls = <String>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('nextlead/contact'),
          (call) async {
            urls.add(call.arguments['url'] as String);
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            const MethodChannel('nextlead/contact'),
            null,
          ),
        );
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (request, handler) {
              if (request.method == 'PATCH') {
                patches++;
                if (patches == 1) {
                  handler.reject(DioException(requestOptions: request));
                  return;
                }
                timestamp = DateTime.now().toUtc().toIso8601String();
                handler.resolve(
                  Response(
                    requestOptions: request,
                    data: {
                      'success': true,
                      'data': {'contactedAt': timestamp},
                    },
                  ),
                );
              } else {
                handler.resolve(
                  Response(
                    requestOptions: request,
                    data: {
                      'success': true,
                      'data': {
                        'isPurchased': true,
                        'customerName': 'Real Client',
                        'primaryPhone': '9876543210',
                        'email': 'client@example.com',
                        'areaLocality': 'Baner',
                        'city': 'Pune',
                        'contactedAt': timestamp,
                      },
                    },
                  ),
                );
              }
            },
          ),
        );
        final lead = PreviewLead(
          id: 'NL-1',
          backendId: 'lead-1',
          title: 'House construction',
          category: -1,
          city: 'Pune',
          state: 'Maharashtra',
          budget: 3500000,
          fee: 99,
          description: 'Ground + 1 floor construction\nModern elevation design',
          joined: true,
          propertyType: '2 BHK Home',
          area: '1200 sq ft',
          timeline: '6 Months',
        );
        store.leads = [lead];
        Future<void> mount() async {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [dioProvider.overrideWithValue(dio)],
              child: MaterialApp(
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: OwnedLeadDetailsPage(
                  lead: lead,
                  store: store,
                  categoryName: 'Civil Construction',
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        await mount();
        final scroll = find
            .descendant(
              of: find.byKey(const ValueKey('lead-details-scroll')),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(
          find.text('Call Now').hitTestable(),
          200,
          scrollable: scroll,
        );
        await tester.pumpAndSettle();
        expect(find.text('Real Client'), findsOneWidget);
        expect(find.text('client@example.com'), findsOneWidget);
        await tester.tap(find.text('Call Now').hitTestable());
        await tester.pumpAndSettle();
        expect(urls.single, 'tel:9876543210');
        await tester.tap(find.text('Mark as Contacted'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Could not save contact status'),
          findsOneWidget,
        );
        expect(find.text('Contacted'), findsNothing);
        await tester.tap(find.text('Mark as Contacted'));
        await tester.pumpAndSettle();
        expect(find.text('Contacted'), findsOneWidget);
        expect(patches, 2);
        await tester.pumpWidget(const SizedBox());
        await mount();
        expect(find.text('Contacted'), findsOneWidget);
        expect(patches, 2);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('unverified purchase never shows client data', (tester) async {
    final dio = Dio(), store = PreviewStore.empty();
    addTearDown(dio.close);
    addTearDown(store.dispose);
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) => handler.resolve(
          Response(
            requestOptions: request,
            data: {
              'success': true,
              'data': {'isPurchased': false, 'customerName': 'Private Client'},
            },
          ),
        ),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dioProvider.overrideWithValue(dio)],
        child: MaterialApp(
          home: OwnedLeadDetailsPage(
            lead: PreviewLead(
              id: 'NL-1',
              backendId: 'lead-1',
              title: 'House',
              category: -1,
              city: 'Pune',
              state: 'MH',
              budget: 0,
              fee: 99,
              description: '',
              joined: true,
            ),
            store: store,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Private Client'), findsNothing);
    expect(find.text('Mark as Contacted'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
  });
}
