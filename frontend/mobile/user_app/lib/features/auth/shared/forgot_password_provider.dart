import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
import 'package:user_app/core/network/dio_provider.dart';
import 'package:user_app/features/auth/domain/forgot_state.dart';
import 'package:user_app/features/auth/infra/forgot_password_controller.dart';
import 'package:user_app/features/auth/infra/forgot_password_repository.dart';

final forgotPasswordRepositoryProvider =
    Provider<ForgotPasswordRepository>((ref) {
  return ForgotPasswordRepositoryImpl(ref.read(dioProvider));
});
 
final forgotPasswordControllerProvider =
    StateNotifierProvider.autoDispose<ForgotPasswordController, ForgotPasswordState>(
  (ref) => ForgotPasswordController(ref.read(forgotPasswordRepositoryProvider)),
);