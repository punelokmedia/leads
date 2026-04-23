import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
import 'package:user_app/core/network/dio_provider.dart';
import '../domain/profile_model.dart';
import '../infra/profile_repository.dart';
import '../infra/profile_controller.dart';

final profileRepositoryProvider = Provider<IProfileRepository>((ref){
  final dio=ref.read(dioProvider);
  return ProfileRepository(dio);
});

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
  return ProfileController(ref.watch(profileRepositoryProvider));
});

// Derived providers
final profileDataProvider = Provider<ProfileModel?>(
  (ref) => ref.watch(profileControllerProvider).profile,
);

final profileIsLoadingProvider = Provider<bool>(
  (ref) => ref.watch(profileControllerProvider).isLoading,
);

final profileIsLoggingOutProvider = Provider<bool>(
  (ref) => ref.watch(profileControllerProvider).isLoggingOut,
);

final profileErrorProvider = Provider<String?>(
  (ref) => ref.watch(profileControllerProvider).errorMessage,
);