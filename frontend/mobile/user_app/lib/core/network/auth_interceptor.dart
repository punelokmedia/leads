import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;

  AuthInterceptor(this._storage);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 1. Get the token from storage
    final token = await _storage.read(key: 'auth_token');

    // 2. If token exists, inject it into the headers
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // 3. Continue with the request
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle 401 Unauthorized globally if needed
    if (err.response?.statusCode == 401) {
      // Logic to logout user or clear storage could go here
    }
    return handler.next(err);
  }
}