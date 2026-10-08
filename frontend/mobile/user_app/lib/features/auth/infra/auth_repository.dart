import 'package:flutter_dotenv/flutter_dotenv.dart';
// auth/infra/auth_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:user_app/core/errors/app_exception.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // ✅ Import secure storage
import 'package:user_app/core/network/api_endpoints.dart';
import '../domain/auth_model.dart';

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  // ✅ Require storage in the constructor
  AuthRepository(this._dio, this._storage);

  // ── PUT /auth/mobile/complete-profile ────────────────────────────────────
  Future<AuthUser> completeProfile({
    required String fullName,
    required String email,
    required String city,
    required String address,
    required List<String> categories,
    required String businessName,
    required String workType,
  }) async {
    // ✅ FIX 1: Use FormData for multipart/form-data instead of a standard Map
    final formData = FormData.fromMap({
      'fullName': fullName,
      'email': email,
      'city': city,
      'businessName': businessName,
      'workType': workType,
      'address': address,
    });

    // ✅ FIX 2: Handle the Array for multipart form data.
    // Notice in Postman the key is exactly 'categories[]'
    for (var category in categories) {
      formData.fields.add(MapEntry('categories[]', category));
    }


    // ✅ FIX 3: Backend route is POST /auth/mobile/complete-profile
    final res = await _dio.post(ApiEndpoints.completeProfile, data: formData);

    final body = res.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;

    return AuthUser.fromJson(data);
  }

  // ── POST /auth/mobile/request-otp-session ─────────────────────────────────
  Future<Map<String, dynamic>> sendOtp({required String phoneNumber}) async {
    final res = await _dio.post(
      ApiEndpoints.requestOtp,
      data: {'phoneNumber': phoneNumber},
    );

    return res.data as Map<String, dynamic>;
  }

  // ── POST /auth/login ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>> requestOtpSession({
    required String phoneNumber,
    required String token,
  }) async {
    final res = await _dio.post(
      ApiEndpoints.requestOtpSession,
      data: {'phoneNumber': phoneNumber},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    return res.data as Map<String, dynamic>;
  }

  // ── POST /auth/mobile/verify-otp (Standard Flow) ──────────────────────────
  // ── POST /auth/mobile/verify-otp (Standard Flow) ──────────────────────────
  Future<({AuthUser? user, String token, bool needsProfile})> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    final res = await _dio.post(
      ApiEndpoints.verifyOtp,
      data: {'phoneNumber': phoneNumber, 'otp': otp},
    );

    final body = res.data as Map<String, dynamic>;

    // 1. Save Token
    final String token = body['token'] as String;
    await _storage.write(key: 'auth_token', value: token);

    // 2. Extract meta object
    final Map<String, dynamic>? meta = body['meta'] as Map<String, dynamic>?;

    //  Strictly use 'isNewUser' only. Default to false if missing.
    final bool isNewUser = meta?['isNewUser'] as bool? ?? false;

    // Assign it directly to needsProfile for your UI to use
    final bool needsProfile = meta?['needsProfile'] as bool? ?? isNewUser;

    // 3. Parse User Data
    AuthUser? user;
    final Map<String, dynamic>? data = body['data'] as Map<String, dynamic>?;

    if (data != null) {
      user = AuthUser.fromJson(data);
    }

    return (user: user, token: token, needsProfile: needsProfile);
  }

  // ── POST /auth/mobile/verify-otp-session (Google Flow) ────────────────────
  Future<Map<String, dynamic>> verifyOtpSession({
    required String phoneNumber,
    required String otp,
    required String token, // The Google Bearer token
  }) async {
    final res = await _dio.post(
      ApiEndpoints.verifyOtpSession,
      data: {'phoneNumber': phoneNumber, 'otp': otp},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final body = res.data as Map<String, dynamic>;

    // ✅ SAVE TOKEN IMMEDIATELY IF PRESENT
    if (body['token'] != null) {
      await _storage.write(key: 'auth_token', value: body['token'] as String);
    }

    return body;
  }

  // ── GET /auth/google ──────────────────────────────────────────────────────
  Future<({AuthUser user, String token})> googleAuth() async {
    // 1. Trigger the native Google Sign-In UI
    final configuredClientId = dotenv.env['MOBILE_USER_GOOGLE_CLIENT_ID']?.trim();
    final serverClientId = configuredClientId != null && configuredClientId.isNotEmpty
        ? configuredClientId
        : (dotenv.env['USER_GOOGLE_WEB_CLIENT_ID'] ??
            dotenv.env['USER_GOOGLE_CLIENT_ID'])?.trim();
    if (serverClientId == null || serverClientId.isEmpty) {
      throw const AppException(
        'Google sign-in is not configured: MOBILE_USER_GOOGLE_CLIENT_ID is missing.',
      );
    }
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      serverClientId: serverClientId,
    );
    GoogleSignInAccount? googleUser;
    GoogleSignInAuthentication googleAuth;
    try {
      if (kDebugMode) debugPrint('[GoogleAuth] Opening Google account picker');
      googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw const AppException('Google Sign-In canceled');
      }
      googleAuth = await googleUser.authentication;
    } on PlatformException catch (error) {
      if (kDebugMode) {
        debugPrint('[GoogleAuth] Native sign-in failed: ${error.code}; ${error.message}');
      }
      if (error.code == 'sign_in_canceled') {
        throw const AppException('Google Sign-In canceled');
      }
      if (RegExp(r'\b10\b').hasMatch(error.message ?? '')) {
        throw const AppException(
          'Google sign-in configuration error (10). Check the Android package, release SHA-1 and Web client ID in Google Cloud.',
        );
      }
      throw AppException('Google account sign-in failed (${error.code}). Please retry and report this code.');
    }

    if (googleUser == null) {
      throw Exception('Google Sign-In canceled');
    }

    // 2. Extract the secure ID Token from Google
    final String? idToken = googleAuth.idToken;

    if (idToken == null) {
      throw const AppException('Google did not return an ID token. Check the Web client ID configuration.');
    }

    // 3. Send the token to YOUR backend
    if (kDebugMode) {
      debugPrint('[GoogleAuth] ID token received; contacting ${_dio.options.baseUrl}${ApiEndpoints.googleAuth}');
    }
    late final Response<dynamic> res;
    try {
      res = await _dio.post(
        ApiEndpoints.googleAuth,
        data: {'idToken': idToken},
        options: Options(receiveTimeout: const Duration(seconds: 90)),
      );
    } on DioException catch (error) {
      if (kDebugMode) {
        debugPrint('[GoogleAuth] Backend request failed: ${error.type.name}; HTTP ${error.response?.statusCode ?? "no response"}');
      }
      rethrow;
    }
    if (kDebugMode) debugPrint('[GoogleAuth] Backend responded: HTTP ${res.statusCode}');

    final body = res.data;
    if (body is! Map<String, dynamic> ||
        body['user'] is! Map<String, dynamic> ||
        body['token'] is! String ||
        (body['token'] as String).isEmpty) {
      throw const AppException('The server returned an unexpected Google login response. Check the deployed mobile authentication endpoint.');
    }
    final userData = body['user'] as Map<String, dynamic>;
    final token = body['token'] as String;

    // ✅ SAVE TOKEN IMMEDIATELY TO STORAGE
    await _storage.write(key: 'auth_token', value: token);

    return (user: AuthUser.fromJson(userData), token: token);
  }

  // ── LOGOUT ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    final res = await _dio.get(
      ApiEndpoints.logout,
      options: Options(responseType: ResponseType.plain),
    );

    // ✅ DELETE TOKEN FROM STORAGE ON LOGOUT
    await _storage.delete(key: 'auth_token');

    debugPrint("Logout response: ${res.data}");
  }

  // ── Create Razorpay Order ──────────────────────────────────────────────────
  Future<Map<String, dynamic>> createRegistrationOrder() async {
    final res = await _dio.post(ApiEndpoints.createRegistrationOrder);
    final body = res.data as Map<String, dynamic>;
    return body['data'];
  }

  // ── Verify Razorpay Payment ────────────────────────────────────────────────
  Future<void> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    required String fullName,
    required String email,
    required String city,
    required List<String> categories,
    required String businessName,
    required String workType,
  }) async {
    final res = await _dio.post(
      ApiEndpoints.verifyRegistrationPayment,
      data: {
        'razorpayOrderId': orderId,
        'razorpayPaymentId': paymentId,
        'razorpaySignature': signature,
        'membershipOnly': true,
        'fullName': fullName,
        'email': email,
        'city': city,
        'categories': categories,
        'businessName': businessName,
        'workType': workType,
      },
    );

    // ✅ If the backend returns a refreshed token after payment/profile completion, save it!
    final body = res.data as Map<String, dynamic>?;
    if (body != null && body['token'] != null) {
      await _storage.write(key: 'auth_token', value: body['token'] as String);
    }
  }
}
