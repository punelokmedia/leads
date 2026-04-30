import 'package:hooks_riverpod/legacy.dart';
import '../domain/profile_model.dart';
import 'profile_repository.dart';

// ---------- State ----------
class ProfileState {
  final ProfileModel? profile;
  final bool isLoading;
  final bool isLoggingOut;
  final String? errorMessage;

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.isLoggingOut = false,
    this.errorMessage,
  });

  ProfileState copyWith({
    ProfileModel? profile,
    bool? isLoading,
    bool? isLoggingOut,
    String? errorMessage,
  }) => ProfileState(
    profile: profile ?? this.profile,
    isLoading: isLoading ?? this.isLoading,
    isLoggingOut: isLoggingOut ?? this.isLoggingOut,
    errorMessage: errorMessage,
  );
}

// ---------- Controller ----------
class ProfileController extends StateNotifier<ProfileState> {
  final IProfileRepository _repository;

  ProfileController(this._repository) : super(const ProfileState());

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final profile = await _repository.fetchProfile();
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load profile.',
      );
    }
  }

  Future<void> logout(void Function() onSuccess) async {
    state = state.copyWith(isLoggingOut: true);
    try {
      await _repository.logout();
      state = state.copyWith(isLoggingOut: false);
      onSuccess();
    } catch (_) {
      state = state.copyWith(
        isLoggingOut: false,
        errorMessage: 'Logout failed. Try again.',
      );
    }
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}
