// auth/infra/auth_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // ✅ Import secure storage
import 'package:user_app/core/network/api_endpoints.dart';
import '../domain/auth_model.dart';

class AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage; // ✅ Add storage instance

  // ✅ Require storage in the constructor
  AuthRepository(this._dio, this._storage);

  // ── POST /auth/mobile/complete-profile ────────────────────────────────────
  Future<AuthUser> completeProfile({
    required String fullName,
    required String email,
    required String city,
    required List<String> categories, 
    required String businessName,
    required String workType,
  }) async {
    final res = await _dio.post(
      ApiEndpoints.completeProfile,
      data: {
        'fullName': fullName,
        'email': email,
        'city': city,
        'categories': categories, 
        'businessName': businessName,
        'workType': workType,
      },
    );

    final body = res.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;

    return AuthUser.fromJson(data);
  }

  // ── POST /auth/mobile/request-otp-session ─────────────────────────────────
  Future<Map<String, dynamic>> sendOtp({required String phoneNumber}) async {
    final res = await _dio.post(
      ApiEndpoints.requestOtp, 
      data: {
        'phoneNumber': phoneNumber, 
      },
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
      options: Options(
        headers: {
          'Authorization': 'Bearer $token', 
        },
      ),
    );

    return res.data as Map<String, dynamic>;
  }

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

    // 1. Token is at the root level
    final String token = body['token'] as String;

    // ✅ SAVE TOKEN IMMEDIATELY TO STORAGE
    await _storage.write(key: 'auth_token', value: token);

    // 2. The user object is the 'data' object itself
    final Map<String, dynamic>? data = body['data'] as Map<String, dynamic>?;

    AuthUser? user;
    bool needsProfile = true; 

    if (data != null) {
      user = AuthUser.fromJson(data);
      needsProfile = !(data['isProfileCompleted'] as bool? ?? false);
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
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      throw Exception('Google Sign-In canceled');
    }

    // 2. Extract the secure ID Token from Google
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final String? idToken = googleAuth.idToken;

    if (idToken == null) {
      throw Exception('Failed to retrieve Google ID Token.');
    }

    // 3. Send the token to YOUR backend
    final res = await _dio.post(
      ApiEndpoints.googleAuth,
      data: {'idToken': idToken},
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