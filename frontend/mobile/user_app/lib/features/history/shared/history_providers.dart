import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
import '../../../../core/network/dio_provider.dart'; 
import '../domain/history_model.dart';
import '../infra/history_repository.dart';
import '../infra/history_controller.dart';

// 1. Fixed Repository Provider: Now injects the Dio instance
final historyRepositoryProvider = Provider<IHistoryRepository>((ref) {
  final dio = ref.watch(dioProvider); 
  return HistoryRepository(dio);
});

// 2. Controller Provider
final historyControllerProvider =
    StateNotifierProvider<HistoryController, HistoryState>((ref) {
  final repository = ref.watch(historyRepositoryProvider);
  return HistoryController(repository);
});

// ── Derived convenience providers (No changes needed here) ───────────────────

final historyItemsProvider = Provider<List<HistoryModel>>(
  (ref) => ref.watch(historyControllerProvider).items,
);

final historyIsLoadingProvider = Provider<bool>(
  (ref) => ref.watch(historyControllerProvider).isLoading,
);

final historyErrorProvider = Provider<String?>(
  (ref) => ref.watch(historyControllerProvider).errorMessage,
);

final historyIsEmptyProvider = Provider<bool>(
  (ref) => ref.watch(historyControllerProvider).isEmpty,
);