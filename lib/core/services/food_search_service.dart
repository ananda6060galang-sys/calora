import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/food.dart';
import '../../models/mock_data.dart';
import '../config/supabase_config.dart';

/// Abstraction for food searching and food details lookup.
abstract class FoodSearchService {
  Future<List<Food>> searchFoods(String query, {int page = 0, int maxResults = 20});
  Future<Food?> getFoodDetails(String foodId);
}

/// Real food search service powered by FatSecret through Supabase Edge Function.
/// Flutter NEVER holds or sends FatSecret client secrets.
class FatSecretFoodSearchService implements FoodSearchService {
  FatSecretFoodSearchService({SupabaseClient? client, http.Client? httpClient})
      : _client = client ?? Supabase.instance.client,
        _httpClient = httpClient ?? http.Client();

  final SupabaseClient _client;
  final http.Client _httpClient;

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
  Future<List<Food>> searchFoods(String query, {int page = 0, int maxResults = 20}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

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
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final foodsList = data['foods'] as List<dynamic>? ?? [];
        return foodsList
            .whereType<Map<String, dynamic>>()
            .map(Food.fromJson)
            .toList();
      } else {
        throw Exception(
          'Food search failed (status ${response.statusCode})',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Food?> getFoodDetails(String foodId) async {
    final cleanId = foodId.trim();
    if (cleanId.isEmpty) return null;

    // Local items are resolved locally without network calls
    if (cleanId.startsWith('local_')) {
      try {
        return demoFoods.firstWhere((f) => f.id == cleanId);
      } catch (_) {
        return null;
      }
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
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final foodJson = data['food'] as Map<String, dynamic>?;
        if (foodJson != null) {
          return Food.fromJson(foodJson);
        }
        return null;
      } else {
        throw Exception(
          'Food details failed (status ${response.statusCode})',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}

/// In-memory mock food search service for development, testing, and offline fallback.
class MockFoodSearchService implements FoodSearchService {
  final List<Food> _foods;

  MockFoodSearchService([List<Food>? foods]) : _foods = foods ?? demoFoods;

  @override
  Future<List<Food>> searchFoods(String query, {int page = 0, int maxResults = 20}) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) {
      return _foods.take(maxResults).toList();
    }
    await Future.delayed(const Duration(milliseconds: 150)); // simulated latency
    return _foods
        .where((f) => f.name.toLowerCase().contains(clean))
        .take(maxResults)
        .toList();
  }

  @override
  Future<Food?> getFoodDetails(String foodId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _foods.firstWhere((f) => f.id == foodId);
    } catch (_) {
      return null;
    }
  }
}
