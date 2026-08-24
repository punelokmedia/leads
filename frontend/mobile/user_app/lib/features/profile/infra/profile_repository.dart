import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
// Note: hooks_riverpod/legacy.dart is usually not needed if you have flutter_riverpod
import 'package:user_app/features/auth/shared/auth_providers.dart';
import 'package:user_app/features/profile/infra/profile_controller.dart';
import '../domain/profile_model.dart';

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
    // ✅ Added the ability to explicitly pass null to profile
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

class ProfileController extends StateNotifier<ProfileState> {
  final IProfileRepository _repository;
  final Ref _ref; // ✅ 1. Define Ref as a class variable

  // ✅ 2. Require Ref in the constructor
  ProfileController(this._repository, this._ref) : super(const ProfileState()) {
    loadProfile(); 
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final profile = await _repository.fetchProfile();
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load profile.');
    }
  }

  Future<void> logout(void Function() onSuccess) async {
    state = state.copyWith(isLoggingOut: true);
    try {
      // 1. Call backend logout API
      await _repository.logout();
      
      // ✅ 3. Use _ref to read the secure storage provider
      final secureStorage = _ref.read(secureStorageProvider);
      await secureStorage.deleteAll();
      
      // ✅ 4. Clear the local profile data from state
      state = const ProfileState(); 
      
      onSuccess();
    } catch (_) {
      state = state.copyWith(isLoggingOut: false, errorMessage: 'Logout failed.');
    }
  }
}

final profileControllerProvider = StateNotifierProvider<ProfileController, ProfileState>((ref) {
  // ✅ 5. Pass the 'ref' into the controller
  return ProfileController(
    ref.watch(profileRepositoryProvider), 
    ref, 
  );
});