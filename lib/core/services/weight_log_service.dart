import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../models/weight_log.dart';

/// Service responsible for managing user weight measurements with `public.weight_logs`.
class WeightLogService {
  final SupabaseClient _client;

  WeightLogService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  /// Fetches weight logs for the current authenticated user sorted chronologically.
  Future<List<WeightLog>> fetchLogs() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _client
          .from('weight_logs')
          .select('id, weight_kg, logged_date, notes')
          .eq('user_id', user.id)
          .order('logged_date', ascending: true);

      final list = response as List<dynamic>;
      return list
          .map((row) => WeightLog.fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Records or updates a weight measurement for a given calendar date.
  Future<WeightLog?> upsertWeightLog(
    double weightKg, {
    DateTime? date,
    String? notes,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final logDate = date ?? DateTime.now();
    final dateStr =
        '${logDate.year.toString().padLeft(4, '0')}-${logDate.month.toString().padLeft(2, '0')}-${logDate.day.toString().padLeft(2, '0')}';

    try {
      final response = await _client
          .from('weight_logs')
          .upsert(
            {
              'user_id': user.id,
              'weight_kg': weightKg,
              'logged_date': dateStr,
              'notes': notes,
            },
            onConflict: 'user_id,logged_date',
          )
          .select()
          .single();

      return WeightLog.fromMap(response);
    } catch (_) {
      return null;
    }
  }

  /// Deletes an individual weight measurement by its UUID.
  Future<void> deleteWeightLog(String id) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client
          .from('weight_logs')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id);
    } catch (_) {}
  }
}

final weightLogServiceProvider = Provider<WeightLogService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return WeightLogService(client);
});
