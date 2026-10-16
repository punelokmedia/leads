import 'dart:developer';
import 'package:dio/dio.dart';
import 'api_config.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'background_transformer.dart';
import 'session_events.dart';
import 'auth_interceptor.dart'; // ← Import your new interceptor

// Define a storage provider
final storageProvider = Provider((ref) => const FlutterSecureStorage());

final dioProvider = Provider<Dio>((ref) {
  final baseUrl = ApiConfig.baseUrl;
  final storage = ref.watch(storageProvider);

  log("🚀 DIO INITIALIZED WITH BASE_URL: $baseUrl");

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15), // Increased for stability
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  // --- Add Interceptors & Transformers ---

  // 1. Add your Auth Interceptor
  dio.interceptors.add(
    AuthInterceptor(
      storage,
      onSessionExpired: () {
        ref.read(sessionExpiredProvider.notifier).state++;
      },
    ),
  );

  // 2. Add Background Transformer
  dio.transformer = AppBackgroundTransformer();

  // 3. Optional: Add Logging (Very helpful for debugging headers)
  dio.interceptors.add(
    LogInterceptor(
      requestHeader: false,
      requestBody: false,
      responseBody: false,
    ),
  );

  return dio;
});
