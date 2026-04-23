import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
import 'package:user_app/core/network/dio_provider.dart';
import '../domain/edit_profile_model.dart';
import '../infra/edit_profile_repository.dart';
import '../infra/edit_profile_controller.dart';



final editProfileRepositoryProvider = Provider<IEditProfileRepository>((ref) {
  final dio = ref.read(dioProvider);
  return EditProfileRepository(dio);
});

final editProfileControllerProvider =
    StateNotifierProvider<EditProfileController, EditProfileState>((ref) {
      return EditProfileController(ref.watch(editProfileRepositoryProvider));
    });

// Derived providers
final editProfileDataProvider = Provider<EditProfileModel?>(
  (ref) => ref.watch(editProfileControllerProvider).data,
);

final editProfileIsLoadingProvider = Provider<bool>(
  (ref) => ref.watch(editProfileControllerProvider).isLoading,
);

final editProfileIsUpdatingProvider = Provider<bool>(
  (ref) => ref.watch(editProfileControllerProvider).isUpdating,
);

final editProfileObscurePasswordProvider = Provider<bool>(
  (ref) => ref.watch(editProfileControllerProvider).obscurePassword,
);

final editProfileErrorProvider = Provider<String?>(
  (ref) => ref.watch(editProfileControllerProvider).errorMessage,
);

final editProfileSuccessProvider = Provider<String?>(
  (ref) => ref.watch(editProfileControllerProvider).successMessage,
);
