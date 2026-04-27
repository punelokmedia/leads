import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
import 'package:user_app/core/network/dio_provider.dart';
import 'package:user_app/features/cart/shared/cart_providers.dart';
import 'package:user_app/features/home/domain/leads_model.dart';
import '../infra/home_repository.dart';
import '../infra/home_controller.dart';


// Repository provider
final homeRepositoryProvider = Provider<IHomeRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return HomeRepository(dio);
});

// Controller / StateNotifier provider
final homeControllerProvider =
    StateNotifierProvider<HomeController, HomeState>((ref) {
  final repository = ref.watch(homeRepositoryProvider);
  return HomeController(repository);
});

// Convenience derived providers
final leadsProvider = Provider<List<LeadModel>>((ref) {
  return ref.watch(homeControllerProvider).leads;
});

final cartCountProvider = Provider<int>(
  (ref) => ref.watch(cartItemsProvider).length,
);

// final cartCountProvider = Provider<int>((ref) {
//   final cartState = ref.watch(cartControllerProvider);
//   return cartState.items.length;
// });

// Selector to see if a specific lead is in cart (for the Home Screen icon color)
final isInCartProvider = Provider.family<bool, String>((ref, leadId) {
  final items = ref.watch(cartItemsProvider);
  return items.any((item) => item.id == leadId);
});

final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(homeControllerProvider).isLoading;
});

final errorMessageProvider = Provider<String?>((ref) {
  return ref.watch(homeControllerProvider).errorMessage;
});