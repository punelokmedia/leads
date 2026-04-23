// auth/infra/auth_repository.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:user_app/core/network/api_endpoints.dart';
import '../domain/auth_model.dart';

class AuthRepository {
  final Dio _dio;
  AuthRepository(this._dio);

  // ── POST /auth/register ───────────────────────────────────────────────────
  Future<({AuthUser user, String? token})> register({
    required String firstname,
    required String lastname,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    final res = await _dio.post(
      ApiEndpoints.register,
      data: {
        'firstname': firstname,
        'lastname': lastname,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
      },
    );
    final body = res.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    return (user: AuthUser.fromJson(data), token: body['token'] as String?);
  }

  // ── POST /auth/login ──────────────────────────────────────────────────────
  Future<({AuthUser user, String token})> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    final body = res.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    return (user: AuthUser.fromJson(data), token: body['token'] as String);
  }

  // ── GET /auth/google ──────────────────────────────────────────────────────
  Future<({AuthUser user, String token})> googleAuth() async {
  // 1. Trigger the native Google Sign-In UI
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

  // If the user closes the modal without selecting an account
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
  // Note: You must update your ApiEndpoints to point to a POST route (e.g., /api/v1/auth/google/verify)
  final res = await _dio.post(
    ApiEndpoints.googleAuth, 
    data: {
      'idToken': idToken,
    },
  );

  // 4. Parse the backend response exactly as you did before
  final body = res.data as Map<String, dynamic>;
  final userData = body['user'] as Map<String, dynamic>;
  
  return (
    user: AuthUser.fromJson(userData), 
    token: body['token'] as String
  );
}

  Future<void> logout() async {
    final res = await _dio.get(
      ApiEndpoints.logout,
      options: Options(
        responseType: ResponseType.plain, 
      ),
    );

    debugPrint("Logout response: ${res.data}");
  }
}
