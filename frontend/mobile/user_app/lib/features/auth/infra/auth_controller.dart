// auth/infra/auth_controller.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
import 'package:user_app/core/errors/error_handler.dart'; // Import your error handler
import 'package:user_app/features/auth/shared/auth_providers.dart';
import 'package:user_app/features/cart/shared/cart_providers.dart';
import '../domain/auth_model.dart';
import 'auth_repository.dart';

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final Ref _ref;
  AuthController(this._repo, this._ref) : super(const AuthState());

  // ── Complete Profile ──────────────────────────────────────────────────────
  Future<void> completeProfile({
    required String fullName,
    required String email,
    required String city,
    required List<String> categories,
    required String businessName,
    required String workType,
    required void Function() onSuccess,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final updatedUser = await _repo.completeProfile(
        fullName: fullName,
        email: email,
        city: city,
        categories: categories,
        businessName: businessName,
        workType: workType,
      );

      // Update the state with the newly completed user profile
      state = state.copyWith(isLoading: false, user: updatedUser);

      onSuccess();
    } catch (e) {
      final appException = ErrorHandler.handle(e);
      state = state.copyWith(isLoading: false, error: appException.message);
    }
  }

  // ── Send OTP ──────────────────────────────────────────────────────────────
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String otpCode) onSuccess,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repo.sendOtp(phoneNumber: phoneNumber);

      state = state.copyWith(isLoading: false);

      // Since your API returns the OTP in the response (useful for testing),
      // we can extract it and pass it to the success callback.
      final data = response['data'] as Map<String, dynamic>;
      final String otpCode = data['otp'].toString();

      onSuccess(otpCode);
    } catch (e) {
      final appException = ErrorHandler.handle(e);
      state = state.copyWith(isLoading: false, error: appException.message);
    }
  }

  // ── Request OTP Session (For Google Auth Flow) ────────────────────────────
  Future<void> requestOtpSession({
    required String phoneNumber,
    required String token,
    required void Function(String otpCode) onSuccess,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repo.requestOtpSession(
        phoneNumber: phoneNumber,
        token: token,
      );

      state = state.copyWith(isLoading: false);

      final data = response['data'] as Map<String, dynamic>;
      final String otpCode = data['otp'].toString();

      onSuccess(otpCode);
    } catch (e) {
      final appException = ErrorHandler.handle(e);
      state = state.copyWith(isLoading: false, error: appException.message);
    }
  }

  // ── Verify OTP (Standard Phone Flow) ──────────────────────────────────────
  Future<void> verifyOtp({
    required String phoneNumber,
    required String otp,
    // We only really need to know if they need to complete their profile
    required void Function(bool needsProfile) onSuccess, 
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _repo.verifyOtp(
        phoneNumber: phoneNumber,
        otp: otp,
      );

      // Save token and user to state
      state = state.copyWith(
        isLoading: false,
        token: result.token,
        user: result.user,
      );

      // Trigger UI navigation
      onSuccess(result.needsProfile);

    } catch (e) {
      print("VERIFY OTP ERROR: $e"); 
      final appException = ErrorHandler.handle(e);
      state = state.copyWith(isLoading: false, error: appException.message);
    }
  }

  // ── Verify OTP Session (Google Auth Flow) ─────────────────────────────────
  Future<void> verifyOtpSession({
    required String phoneNumber,
    required String otp,
    required String token,
    required void Function() onSuccess,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.verifyOtpSession(
        phoneNumber: phoneNumber,
        otp: otp,
        token: token,
      );

      state = state.copyWith(isLoading: false);

      // Successfully linked phone number to Google account
      onSuccess();
    } catch (e) {
      final appException = ErrorHandler.handle(e);
      state = state.copyWith(isLoading: false, error: appException.message);
    }
  }

  // ── Google Auth ──
  Future<void> googleAuth({
    required void Function(String token)
    onSuccess, // ✅ Add token parameter here
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.googleAuth();

      state = state.copyWith(
        isLoading: false,
        user: result.user,
        token: result.token,
      );

      await _ref.read(cartRepositoryProvider).syncLocalToRemote();
      _ref.invalidate(cartControllerProvider);

      onSuccess(result.token); // ✅ Pass the token back to the UI
    } catch (e) {
      if (e.toString().contains('canceled')) {
        state = state.copyWith(isLoading: false);
        return;
      }
      final appException = ErrorHandler.handle(e);
      state = state.copyWith(isLoading: false, error: appException.message);
    }
  }

  // ── Create Payment Order ─────────────────────────────────────────────────
  Future<Map<String, dynamic>?> createPaymentOrder() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final orderData = await _repo.createRegistrationOrder();
      state = state.copyWith(isLoading: false);
      return orderData;
    } catch (e) {
      final appException = ErrorHandler.handle(e);
      state = state.copyWith(isLoading: false, error: appException.message);
      return null;
    }
  }

  // ── Verify Payment ───────────────────────────────────────────────────────
  Future<void> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    // ✅ Add Profile Fields
    required String fullName,
    required String email,
    required String city,
    required List<String> categories,
    required String businessName,
    required String workType,
    required void Function() onSuccess,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.verifyPayment(
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
        // ✅ Pass to Repo
        fullName: fullName,
        email: email,
        city: city,
        categories: categories,
        businessName: businessName,
        workType: workType,
      );
      state = state.copyWith(isLoading: false);
      onSuccess();
    } catch (e) {
      final appException = ErrorHandler.handle(e);
      state = state.copyWith(isLoading: false, error: appException.message);
    }
  }

  Future<void> logout() async {
    try {
      await _repo.logout();
    } catch (_) {}

    await _ref.read(isLoggedInProvider.notifier).setLoggedOut();
    state = const AuthState();
  }

  void clearError() => state = state.copyWith(clearError: true);
}
