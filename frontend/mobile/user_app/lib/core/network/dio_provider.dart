import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'background_transformer.dart';
import 'auth_interceptor.dart'; // ← Import your new interceptor

// Define a storage provider
final storageProvider = Provider((ref) => const FlutterSecureStorage());

final dioProvider = Provider<Dio>((ref) {
  final baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:5000/';
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
  dio.interceptors.add(AuthInterceptor(storage));

  // 2. Add Background Transformer
  dio.transformer = AppBackgroundTransformer();
  
  // 3. Optional: Add Logging (Very helpful for debugging headers)
  dio.interceptors.add(LogInterceptor(
    requestHeader: true, 
    requestBody: true, 
    responseBody: true
  ));

  return dio; 
});