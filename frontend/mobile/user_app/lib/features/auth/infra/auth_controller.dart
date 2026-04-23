// auth/infra/auth_controller.dart

import 'package:dio/dio.dart';
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

  // ── Register ──────────────────────────────────────────────────────────────
  Future<void> register({
    required String firstname,
    required String lastname,
    required String email,
    required String phoneNumber,
    required String password,
    required void Function(String message) onSuccess,
  }) async {
    // _setLoading();
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.register(
        firstname: firstname,
        lastname: lastname,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
      );
      if (result.token != null) {
        await _ref.read(isLoggedInProvider.notifier).setLoggedIn(result.token!);
      }
      state = state.copyWith(
        isLoading: false,
        user: result.user,
        token: result.token,
      );

      onSuccess("Account created successfully");
    } catch (e) {
      // Use centralized ErrorHandler
      final appException = ErrorHandler.handle(e);
      state = state.copyWith(isLoading: false, error: appException.message);
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<void> login({
    required String email,
    required String password,
    required void Function() onSuccess,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.login(email: email, password: password);

      // 1. Save Login Status and WAIT for it
      await _ref.read(isLoggedInProvider.notifier).setLoggedIn(result.token);

      state = state.copyWith(
        isLoading: false,
        user: result.user,
        token: result.token,
      );

      // 2. Trigger Navigation
      onSuccess();

      // 3. Sync Cart 
      Future.delayed(const Duration(milliseconds: 500), () async {
        try {
          await _ref.read(cartRepositoryProvider).syncLocalToRemote();
          _ref.invalidate(cartControllerProvider);
        } catch (e) {
          print("Silent Cart Sync Error: $e");
        }
      });
    } catch (e) {
      final appException = ErrorHandler.handle(e);
      state = state.copyWith(isLoading: false, error: appException.message);
    }
  }

  // ── Google Auth ───────────────────────────────────────────────────────────
  Future<void> googleAuth({required void Function() onSuccess}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.googleAuth();

      state = state.copyWith(
        isLoading: false,
        user: result.user,
        token: result.token,
      );

      // ↓ Sync local cart → backend, then reload cart from backend
      await _ref.read(cartRepositoryProvider).syncLocalToRemote();
      _ref.invalidate(cartControllerProvider);

      onSuccess();
    } catch (e) {
      // Handle the case where the user simply closed the Google popup
      if (e.toString().contains('canceled')) {
        state = state.copyWith(isLoading: false);
        return;
      }

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
