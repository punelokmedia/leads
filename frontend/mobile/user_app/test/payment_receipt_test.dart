import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/core/network/dio_provider.dart';
import 'package:user_app/features/payments/presentation/widgets/receipt_button.dart';

void main() {
  test('receipt lookup shares history and selects only the paid order', () async {
    var requests = 0;
    final dio = Dio();
    addTearDown(dio.close);
    dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
      requests++;
      handler.resolve(Response(requestOptions: request, data: {
        'success': true,
        'data': [
          {'orderId': 'failed', 'status': 'FAILED', 'items': [{'leadId': 'a'}]},
          {'orderId': 'paid', 'status': 'PAID', 'items': [{'leadId': 'a'}, {'leadId': 'b'}]},
        ],
      }));
    }));
    final container = ProviderContainer(overrides: [dioProvider.overrideWithValue(dio)]);
    addTearDown(container.dispose);
    final a = container.listen(receiptOrderProvider('a'), (_, _) {});
    final b = container.listen(receiptOrderProvider('b'), (_, _) {});
    addTearDown(a.close);
    addTearDown(b.close);
    expect(await container.read(receiptOrderProvider('a').future), 'paid');
    expect(await container.read(receiptOrderProvider('b').future), 'paid');
    expect(await container.read(receiptOrderProvider('missing').future), isNull);
    expect(requests, 1);
  });

  test('receipt download rejects non-PDF response before saving a file', () async {
    final dio = Dio();
    addTearDown(dio.close);
    dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
      expect(request.path, 'api/v1/leads/receipt/order-1');
      expect(request.responseType, ResponseType.bytes);
      handler.resolve(Response(requestOptions: request, data: <int>[123, 125], headers: Headers.fromMap({'content-type': ['application/json']})));
    }));
    await expectLater(savePaymentReceipt(dio, 'order-1'), throwsStateError);
  });
}
