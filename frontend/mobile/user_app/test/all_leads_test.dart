import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/core/network/dio_provider.dart';
import 'package:user_app/features/home/infra/home_repository.dart';
import 'package:user_app/features/home/presentation/widgets/home_banner_carousel.dart';
import 'package:user_app/features/preview/category_leads_page.dart';
import 'package:user_app/features/preview/figma_widgets.dart';
import 'package:user_app/features/preview/home_dashboard.dart';
import 'package:user_app/features/preview/live_store.dart';
import 'package:user_app/features/preview/preview_app.dart';

Map<String, dynamic> lead(int i) => {
  '_id': '$i',
  'leadDisplayId': 'NL$i',
  'title': 'Project $i',
  'category': {
    '_id': i % 15 == 0 ? 'painting' : 'solar',
    'name': i % 15 == 0 ? 'Painting' : 'Solar',
  },
  'city': 'Delhi',
  'state': 'Delhi',
  'price': 99,
  'createdAt': '2026-11-01T10:00:00Z',
  'expiresAt': '2099-01-01T00:00:00Z',
  'status': i < 31
      ? 'ACTIVE'
      : i < 42
      ? 'SOLD_OUT'
      : 'EXPIRED',
  'isPurchased': false,
  'buyersCount': i < 31 ? 0 : 2,
  'maxBuyers': 2,
};

void main() {
  for (final search in [false, true]) {
    test(
      'repository loads every page for ${search ? 'search' : 'browsing'}',
      () async {
        final dio = Dio();
        addTearDown(dio.close);
        final requests = <RequestOptions>[];
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (request, handler) {
              requests.add(request);
              final page = request.queryParameters['page'] as int;
              handler.resolve(
                Response(
                  requestOptions: request,
                  data: {
                    'success': true,
                    'data': List.generate(
                      page == 1 ? 25 : 20,
                      (i) => lead(i + (page == 1 ? 0 : 25)),
                    ),
                    'pagination': {'total': 45, 'totalPages': 2},
                  },
                ),
              );
            },
          ),
        );
        final repository = HomeRepository(dio);
        final leads = search
            ? await repository.searchLeads('Project')
            : await repository.fetchLeads(city: 'Delhi');
        expect(leads.length, 45);
        expect(leads.map((row) => row.id).toSet().length, 45);
        expect(requests.map((r) => r.queryParameters['page']), [1, 2]);
        expect(requests.every((r) => r.queryParameters['limit'] == 50), isTrue);
        expect(
          requests.every(
            (r) =>
                r.queryParameters[search ? 'search' : 'city'] ==
                (search ? 'Project' : 'delhi'),
          ),
          isTrue,
        );
      },
    );
  }

  testWidgets(
    'Home exposes all 45 server leads and clears the three-lead category on return',
    (tester) async {
      tester.view.physicalSize = const Size(393, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      FlutterSecureStorage.setMockInitialValues({});
      final dio = Dio();
      addTearDown(dio.close);
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            final data = request.path.endsWith('get-all-categories')
                ? [
                    {'_id': 'painting', 'name': 'Painting'},
                    {'_id': 'solar', 'name': 'Solar'},
                  ]
                : request.path.endsWith('get-all-cities')
                ? [
                    {'name': 'Delhi'},
                  ]
                : request.path.endsWith('get-all-leads')
                ? List.generate(45, lead)
                : {'balancePaise': 0};
            handler.resolve(
              Response(
                requestOptions: request,
                data: {
                  'success': true,
                  'data': data,
                  'pagination': {'total': 45, 'totalPages': 1},
                },
              ),
            );
          },
        ),
      );
      final store = LiveStore(dio, signedIn: false);
      addTearDown(store.dispose);
      await tester.runAsync(store.refresh);
      expect(store.leads.length, 45);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dioProvider.overrideWithValue(dio),
            homeBannersProvider.overrideWith((ref) async => []),
          ],
          child: MaterialApp(home: PreviewHome(store: store)),
        ),
      );
      await tester.pumpAndSettle();
      int count() =>
          (tester
                      .widget<ListView>(
                        find.descendant(
                          of: find.byType(NextLeadDashboard),
                          matching: find.byType(ListView),
                        ),
                      )
                      .childrenDelegate
                  as SliverChildBuilderDelegate)
              .childCount!;
      expect(count(), 46);
      expect(find.byType(FigmaLeadCard).evaluate().length, lessThan(45));
      await tester.tap(find.text('Painting').first);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CategoryLeadsPage>(find.byType(CategoryLeadsPage))
            .leads
            .length,
        3,
      );
      await tester.tap(find.text('Home').last);
      await tester.pumpAndSettle();
      expect(count(), 46);
      await tester.enterText(find.byType(TextField).first, 'Project 44');
      await tester.pumpAndSettle();
      expect(count(), 2);
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Home').last);
      await tester.pumpAndSettle();
      expect(count(), 46);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText).first)
            .controller
            .text,
        isEmpty,
      );
      await tester.scrollUntilVisible(
        find.text('Project 44').hitTestable(),
        600,
        scrollable: find
            .descendant(
              of: find.byType(NextLeadDashboard),
              matching: find.byType(Scrollable),
            )
            .first,
        maxScrolls: 60,
      );
      await tester.pumpAndSettle();
      expect(find.text('Project 44').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
