import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/food.dart';
import '../../models/indonesian_foods_data.dart';
import '../../models/mock_data.dart';
import '../config/supabase_config.dart';

/// Abstraction for food searching and food details lookup.
abstract class FoodSearchService {
  Future<List<Food>> searchFoods(
    String query, {
    int page = 0,
    int maxResults = 50,
    String? category,
  });
  Future<Food?> getFoodDetails(String foodId);
}

/// Real food search service powered by FatSecret through Supabase Edge Function,
/// with instant seamless fallback to curated Indonesian foods database.
class FatSecretFoodSearchService implements FoodSearchService {
  FatSecretFoodSearchService({SupabaseClient? client, http.Client? httpClient})
      : _client = client ?? Supabase.instance.client,
        _httpClient = httpClient ?? http.Client();

  final SupabaseClient _client;
  final http.Client _httpClient;
  final MockFoodSearchService _localFallback = MockFoodSearchService();

  Uri get _edgeFunctionUri =>
      Uri.parse('${SupabaseConfig.url}/functions/v1/fatsecret-food');

  Map<String, String> _buildHeaders() {
    final session = _client.auth.currentSession;
    final token = session?.accessToken ?? SupabaseConfig.publishableKey;
    return {
      'Content-Type': 'application/json',
      'apikey': SupabaseConfig.publishableKey,
      'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<List<Food>> searchFoods(
    String query, {
    int page = 0,
    int maxResults = 50,
    String? category,
  }) async {
    final cleanQuery = query.trim();

    try {
      if (cleanQuery.isEmpty) {
        return _localFallback.searchFoods(
          cleanQuery,
          page: page,
          maxResults: maxResults,
          category: category,
        );
      }

      final response = await _httpClient
          .post(
            _edgeFunctionUri,
            headers: _buildHeaders(),
            body: jsonEncode({
              'action': 'search',
              'query': cleanQuery,
              'pageNumber': page,
              'maxResults': maxResults,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final foodsList = data['foods'] as List<dynamic>? ?? [];
        final results = foodsList
            .whereType<Map<String, dynamic>>()
            .map(Food.fromJson)
            .toList();

        if (results.isNotEmpty) {
          return results;
        }
      }

      // If FatSecret returned empty or non-200, query Indonesian database
      return _localFallback.searchFoods(
        cleanQuery,
        page: page,
        maxResults: maxResults,
        category: category,
      );
    } catch (_) {
      // Instant fallback to Indonesian food dataset
      return _localFallback.searchFoods(
        cleanQuery,
        page: page,
        maxResults: maxResults,
        category: category,
      );
    }
  }

  @override
  Future<Food?> getFoodDetails(String foodId) async {
    final cleanId = foodId.trim();
    if (cleanId.isEmpty) return null;

    // Local & Indonesian items are resolved locally without network calls
    if (cleanId.startsWith('indo_') || cleanId.startsWith('local_')) {
      return _localFallback.getFoodDetails(cleanId);
    }

    try {
      final response = await _httpClient
          .post(
            _edgeFunctionUri,
            headers: _buildHeaders(),
            body: jsonEncode({
              'action': 'details',
              'foodId': cleanId,
            }),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final foodJson = data['food'] as Map<String, dynamic>?;
        if (foodJson != null) {
          return Food.fromJson(foodJson);
        }
        return null;
      }
    } catch (_) {
      return _localFallback.getFoodDetails(cleanId);
    }
    return _localFallback.getFoodDetails(cleanId);
  }
}

/// In-memory food search service powered by curated Indonesian foods
/// for sub-millisecond, offline-capable, highly reliable logging.
class MockFoodSearchService implements FoodSearchService {
  final List<Food> _foods;

  MockFoodSearchService([List<Food>? foods])
      : _foods = foods ?? [...indonesianFoods, ...demoFoods];

  @override
  Future<List<Food>> searchFoods(
    String query, {
    int page = 0,
    int maxResults = 50,
    String? category,
  }) async {
    final clean = query.trim().toLowerCase();

    // 1. Filter by category if specified
    List<Food> baseList = _foods;
    if (category != null && category.isNotEmpty && category != 'Semua') {
      baseList = baseList.where((f) {
        final foodCat = f.category.toLowerCase();
        return foodCat == category.toLowerCase();
      }).toList();
    }

    if (clean.isEmpty) {
      return baseList.take(maxResults).toList();
    }

    // 2. Token-based matching (e.g. 'ayam geprek' matches both 'ayam' and 'geprek')
    final tokens = clean.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    return baseList.where((f) {
      final nameLower = f.name.toLowerCase();
      final catLower = f.category.toLowerCase();

      // Check exact substring first
      if (nameLower.contains(clean)) return true;

      // Check all tokens
      return tokens.every((token) => nameLower.contains(token) || catLower.contains(token));
    }).take(maxResults).toList();
  }

  @override
  Future<Food?> getFoodDetails(String foodId) async {
    try {
      return _foods.firstWhere((f) => f.id == foodId);
    } catch (_) {
      return null;
    }
  }
}
