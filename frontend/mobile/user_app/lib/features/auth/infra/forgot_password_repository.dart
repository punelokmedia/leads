
import 'package:dio/dio.dart';
import '../../../core/network/api_endpoints.dart';


abstract class ForgotPasswordRepository {
  Future<void> sendOtp({required String email});
  Future<void> verifyOtp({required String email, required String otp});
  Future<void> changePassword({
    required String email,
    required String confirmPassword,
    required String newPassword,
  });
}

class ForgotPasswordRepositoryImpl implements ForgotPasswordRepository {
  final Dio _dio;

  ForgotPasswordRepositoryImpl(this._dio);

  @override
  Future<void> sendOtp({required String email}) async {
    try {
      await _dio.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      await _dio.post(
        ApiEndpoints.verifyOtp,
        data: {
          'email': email,
          'otp': otp,
        },
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> changePassword({
    required String email,
    required String confirmPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        ApiEndpoints.resetPassword,
        data: {
          'email': email,
          'newPassword':newPassword,
          'confirmPassword': confirmPassword,
        },
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    final message = e.response?.data?['message'] as String? ??
        e.message ??
        'Something went wrong';
    return Exception(message);
  }
}