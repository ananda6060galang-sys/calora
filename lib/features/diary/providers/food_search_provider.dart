import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/services/food_search_service.dart';
import '../../../models/food.dart';
import '../../../models/indonesian_foods_data.dart';
import '../../../models/mock_data.dart';

/// Active [FoodSearchService] implementation.
/// Default: [FatSecretFoodSearchService] which has instant, seamless fallback
/// to [indonesianFoods] curated dataset if network/FatSecret is unreachable.
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
    this.selectedCategory = 'Semua',
    this.errorMessage,
    this.isFallback = false,
  });

  final FoodSearchStatus status;
  final List<Food> foods;
  final String query;
  final String selectedCategory;
  final String? errorMessage;
  final bool isFallback;

  FoodSearchState copyWith({
    FoodSearchStatus? status,
    List<Food>? foods,
    String? query,
    String? selectedCategory,
    String? errorMessage,
    bool? isFallback,
  }) {
    return FoodSearchState(
      status: status ?? this.status,
      foods: foods ?? this.foods,
      query: query ?? this.query,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      errorMessage: errorMessage,
      isFallback: isFallback ?? this.isFallback,
    );
  }
}

/// StateNotifier managing food search queries, categories, debounce, and network requests.
class FoodSearchNotifier extends StateNotifier<FoodSearchState> {
  FoodSearchNotifier(this._service) : super(const FoodSearchState()) {
    // Initially populate with Indonesian foods database in idle state for instant offline UX
    final initialList = [...indonesianFoods, ...demoFoods];
    state = FoodSearchState(
      status: FoodSearchStatus.idle,
      foods: initialList,
      query: '',
      selectedCategory: 'Semua',
    );
  }

  final FoodSearchService _service;
  Timer? _debounceTimer;
  int _searchCounter = 0;

  void onCategoryChanged(String category) {
    state = state.copyWith(selectedCategory: category);
    _executeSearch(state.query, category: category);
  }

  void onQueryChanged(String query) {
    _debounceTimer?.cancel();

    final clean = query.trim();
    if (clean.isEmpty) {
      _executeSearch('', category: state.selectedCategory);
      return;
    }

    // Debounce 250ms for snappy responsiveness
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      _executeSearch(clean, category: state.selectedCategory);
    });
  }

  Future<void> _executeSearch(String query, {String? category}) async {
    final searchId = ++_searchCounter;
    final activeCategory = category ?? state.selectedCategory;

    state = state.copyWith(
      status: FoodSearchStatus.loading,
      query: query,
      errorMessage: null,
    );

    try {
      final results = await _service.searchFoods(
        query,
        category: activeCategory == 'Semua' ? null : activeCategory,
      );

      // Verify freshness of search
      if (searchId != _searchCounter) return;

      if (results.isEmpty) {
        state = state.copyWith(
          status: FoodSearchStatus.empty,
          foods: [],
          isFallback: false,
        );
      } else {
        state = state.copyWith(
          status: query.isEmpty && activeCategory == 'Semua'
              ? FoodSearchStatus.idle
              : FoodSearchStatus.results,
          foods: results,
          isFallback: false,
        );
      }
    } catch (_) {
      if (searchId != _searchCounter) return;

      // Fallback directly to local Indonesian foods database
      final queryLower = query.toLowerCase();
      final tokens =
          queryLower.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

      var baseList = [...indonesianFoods, ...demoFoods];
      if (activeCategory != 'Semua') {
        baseList = baseList
            .where((f) => f.category.toLowerCase() == activeCategory.toLowerCase())
            .toList();
      }

      final fallbackResults = queryLower.isEmpty
          ? baseList
          : baseList.where((f) {
              final nameLower = f.name.toLowerCase();
              if (nameLower.contains(queryLower)) return true;
              if (tokens.isNotEmpty && tokens.every((t) => nameLower.contains(t))) return true;
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
          status: FoodSearchStatus.empty,
          foods: [],
          isFallback: true,
          errorMessage: null,
        );
      }
    }
  }

  void retry() {
    _executeSearch(state.query, category: state.selectedCategory);
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
