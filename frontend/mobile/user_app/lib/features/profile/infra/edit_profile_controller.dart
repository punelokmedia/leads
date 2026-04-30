import 'package:dio/dio.dart';
import 'package:hooks_riverpod/legacy.dart';
import '../domain/edit_profile_model.dart';
import 'edit_profile_repository.dart';

// ---------- State ----------
class EditProfileState {
  final EditProfileModel? data;
  final bool isLoading;
  final bool isUpdating;
  final bool isChangingPassword;
  final bool obscurePassword;
  final String? errorMessage;
  final String? successMessage;

  const EditProfileState({
    this.data,
    this.isLoading = false,
    this.isUpdating = false,
    this.isChangingPassword = false,
    this.obscurePassword = true,
    this.errorMessage,
    this.successMessage,
  });

  EditProfileState copyWith({
    EditProfileModel? data,
    bool? isLoading,
    bool? isUpdating,
    bool? isChangingPassword,
    bool? obscurePassword,
    String? errorMessage,
    String? successMessage,
  }) => EditProfileState(
    data: data ?? this.data,
    isLoading: isLoading ?? this.isLoading,
    isUpdating: isUpdating ?? this.isUpdating,
    isChangingPassword: isChangingPassword ?? this.isChangingPassword,
    obscurePassword: obscurePassword ?? this.obscurePassword,
    errorMessage: errorMessage,
    successMessage: successMessage,
  );
}

// ---------- Controller ----------
class EditProfileController extends StateNotifier<EditProfileState> {
  final IEditProfileRepository _repository;

  EditProfileController(this._repository) : super(const EditProfileState());

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final data = await _repository.fetchEditProfile();
      state = state.copyWith(data: data, isLoading: false);
    } catch (e, stack) {
      print("Load Profile Error: $e");
      print(stack);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load profile.',
      );
    }
  }

  void updateField(EditProfileModel updated) {
    state = state.copyWith(data: updated);
  }

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  Future<void> submitUpdate(void Function() onSuccess) async {
    if (state.data == null) return;
    state = state.copyWith(
      isUpdating: true,
      errorMessage: null,
      successMessage: null,
    );
    try {
      await _repository.updateProfile(state.data!);
      state = state.copyWith(
        isUpdating: false,
        successMessage: 'Profile updated successfully!',
      );
      onSuccess();
    } catch (_) {
      state = state.copyWith(
        isUpdating: false,
        errorMessage: 'Update failed. Try again.',
      );
    }
  }

  Future<void> changePassword({
    required String current,
    required String newPass,
    required void Function() onSuccess,
  }) async {
    state = state.copyWith(isChangingPassword: true, errorMessage: null);
    try {
      await _repository.changePassword(
        currentPassword: current,
        newPassword: newPass,
      );
      state = state.copyWith(
        isChangingPassword: false,
        successMessage: 'Password changed!',
      );
      onSuccess();
    } on DioException catch (e) {
      final responseData = e.response?.data;
      String msg = 'Password change failed';

      if (responseData is Map && responseData.containsKey('message')) {
        msg = responseData['message'];
      }

      state = state.copyWith(isChangingPassword: false, errorMessage: msg);
    } catch (e) {
      state = state.copyWith(
        isChangingPassword: false,
        errorMessage: 'An unexpected error occurred',
      );
    }
  }

  void clearMessages() =>
      state = state.copyWith(errorMessage: null, successMessage: null);
}
