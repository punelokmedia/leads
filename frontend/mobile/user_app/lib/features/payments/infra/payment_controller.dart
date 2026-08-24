import 'package:hooks_riverpod/legacy.dart';
import '../domain/payment_model.dart';
import 'payment_repository.dart';

class HistoryState {
  final bool isLoading;
  final List<HistoryModel> items;
  final String? error;
  final int selectedTabIndex;

  HistoryState({
    this.isLoading = false,
    this.items = const [],
    this.error,
    this.selectedTabIndex = 0,
  });

  HistoryState copyWith({bool? isLoading, List<HistoryModel>? items, String? error, int? selectedTabIndex}) {
    return HistoryState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      error: error,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
    );
  }
}

class HistoryController extends StateNotifier<HistoryState> {
  final HistoryRepository _repo;

  HistoryController(this._repo) : super(HistoryState()) {
    fetchHistory(0); // Fetch 'ALL' initially
  }

  Future<void> fetchHistory(int tabIndex) async {
    state = state.copyWith(isLoading: true, selectedTabIndex: tabIndex, error: null);
    
    // Map tab index to API parameter
    String typeParam = 'ALL';
    if (tabIndex == 1) typeParam = 'PAYMENT';
    if (tabIndex == 2) typeParam = 'LEADS';

    try {
      final items = await _repo.fetchHistory(typeParam);
      state = state.copyWith(isLoading: false, items: items);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load history');
    }
  }
}

final historyControllerProvider = StateNotifierProvider<HistoryController, HistoryState>((ref) {
  return HistoryController(ref.watch(historyRepositoryProvider));
});