import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/features/cart/presentation/screens/payment_successful.dart';
import 'package:user_app/features/preview/lead_details_page.dart';
import 'package:user_app/core/network/dio_provider.dart';

final _confirmation = <String, dynamic>{
  'order': <String, dynamic>{
    'status': 'PAID',
    'totalAmount': 149,
    'items': [
      {'leadId': 'lead-1', 'price': 149, 'title': 'House construction'},
    ],
  },
  'lead': <String, dynamic>{
    '_id': 'lead-1',
    'leadDisplayId': 'NL-1',
    'title': 'House construction',
    'isPurchased': true,
    'category': {'displayName': 'Civil Construction'},
    'city': 'Pune',
    'state': 'Maharashtra',
    'budget': {'max': 3500000},
    'propertyType': '2 BHK Home',
    'areaSize': '1200 sq ft',
    'timeline': '6 Months',
  },
};

void main() {
  final pageScroll = find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable && widget.axisDirection == AxisDirection.down,
  );
  Future<void> mount(WidgetTester tester, {double scale = 1}) async {
    tester.view.physicalSize = scale == 1
        ? const Size(393, 1184)
        : const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final dio = Dio();
    addTearDown(dio.close);
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) => handler.resolve(
          Response(
            requestOptions: request,
            data: {'success': true, 'data': _confirmation['lead']},
          ),
        ),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dioProvider.overrideWithValue(dio),
          paymentConfirmationProvider(
            'order-1',
          ).overrideWith((ref) async => _confirmation),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const PaymentSuccessScreen(orderId: 'order-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('confirmed payment opens purchased lead without checkout', (
    tester,
  ) async {
    await mount(tester);
    expect(find.text('Payment Successful!'), findsOneWidget);
    expect(find.text('House construction'), findsOneWidget);
    final action = find.text('View Complete Lead Details →');
    await tester.scrollUntilVisible(action, 300, scrollable: pageScroll);
    expect(find.text('₹ 149'), findsOneWidget);
    expect(find.text('Not provided'), findsOneWidget);
    expect(find.text('order-1'), findsOneWidget);
    await tester.tap(action);
    await tester.pumpAndSettle();
    final details = tester.widget<LeadDetailsPreview>(
      find.byType(LeadDetailsPreview),
    );
    expect(details.lead.joined, isTrue);
    expect(details.lead.backendId, 'lead-1');
    expect(details.lead.area, '1200 sq ft');
    expect(find.text('Test checkout'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow payment layout supports enlarged text', (tester) async {
    await mount(tester, scale: 1.4);
    await tester.scrollUntilVisible(
      find.text('Go to Home →'),
      250,
      scrollable: pageScroll,
    );
    expect(tester.takeException(), isNull);
  });
}
