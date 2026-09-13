import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/food.dart';

/// Service responsible for Supabase database operations on `diary_entries`.
class DiaryService {
  final SupabaseClient _client;

  DiaryService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  /// Fetch all diary entries for the authenticated user.
  /// If [date] is provided, filters strictly for that calendar date.
  Future<List<DiaryEntry>> fetchEntries({DateTime? date}) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      var query = _client.from('diary_entries').select().eq('user_id', user.id);

      if (date != null) {
        final dateStr = date.toIso8601String().substring(0, 10);
        query = query.eq('logged_date', dateStr);
      }

      final response = await query.order('created_at', ascending: true);
      final list = response as List<dynamic>;
      return list
          .map((row) => DiaryEntry.fromSupabase(row as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // In case of network failure or table missing, return empty list gracefully
      return [];
    }
  }

  /// Insert a new diary entry.
  Future<void> insertEntry(DiaryEntry entry) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client.from('diary_entries').insert(entry.toSupabase(user.id));
    } catch (_) {
      // Gracefully handle offline / connection error
    }
  }

  /// Update servings for an existing diary entry.
  Future<void> updateServings(String id, double servings, DiaryEntry current) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final newCalories = (current.food.calories * servings).round();
    final newProtein = current.food.proteinG * servings;
    final newCarbs = current.food.carbsG * servings;
    final newFat = current.food.fatG * servings;

    try {
      await _client.from('diary_entries').update({
        'servings': servings,
        'calories': newCalories,
        'protein_g': newProtein,
        'carbs_g': newCarbs,
        'fat_g': newFat,
      }).eq('id', id).eq('user_id', user.id);
    } catch (_) {
      // Gracefully handle offline / connection error
    }
  }

  /// Delete a diary entry by ID.
  Future<void> deleteEntry(String id) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client.from('diary_entries').delete().eq('id', id).eq('user_id', user.id);
    } catch (_) {
      // Gracefully handle offline / connection error
    }
  }
}
