import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
import '../domain/history_model.dart';
import 'history_repository.dart';

// ---------- State ----------
class HistoryState {
  final List<HistoryModel> items;
  final bool isLoading;
  final String? errorMessage;

  const HistoryState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isEmpty => !isLoading && errorMessage == null && items.isEmpty;

  HistoryState copyWith({
    List<HistoryModel>? items,
    bool? isLoading,
    String? errorMessage,
  }) =>
      HistoryState(
        items: items ?? this.items,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );
}

// ---------- Controller ----------
class HistoryController extends StateNotifier<HistoryState> {
  final IHistoryRepository _repository;

  HistoryController(this._repository) : super(const HistoryState());

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await _repository.fetchHistory();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load history. Please try again.',
      );
    }
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}