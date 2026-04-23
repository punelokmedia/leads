import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/legacy.dart';
import 'package:user_app/core/network/dio_provider.dart';
import '../domain/auth_model.dart';
import '../infra/auth_repository.dart';
import '../infra/auth_controller.dart';

// 1. Storage & Persistence Logic
final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());

class AuthStateNotifier extends StateNotifier<bool> {
  final FlutterSecureStorage _storage;

  AuthStateNotifier(this._storage) : super(false) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final token = await _storage.read(key: 'auth_token');
    state = token != null;
  }

  // Updates the state and writes to storage
  Future<void> setLoggedIn(String token) async {
    await _storage.write(key: 'auth_token', value: token);
    state = true;
  }

  // Updates the state and deletes from storage
  Future<void> setLoggedOut() async {
    await _storage.delete(key: 'auth_token');
    state = false;
  }
}

final isLoggedInProvider = StateNotifierProvider<AuthStateNotifier, bool>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return AuthStateNotifier(storage);
});

// 2. API & Controller Logic
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider)),
);

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref.watch(authRepositoryProvider), ref),
);

// 3. Convenience Selectors
final authIsLoadingProvider = Provider<bool>(
  (ref) => ref.watch(authControllerProvider).isLoading,
);

final authErrorProvider = Provider<String?>(
  (ref) => ref.watch(authControllerProvider).error,
);

final authUserProvider = Provider<AuthUser?>(
  (ref) => ref.watch(authControllerProvider).user,
);