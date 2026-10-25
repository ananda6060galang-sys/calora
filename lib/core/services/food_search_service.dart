import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/food.dart';
import '../../models/food_category.dart';
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
    final accessToken = session?.accessToken;
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'apikey': SupabaseConfig.publishableKey,
    };
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    return headers;
  }

  @override
  Future<List<Food>> searchFoods(
    String query, {
    int page = 0,
    int maxResults = 50,
    String? category,
  }) async {
    final cleanQuery = query.trim();

    // 1. Fetch matching verified foods from real Supabase public.foods
    List<Food> supabaseFoods = [];
    try {
      var sbQuery = _client
          .from('foods')
          .select('*, food_categories(name)');

      if (cleanQuery.isNotEmpty) {
        sbQuery = sbQuery.ilike('name', '%$cleanQuery%');
      }

      final hasCategory = category != null &&
          category.isNotEmpty &&
          category != 'Semua' &&
          category != 'All';

      if (hasCategory) {
        final matchedCat = defaultFoodCategories.where(
          (c) => c.name.toLowerCase() == category.toLowerCase() ||
                 c.id == category,
        ).firstOrNull;

        if (matchedCat != null) {
          sbQuery = sbQuery.eq('category_id', matchedCat.id);
        }
      }

      final sbResponse = await sbQuery
          .order('created_at', ascending: false)
          .limit(maxResults);

      final list = sbResponse as List<dynamic>;
      supabaseFoods = list
          .map((row) => Food.fromSupabase(row as Map<String, dynamic>))
          .where((f) {
            if (!hasCategory) return true;
            return f.category.toLowerCase() == category.toLowerCase();
          })
          .toList();
    } catch (_) {
      // Offline / network fallback
    }

    // 2. Fetch external / local foods
    List<Food> otherFoods = [];
    try {
      if (cleanQuery.isEmpty) {
        otherFoods = await _localFallback.searchFoods(
          cleanQuery,
          page: page,
          maxResults: maxResults,
          category: category,
        );
      } else {
        // Fetch external search results (FatSecret / USDA Edge Function)
        List<Food> externalResults = [];
        try {
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
            externalResults = foodsList
                .whereType<Map<String, dynamic>>()
                .map(Food.fromJson)
                .toList();
          }
        } catch (_) {}

        // Always query local/curated Indonesian database as well
        final localResults = await _localFallback.searchFoods(
          cleanQuery,
          page: page,
          maxResults: maxResults,
          category: category,
        );

        // Put curated local/Indonesian foods first, then external results
        otherFoods = [...localResults, ...externalResults];
      }
    } catch (_) {
      otherFoods = await _localFallback.searchFoods(
        cleanQuery,
        page: page,
        maxResults: maxResults,
        category: category,
      );
    }

    // 3. Merge: Prioritize Supabase database items at the top without duplicates
    final combined = <Food>[...supabaseFoods];
    final seenNames = {
      for (final f in supabaseFoods) f.name.toLowerCase().trim()
    };

    for (final f in otherFoods) {
      final nameKey = f.name.toLowerCase().trim();
      if (!seenNames.contains(nameKey)) {
        seenNames.add(nameKey);
        combined.add(f);
      }
    }

    return combined;
  }

  @override
  Future<Food?> getFoodDetails(String foodId) async {
    final cleanId = foodId.trim();
    if (cleanId.isEmpty) return null;

    // Check Supabase public.foods first
    try {
      final sbResponse = await _client
          .from('foods')
          .select('*, food_categories(name)')
          .eq('id', cleanId)
          .maybeSingle();

      if (sbResponse != null) {
        return Food.fromSupabase(sbResponse);
      }
    } catch (_) {}

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
    if (category != null && category.isNotEmpty && category != 'Semua' && category != 'All') {
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
