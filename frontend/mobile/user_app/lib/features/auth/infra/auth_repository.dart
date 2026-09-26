import 'package:flutter_dotenv/flutter_dotenv.dart';
// auth/infra/auth_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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
    String? profilePicPath,
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

    // Optional: How to attach the image file if you add it later
    if (profilePicPath != null && profilePicPath.isNotEmpty) {
      formData.files.add(
        MapEntry('profilePic', await MultipartFile.fromFile(profilePicPath)),
      );
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
    final bool needsProfile = isNewUser;

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
    final serverClientId = dotenv.env['USER_GOOGLE_WEB_CLIENT_ID']?.trim();
    if (serverClientId == null || serverClientId.isEmpty) {
      throw Exception(
        'Google sign-in is not configured: USER_GOOGLE_WEB_CLIENT_ID is missing.',
      );
    }
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      serverClientId: serverClientId,
    );
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      throw Exception('Google Sign-In canceled');
    }

    // 2. Extract the secure ID Token from Google
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final String? idToken = googleAuth.idToken;

    if (idToken == null) {
      throw Exception('Failed to retrieve Google ID Token.');
    }

    // 3. Send the token to YOUR backend
    final res = await _dio.post(
      ApiEndpoints.googleAuth,
      data: {'idToken': idToken},
      // A sleeping development backend can take about a minute to respond.
      options: Options(receiveTimeout: const Duration(seconds: 90)),
    );

    final body = res.data as Map<String, dynamic>;
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
