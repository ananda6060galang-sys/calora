import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../models/weight_log.dart';
import '../../dashboard/providers/profile_provider.dart';

/// StateNotifier managing real, authentic user weight logs.
/// Strictly follows PRD & user rules: NO fake or demo progress data.
class WeightLogNotifier extends StateNotifier<List<WeightLog>> {
  WeightLogNotifier(this._ref) : super([]);

  final Ref _ref;

  /// Records a new weight measurement entry.
  /// Replaces existing entry if logged on the same calendar day, otherwise appends.
  /// Keeps the list strictly sorted chronologically by [loggedDate].
  void addWeightLog(double newWeight, {String? notes, DateTime? date}) {
    final logDate = date ?? DateTime.now();
    final newEntry = WeightLog(
      id: 'w_${logDate.millisecondsSinceEpoch}',
      weightKg: double.parse(newWeight.toStringAsFixed(1)),
      loggedDate: logDate,
      notes: notes,
    );

    final updated = List<WeightLog>.from(state);
    final existingIndex = updated.indexWhere((log) =>
        log.loggedDate.year == logDate.year &&
        log.loggedDate.month == logDate.month &&
        log.loggedDate.day == logDate.day);

    if (existingIndex != -1) {
      updated[existingIndex] = newEntry;
    } else {
      updated.add(newEntry);
    }

    // Sort chronologically ascending
    updated.sort((a, b) => a.loggedDate.compareTo(b.loggedDate));

    state = updated;

    // Synchronize latest weight with profile's current weight
    final currentProfile = _ref.read(userProfileProvider);
    _ref.read(userProfileProvider.notifier).state = currentProfile.copyWith(
      weightKg: updated.last.weightKg,
    );
  }

  /// Removes an individual weight entry by [id].
  void deleteWeightLog(String id) {
    final updated = state.where((log) => log.id != id).toList();
    state = updated;

    if (updated.isNotEmpty) {
      final currentProfile = _ref.read(userProfileProvider);
      _ref.read(userProfileProvider.notifier).state = currentProfile.copyWith(
        weightKg: updated.last.weightKg,
      );
    }
  }

  /// Clears all weight logs (e.g. upon account reset).
  void clearLogs() {
    state = [];
  }
}

final weightLogProvider =
    StateNotifierProvider<WeightLogNotifier, List<WeightLog>>((ref) {
  return WeightLogNotifier(ref);
});
