import 'package:hooks_riverpod/legacy.dart';
import 'package:user_app/features/home/domain/leads_model.dart';

import 'home_repository.dart';

// ---------- State ----------
class HomeState {
  final List<LeadModel> leads;
  final List<LeadModel> cartItems;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final String? selectedCity;
  final String? selectedCategoryId;

  const HomeState({
    this.leads = const [],
    this.cartItems = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.selectedCity,
    this.selectedCategoryId,
  });

  HomeState copyWith({
    List<LeadModel>? leads,
    List<LeadModel>? cartItems,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    String? selectedCity,
    String? selectedCategoryId,
  }) {
    return HomeState(
      leads: leads ?? this.leads,
      cartItems: cartItems ?? this.cartItems,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCity: selectedCity ?? this.selectedCity,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
    );
  }

  bool isInCart(String leadId) => cartItems.any((l) => l.id == leadId);
  int get cartCount => cartItems.length;
}

// ---------- Controller ----------
class HomeController extends StateNotifier<HomeState> {
  final IHomeRepository _repository;
  int _requestId = 0;

  HomeController(this._repository) : super(const HomeState());

  Future<void> loadLeads({
    String? city,
    String? categoryId,
    bool isReset = false,
  }) async {
    final requestId = ++_requestId;
    final cityToFetch = isReset ? null : (city ?? state.selectedCity);
    final categoryToFetch = isReset
        ? null
        : (categoryId ?? state.selectedCategoryId);

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      selectedCity: isReset ? "" : cityToFetch,
      selectedCategoryId: isReset ? "" : categoryToFetch,
    );

    try {
      final leads = await _repository.fetchLeads(
        city: cityToFetch,
        categoryId: categoryToFetch,
      );
      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(leads: leads, isLoading: false);
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Could not load leads. Please try again.',
      );
    }
  }

  Future<void> searchLeads(String query) async {
    final requestId = ++_requestId;
    state = state.copyWith(
      searchQuery: query,
      isLoading: true,
      errorMessage: null,
    );
    try {
      final leads = query.isEmpty
          ? await _repository.fetchLeads()
          : await _repository.searchLeads(query);
      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(leads: leads, isLoading: false);
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      state = state.copyWith(isLoading: false, errorMessage: 'Search failed.');
    }
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}
