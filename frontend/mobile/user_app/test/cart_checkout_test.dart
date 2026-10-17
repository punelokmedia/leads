import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:user_app/core/network/dio_provider.dart';
import 'package:user_app/features/cart/domain/cart_model.dart';
import 'package:user_app/features/cart/infra/cart_controller.dart';
import 'package:user_app/features/cart/infra/cart_repository.dart';
import 'package:user_app/features/cart/presentation/screens/cart_screen.dart';
import 'package:user_app/features/cart/shared/cart_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  late Dio dio;
  late CartRepository repository;
  late List<RequestOptions> requests;
  var rejectPurchase = false;
  var cartReads = 0;
  List<Map<String, dynamic>> cartItems = [];
  List<Map<String, dynamic>> removed = [];

  Map<String, dynamic> lead(String id, num price) => {
    '_id': id,
    'title': 'Available $id',
    'price': price,
    'quantity': 1,
    'city': 'Pune',
    'state': 'Maharashtra',
    'remainingSlots': 1,
    'expiresAt': '2099-01-01T00:00:00Z',
  };
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('razorpay_flutter'),
          (_) async => null,
        );
    FlutterSecureStorage.setMockInitialValues({});
    requests = [];
    rejectPurchase = false;
    cartReads = 0;
    cartItems = [lead('shown-a', 12.5), lead('shown-b', 20)];
    removed = [
      {'title': 'Old lead', 'reason': 'This lead is sold out.'},
    ];
    dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          if (options.path.endsWith('/wallet/purchase')) {
            if (rejectPurchase) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.badResponse,
                  response: Response(
                    requestOptions: options,
                    statusCode: 409,
                    data: {
                      'success': false,
                      'code': 'SOLD_OUT',
                      'message': 'This lead is sold out. Review your cart.',
                    },
                  ),
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
                  'data': {'status': 'PAID', 'orderId': 'synthetic-order'},
                },
              ),
            );
            return;
          }
          if (options.path.endsWith('/payments/create')) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response(
                  requestOptions: options,
                  statusCode: 409,
                  data: {
                    'success': false,
                    'code': 'SOLD_OUT',
                    'message': 'This lead is sold out. Review your cart.',
                  },
                ),
              ),
            );
            return;
          }
          if (options.path.endsWith('/get-cart')) {
            cartReads++;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': {
                    'leads': cartItems,
                    'removedLeads': cartReads == 1 ? removed : [],
                  },
                },
              ),
            );
            return;
          }
          if (options.path.endsWith('/wallet')) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': {
                    'balancePaise': 10000,
                    'referralCreditPaise': 0,
                    'entries': [],
                    'nextCursor': null,
                  },
                },
              ),
            );
            return;
          }
          handler.reject(
            DioException(
              requestOptions: options,
              message: 'Unexpected test request',
            ),
          );
        },
      ),
    );
    repository = CartRepository(dio, const FlutterSecureStorage());
  });
  tearDown(() => dio.close(force: true));

  test(
    'Flutter cart uses exact available response, price and unavailable messages',
    () async {
      final snapshot = await repository.fetchRemoteCartState();
      final items = snapshot.items;
      expect(items.map((item) => item.id), ['shown-a', 'shown-b']);
      expect(items.first.price, 12.5);
      expect(
        snapshot.unavailableMessages.single,
        contains('This lead is sold out'),
      );
      expect(items.first.copyWith(isSelected: false).price, 12.5);
      expect(CartLead.fromJson(items.first.toJson()).price, 12.5);
    },
  );

  test(
    'Flutter wallet purchase sends only confirmed subset and displayed price',
    () async {
      final items = await repository.fetchRemoteCart();
      expect(
        await repository.purchaseSelected([items.first]),
        'synthetic-order',
      );
      final purchase = requests.singleWhere(
        (options) => options.path.endsWith('/wallet/purchase'),
      );
      expect(purchase.data, {
        'leadIds': ['shown-a'],
        'expectedTotalPaise': 1250,
      });
    },
  );

  test(
    'Flutter checkout failure never retries automatically and empty selection never submits',
    () async {
      final items = await repository.fetchRemoteCart();
      rejectPurchase = true;
      await expectLater(
        repository.purchaseSelected(items),
        throwsA(isA<DioException>()),
      );
      expect(
        requests
            .where((options) => options.path.endsWith('/wallet/purchase'))
            .length,
        1,
      );
      await expectLater(repository.purchaseSelected([]), throwsStateError);
      expect(
        requests
            .where((options) => options.path.endsWith('/wallet/purchase'))
            .length,
        1,
      );
    },
  );

  test(
    'Flutter gateway checkout conflict refreshes without replacing or retrying the selection',
    () async {
      final controller = CartController(repository, true);
      addTearDown(controller.dispose);
      await controller.loadCart();
      final before = cartReads;
      controller.toggleSelect('shown-b');
      cartItems = [lead('shown-b', 20)];
      String? error;
      await controller.startPaymentProcess(
        onOrderCreated: (_) => fail('Must not open checkout'),
        onError: (message) => error = message,
      );
      final request = requests.singleWhere(
        (options) => options.path.endsWith('/payments/create'),
      );
      expect(request.data, {
        'ids': ['shown-a'],
        'expectedTotalPaise': 1250,
      });
      expect(error, contains('sold out'));
      expect(cartReads, greaterThan(before));
      expect(controller.state.items.map((item) => item.id), ['shown-b']);
    },
  );

  testWidgets(
    'Flutter empty cart still displays reasons after all unavailable items removed',
    (tester) async {
      cartItems = [];
      late CartController controller;
      await tester.runAsync(() async {
        controller = CartController(repository, true);
        await controller.loadCart();
        await controller.loadCart();
      });
      expect(controller.state.items, isEmpty);
      expect(controller.state.availabilityMessages, isNotEmpty);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cartControllerProvider.overrideWith((ref) => controller),
            dioProvider.overrideWithValue(dio),
          ],
          child: ScreenUtilPlusInit(
            designSize: const Size(412, 917),
            builder: (_, child) => MaterialApp(home: child),
            child: const CartScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('cart-availability-notice')), findsOneWidget);
      expect(find.textContaining('This lead is sold out'), findsOneWidget);
      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.text('Pay from wallet'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'Flutter mixed cart failure refreshes the selection and shows the server reason without retrying',
    (tester) async {
      FlutterSecureStorage.setMockInitialValues({
        'auth_token': 'synthetic-session',
      });
      tester.view.physicalSize = const Size(412, 917);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cartRepositoryProvider.overrideWithValue(repository),
            dioProvider.overrideWithValue(dio),
          ],
          child: ScreenUtilPlusInit(
            designSize: const Size(412, 917),
            builder: (_, child) => MaterialApp(home: child),
            child: const CartScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('cart-availability-notice')), findsOneWidget);
      final context = tester.element(find.byType(CartScreen));
      final container = ProviderScope.containerOf(context);
      container.read(cartControllerProvider.notifier).toggleSelect('shown-b');
      await tester.pump();
      final readsBeforePurchase = cartReads;
      rejectPurchase = true;
      cartItems = [lead('shown-b', 20)];
      await tester.tap(find.text('Pay from wallet'));
      await tester.pumpAndSettle();
      final purchase = requests
          .where((options) => options.path.endsWith('/wallet/purchase'))
          .toList();
      expect(purchase.length, 1);
      expect(purchase.single.data, {
        'leadIds': ['shown-a'],
        'expectedTotalPaise': 1250,
      });
      expect(cartReads, greaterThan(readsBeforePurchase));
      expect(
        container.read(cartControllerProvider).items.map((item) => item.id),
        ['shown-b'],
      );
      expect(
        find.textContaining('This lead is sold out. Review your cart.'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
