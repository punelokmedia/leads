import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/core/network/auth_interceptor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();

  test('Google credential rejection preserves the existing app session', () async {
    FlutterSecureStorage.setMockInitialValues({'auth_token': 'saved-token'});
    var expired = 0;
    final dio = Dio();
    dio.interceptors.add(AuthInterceptor(storage, onSessionExpired: () => expired++));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      expect(options.headers.containsKey('Authorization'), isFalse);
      handler.reject(DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 401),
        type: DioExceptionType.badResponse,
      ), true);
    }));
    await expectLater(
      dio.post('https://example.invalid/api/v1/auth/google',
        options: Options(extra: {'skipSessionAuth': true})),
      throwsA(isA<DioException>()),
    );
    expect(await storage.read(key: 'auth_token'), 'saved-token');
    expect(expired, 0);
  });

  for (final status in [401, 403, 429, 500, 503]) {
    test(
      'HTTP $status ${status == 401 ? 'clears rejected' : 'preserves'} session',
      () async {
        FlutterSecureStorage.setMockInitialValues({
          'auth_token': 'saved-token',
        });
        var expired = 0;
        final dio = Dio();
        dio.interceptors.add(
          AuthInterceptor(storage, onSessionExpired: () => expired++),
        );
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response(
                    requestOptions: options,
                    statusCode: status,
                  ),
                  type: DioExceptionType.badResponse,
                ),
                true,
              );
            },
          ),
        );
        await expectLater(
          dio.get('https://example.invalid/profile'),
          throwsA(isA<DioException>()),
        );
        expect(
          await storage.read(key: 'auth_token'),
          status == 401 ? null : 'saved-token',
        );
        expect(expired, status == 401 ? 1 : 0);
      },
    );
  }

  for (final type in [DioExceptionType.connectionError,
    DioExceptionType.connectionTimeout, DioExceptionType.receiveTimeout]) {
    test('$type preserves login so retry can recover', () async {
      FlutterSecureStorage.setMockInitialValues({'auth_token': 'saved-token'});
      var expired = 0;
      final dio = Dio();
      dio.interceptors.add(AuthInterceptor(storage, onSessionExpired: () => expired++));
      var failing = true;
      dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        if (failing) {
          handler.reject(DioException(requestOptions: options, type: type), true);
        } else {
          expect(options.headers['Authorization'], 'Bearer saved-token');
          handler.resolve(Response(requestOptions: options, statusCode: 200,
            data: {'success': true}));
        }
      }));
      await expectLater(dio.get('https://example.invalid/profile'), throwsA(isA<DioException>()));
      expect(await storage.read(key: 'auth_token'), 'saved-token');
      expect(expired, 0);
      failing = false;
      expect((await dio.get('https://example.invalid/profile')).statusCode, 200);
    });
  }

  test('anonymous 401 does not expire a session', () async {
    FlutterSecureStorage.setMockInitialValues({});
    var expired = 0;
    final dio = Dio();
    dio.interceptors.add(AuthInterceptor(storage, onSessionExpired: () => expired++));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      handler.reject(DioException(requestOptions: options,
        response: Response(requestOptions: options, statusCode: 401),
        type: DioExceptionType.badResponse), true);
    }));
    await expectLater(dio.get('https://example.invalid/login'), throwsA(isA<DioException>()));
    expect(expired, 0);
  });

  test('a new login works after a rejected saved session without reinstalling', () async {
    FlutterSecureStorage.setMockInitialValues({'auth_token': 'expired-token'});
    var expired = 0;
    final dio = Dio();
    dio.interceptors.add(AuthInterceptor(storage, onSessionExpired: () => expired++));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      if (options.headers['Authorization'] == 'Bearer expired-token') {
        handler.reject(DioException(requestOptions: options,
          response: Response(requestOptions: options, statusCode: 401),
          type: DioExceptionType.badResponse), true);
      } else {
        expect(options.headers['Authorization'], 'Bearer fresh-token');
        handler.resolve(Response(requestOptions: options, statusCode: 200));
      }
    }));
    await expectLater(dio.get('https://example.invalid/profile'), throwsA(isA<DioException>()));
    expect(await storage.read(key: 'auth_token'), isNull);
    await storage.write(key: 'auth_token', value: 'fresh-token');
    expect((await dio.get('https://example.invalid/profile')).statusCode, 200);
    expect(expired, 1);
  });

  test(
    'explicit authentication headers are preserved and cannot clear another session',
    () async {
      FlutterSecureStorage.setMockInitialValues({'auth_token': 'new-token'});
      var expired = 0;
      final dio = Dio();
      dio.interceptors.add(
        AuthInterceptor(storage, onSessionExpired: () => expired++),
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.headers['Authorization'], 'Bearer old-token');
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(requestOptions: options, statusCode: 401),
                type: DioExceptionType.badResponse,
              ),
              true,
            );
          },
        ),
      );
      await expectLater(
        dio.get(
          'https://example.invalid/profile',
          options: Options(headers: {'Authorization': 'Bearer old-token'}),
        ),
        throwsA(isA<DioException>()),
      );
      expect(await storage.read(key: 'auth_token'), 'new-token');
      expect(expired, 0);
    },
  );
}
