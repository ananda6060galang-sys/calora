import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/services/food_search_service.dart';
import '../../../models/food.dart';
import '../../../models/mock_data.dart';

/// Provides the active [FoodSearchService] implementation.
/// Default: [FatSecretFoodSearchService] with graceful mock fallback.
final foodSearchServiceProvider = Provider<FoodSearchService>((ref) {
  return FatSecretFoodSearchService();
});

/// Food search state enum
enum FoodSearchStatus { idle, loading, results, empty, error }

/// Immutable state for food search results and UI status
class FoodSearchState {
  const FoodSearchState({
    this.status = FoodSearchStatus.idle,
    this.foods = const [],
    this.query = '',
    this.errorMessage,
    this.isFallback = false,
  });

  final FoodSearchStatus status;
  final List<Food> foods;
  final String query;
  final String? errorMessage;
  final bool isFallback;

  FoodSearchState copyWith({
    FoodSearchStatus? status,
    List<Food>? foods,
    String? query,
    String? errorMessage,
    bool? isFallback,
  }) {
    return FoodSearchState(
      status: status ?? this.status,
      foods: foods ?? this.foods,
      query: query ?? this.query,
      errorMessage: errorMessage,
      isFallback: isFallback ?? this.isFallback,
    );
  }
}

/// StateNotifier managing food search queries, debounce, and network requests.
class FoodSearchNotifier extends StateNotifier<FoodSearchState> {
  FoodSearchNotifier(this._service) : super(const FoodSearchState()) {
    // Initially populate with default foods in idle state for clean UX
    state = FoodSearchState(
      status: FoodSearchStatus.idle,
      foods: demoFoods,
      query: '',
    );
  }

  final FoodSearchService _service;
  Timer? _debounceTimer;
  int _searchCounter = 0;

  void onQueryChanged(String query) {
    _debounceTimer?.cancel();

    final clean = query.trim();
    if (clean.isEmpty) {
      state = FoodSearchState(
        status: FoodSearchStatus.idle,
        foods: demoFoods,
        query: '',
      );
      return;
    }

    // Debounce between 350ms
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _executeSearch(clean);
    });
  }

  Future<void> _executeSearch(String query) async {
    final searchId = ++_searchCounter;

    state = state.copyWith(
      status: FoodSearchStatus.loading,
      query: query,
      errorMessage: null,
    );

    try {
      final results = await _service.searchFoods(query);

      // Verify that this is still the freshest search
      if (searchId != _searchCounter) return;

      if (results.isEmpty) {
        state = state.copyWith(
          status: FoodSearchStatus.empty,
          foods: [],
          isFallback: false,
        );
      } else {
        state = state.copyWith(
          status: FoodSearchStatus.results,
          foods: results,
          isFallback: false,
        );
      }
    } catch (e) {
      if (searchId != _searchCounter) return;

      // Graceful fallback to local mock foods matching query (token + substring matching)
      final queryLower = query.toLowerCase();
      final tokens = queryLower.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

      final fallbackResults = demoFoods.where((f) {
        final nameLower = f.name.toLowerCase();
        if (nameLower.contains(queryLower)) return true;
        if (tokens.isNotEmpty && tokens.any((t) => nameLower.contains(t))) return true;
        return false;
      }).toList();

      if (fallbackResults.isNotEmpty) {
        state = state.copyWith(
          status: FoodSearchStatus.results,
          foods: fallbackResults,
          isFallback: true,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          status: FoodSearchStatus.error,
          foods: [],
          isFallback: false,
          errorMessage: 'diary.searchUnavailableNotice',
        );
      }
    }
  }

  void retry() {
    if (state.query.isNotEmpty) {
      _executeSearch(state.query);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final foodSearchProvider =
    StateNotifierProvider<FoodSearchNotifier, FoodSearchState>((ref) {
  final service = ref.watch(foodSearchServiceProvider);
  return FoodSearchNotifier(service);
});
