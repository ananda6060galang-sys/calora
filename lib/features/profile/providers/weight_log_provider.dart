import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/services/weight_log_service.dart';
import '../../../models/weight_log.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/profile_provider.dart';

/// StateNotifier managing authentic user weight logs backed by `public.weight_logs`.
class WeightLogNotifier extends StateNotifier<List<WeightLog>> {
  WeightLogNotifier(this._ref, this._service) : super([]) {
    reload();
  }

  final Ref _ref;
  final WeightLogService _service;

  Future<void> reload() async {
    final logs = await _service.fetchLogs();
    if (logs.isNotEmpty) {
      state = logs;
      final currentProfile = _ref.read(userProfileProvider);
      _ref.read(userProfileProvider.notifier).state = currentProfile.copyWith(
        weightKg: logs.last.weightKg,
      );
    }
  }

  /// Records a new weight measurement entry.
  /// Replaces existing entry if logged on the same calendar day, otherwise appends.
  /// Keeps the list strictly sorted chronologically by [loggedDate].
  Future<void> addWeightLog(double newWeight, {String? notes, DateTime? date}) async {
    final logDate = date ?? DateTime.now();
    final cleanWeight = double.parse(newWeight.toStringAsFixed(1));

    final tempEntry = WeightLog(
      id: 'temp_${logDate.millisecondsSinceEpoch}',
      weightKg: cleanWeight,
      loggedDate: logDate,
      notes: notes,
    );

    final updated = List<WeightLog>.from(state);
    final existingIndex = updated.indexWhere((log) =>
        log.loggedDate.year == logDate.year &&
        log.loggedDate.month == logDate.month &&
        log.loggedDate.day == logDate.day);

    if (existingIndex != -1) {
      updated[existingIndex] = tempEntry;
    } else {
      updated.add(tempEntry);
    }

    // Sort chronologically ascending
    updated.sort((a, b) => a.loggedDate.compareTo(b.loggedDate));
    state = updated;

    // Synchronize latest weight with profile's current weight
    final currentProfile = _ref.read(userProfileProvider);
    _ref.read(userProfileProvider.notifier).state = currentProfile.copyWith(
      weightKg: updated.last.weightKg,
    );

    // Persist to Supabase
    final saved = await _service.upsertWeightLog(
      cleanWeight,
      date: logDate,
      notes: notes,
    );

    if (saved != null) {
      // Replace temporary id with real database id
      state = state.map((log) {
        if (log.loggedDate.year == logDate.year &&
            log.loggedDate.month == logDate.month &&
            log.loggedDate.day == logDate.day) {
          return saved;
        }
        return log;
      }).toList();
    }
  }

  /// Removes an individual weight entry by [id].
  Future<void> deleteWeightLog(String id) async {
    final previous = state;
    final updated = state.where((log) => log.id != id).toList();
    state = updated;

    if (updated.isNotEmpty) {
      final currentProfile = _ref.read(userProfileProvider);
      _ref.read(userProfileProvider.notifier).state = currentProfile.copyWith(
        weightKg: updated.last.weightKg,
      );
    }

    try {
      await _service.deleteWeightLog(id);
    } catch (_) {
      state = previous;
    }
  }

  /// Clears all weight logs (e.g. upon account reset).
  void clearLogs() {
    state = [];
  }
}

final weightLogProvider =
    StateNotifierProvider<WeightLogNotifier, List<WeightLog>>((ref) {
  ref.watch(currentUserProvider);
  final service = ref.watch(weightLogServiceProvider);
  return WeightLogNotifier(ref, service);
});
