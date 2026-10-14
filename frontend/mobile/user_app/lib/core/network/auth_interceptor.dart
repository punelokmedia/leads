import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  final void Function()? onSessionExpired;

  AuthInterceptor(this._storage, {this.onSessionExpired});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 1. Get the token from storage
    final token = await _storage.read(key: 'auth_token');

    // 2. If token exists, inject it into the headers
    if (token != null &&
        token.isNotEmpty &&
        !options.headers.containsKey('Authorization')) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // 3. Continue with the request
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    try {
      // Ignore old requests that fail after a new login and anonymous failures.
      if (err.response?.statusCode == 401) {
        final token = await _storage.read(key: 'auth_token');
        if (token != null &&
            token.isNotEmpty &&
            err.requestOptions.headers['Authorization'] == 'Bearer $token') {
          await _storage.delete(key: 'auth_token');
          onSessionExpired?.call();
        }
      }
    } catch (_) {
      // Storage errors must not leave the request's error handler unresolved.
    }
    return handler.next(err);
  }
}
