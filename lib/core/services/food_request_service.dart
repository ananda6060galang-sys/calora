import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../models/food_request.dart';

/// Service responsible for managing user food submissions with `public.food_request`.
class FoodRequestService {
  final SupabaseClient _client;

  FoodRequestService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  /// Fetches submissions submitted by the currently logged-in user.
  Future<List<FoodRequest>> fetchUserRequests() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _client
          .from('food_request')
          .select('*, food_categories(name)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final list = response as List<dynamic>;
      return list
          .map((row) => FoodRequest.fromSupabase(row as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Inserts a new food request for review by Admin.
  Future<FoodRequest?> submitRequest({
    required String foodName,
    required String categoryId,
    required String servingLabel,
    required int calories,
    required double proteinG,
    required double carbsG,
    required double fatG,
    String? notes,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('User not authenticated');

    final payload = {
      'user_id': user.id,
      'category_id': categoryId,
      'food_name': foodName,
      'serving_label': servingLabel,
      'calories': calories,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
      'status': 'pending',
      'notes': notes,
    };

    final response = await _client
        .from('food_request')
        .insert(payload)
        .select('*, food_categories(name)')
        .single();

    return FoodRequest.fromSupabase(response);
  }

  /// Updates a pending food request.
  Future<FoodRequest?> updateRequest({
    required String id,
    required String foodName,
    required String categoryId,
    required String servingLabel,
    required int calories,
    required double proteinG,
    required double carbsG,
    required double fatG,
    String? notes,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('User not authenticated');

    final payload = {
      'category_id': categoryId,
      'food_name': foodName,
      'serving_label': servingLabel,
      'calories': calories,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
      'status': 'pending', // Re-submitting resets to pending
      'notes': notes,
    };

    final response = await _client
        .from('food_request')
        .update(payload)
        .eq('id', id)
        .eq('user_id', user.id)
        .select('*, food_categories(name)')
        .single();

    return FoodRequest.fromSupabase(response);
  }

  /// Withdraws / deletes a pending food request.
  Future<void> withdrawRequest(String id) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client
        .from('food_request')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id)
        .eq('status', 'pending');
  }
}

final foodRequestServiceProvider = Provider<FoodRequestService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return FoodRequestService(client);
});
