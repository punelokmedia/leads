import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
import 'package:user_app/features/auth/domain/forgot_state.dart';
import 'package:user_app/features/auth/infra/forgot_password_repository.dart';




// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

class ForgotPasswordController
    extends StateNotifier<ForgotPasswordState> {
  final ForgotPasswordRepository _repository;

  ForgotPasswordController(this._repository)
      : super(const ForgotPasswordState());

  // Step 1 – Send OTP to email
  Future<void> sendOtp(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.sendOtp(email: email);
      state = state.copyWith(
        isLoading: false,
        email: email,
        step: ForgotPasswordStep.otp,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // Step 2 – Verify OTP
  Future<void> verifyOtp(String otp) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.verifyOtp(email: state.email, otp: otp);
      state = state.copyWith(
        isLoading: false,
        otp: otp,
        step: ForgotPasswordStep.newPassword,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  // Step 3 – Change password
  Future<void> changePassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (newPassword != confirmPassword) {
      state = state.copyWith(errorMessage: 'Passwords do not match');
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.changePassword(
        email: state.email,
        newPassword: newPassword,
        confirmPassword:confirmPassword

      );
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}