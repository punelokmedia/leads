import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../domain/profile_model.dart';
import '../infra/profile_repository.dart';
export '../infra/profile_repository.dart' show profileControllerProvider;
export '../infra/profile_controller.dart' show profileRepositoryProvider;

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
