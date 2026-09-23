import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../models/food_category.dart';

/// Service responsible for fetching food categories from Supabase.
class CategoryService {
  final SupabaseClient _client;

  CategoryService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  /// Fetches all categories from `public.food_categories` sorted alphabetically.
  Future<List<FoodCategory>> fetchCategories() async {
    try {
      final response = await _client
          .from('food_categories')
          .select('id, name')
          .order('name', ascending: true);

      final list = response as List<dynamic>;
      final categories = list
          .map((row) => FoodCategory.fromJson(row as Map<String, dynamic>))
          .toList();

      if (categories.isNotEmpty) {
        return categories;
      }
    } catch (_) {
      // Gracefully fall back to real default UUID categories
    }
    return defaultFoodCategories;
  }
}

final categoryServiceProvider = Provider<CategoryService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return CategoryService(client);
});

/// FutureProvider exposing all available food categories.
final foodCategoriesProvider = FutureProvider<List<FoodCategory>>((ref) async {
  final service = ref.watch(categoryServiceProvider);
  return service.fetchCategories();
});
