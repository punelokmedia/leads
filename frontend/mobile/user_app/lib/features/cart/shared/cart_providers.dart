import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
import 'package:user_app/core/network/dio_provider.dart';
import '../../auth/shared/auth_providers.dart';
import '../domain/cart_model.dart';
import '../infra/cart_repository.dart';
import '../infra/cart_controller.dart';

final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => CartRepository(
    ref.watch(dioProvider),
    ref.watch(secureStorageProvider),
  ),
);

final cartControllerProvider =
    StateNotifierProvider<CartController, CartState>((ref) {
  final isLoggedIn = ref.watch(isLoggedInProvider);
  return CartController(ref.watch(cartRepositoryProvider), isLoggedIn);
});

final cartItemsProvider = Provider<List<CartLead>>(
  (ref) => ref.watch(cartControllerProvider).items,
);

final cartCountProvider = Provider<int>(
  (ref) => ref.watch(cartItemsProvider).length,
);

final isInCartProvider = Provider.family<bool, String>((ref, id) {
  return ref.watch(cartItemsProvider).any((item) => item.id == id);
});

final cartIsLoadingProvider = Provider<bool>(
  (ref) => ref.watch(cartControllerProvider).isLoading,
);

final cartErrorProvider = Provider<String?>(
  (ref) => ref.watch(cartControllerProvider).error,
);
final cartSelectedItemsProvider = Provider<List<CartLead>>(
  (ref) => ref.watch(cartItemsProvider).where((e) => e.isSelected).toList(),
);

final cartQuantityProvider = Provider.family<int, String>((ref, id) {
  final item = ref.watch(cartItemsProvider).where((item) => item.id == id).firstOrNull;
  return item?.quantity ?? 0;
});