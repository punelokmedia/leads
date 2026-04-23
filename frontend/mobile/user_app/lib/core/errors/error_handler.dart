  // lib/core/errors/error_handler.dart


  import 'package:dio/dio.dart';
import 'package:user_app/core/errors/app_exception.dart';

  class ErrorHandler {
    ErrorHandler._();

    static AppException handle(dynamic error) {
      if (error is DioException) {
        return _handleDio(error);
      }
      if (error is AppException) {
        return error;
      }
      return const AppException('Something went wrong. Please try again.');
    }

    static AppException _handleDio(DioException e) {
      // ── Network / timeout errors ─────────────────────────────────────────
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return const AppException('Connection timed out. Check your internet.');
      }

      if (e.type == DioExceptionType.connectionError) {
        return const AppException('No internet connection.');
      }

      // ── Always use backend message ───────────────────────────────────────
      final data = e.response?.data;
      final statusCode = e.response?.statusCode;

      if (data is Map<String, dynamic>) {
        final message = data['message']?.toString()
                    ?? data['error']?.toString();

        if (message != null && message.isNotEmpty) {
          return AppException(message, statusCode: statusCode);
        }
      }

      if (data is String && data.isNotEmpty) {
        return AppException(data, statusCode: statusCode);
      }

      // ── Backend sent no message at all (empty body) ──────────────────────
      return AppException(
        'Request failed. Please try again.',
        statusCode: statusCode,
      );
    }
  }