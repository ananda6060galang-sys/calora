import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../models/user_profile.dart';
import '../../../models/weight_log.dart';
import '../../dashboard/providers/profile_provider.dart';

class WeightLogNotifier extends StateNotifier<List<WeightLog>> {
  WeightLogNotifier(this._ref) : super([]) {
    _initDefaultHistory();
  }

  final Ref _ref;

  void _initDefaultHistory() {
    final profile = _ref.read(userProfileProvider);
    final now = DateTime.now();
    final currentWeight = profile.weightKg;

    // Seed 5 realistic weekly checkpoints leading up to today
    final List<WeightLog> initialLogs = [];
    final double stepDelta;
    if (profile.goal == Goal.loseWeight) {
      stepDelta = 0.5; // Was heavier previously
    } else if (profile.goal == Goal.gainWeight) {
      stepDelta = -0.5; // Was lighter previously
    } else {
      stepDelta = 0.05; // Fluctuating slightly
    }

    for (int i = 4; i >= 1; i--) {
      final date = now.subtract(Duration(days: i * 7));
      final weight = (currentWeight + (stepDelta * i)).clamp(20.0, 300.0);
      initialLogs.add(WeightLog(
        id: 'seed_w_$i',
        weightKg: double.parse(weight.toStringAsFixed(1)),
        loggedDate: date,
      ));
    }

    // Today's entry
    initialLogs.add(WeightLog(
      id: 'seed_w_today',
      weightKg: currentWeight,
      loggedDate: now,
    ));

    state = initialLogs;
  }

  void addWeightLog(double newWeight, {String? notes}) {
    final now = DateTime.now();
    final newEntry = WeightLog(
      id: 'w_${now.millisecondsSinceEpoch}',
      weightKg: double.parse(newWeight.toStringAsFixed(1)),
      loggedDate: now,
      notes: notes,
    );

    // If there's already a log today, replace or append
    final updated = List<WeightLog>.from(state);
    final todayIndex = updated.indexWhere((log) =>
        log.loggedDate.year == now.year &&
        log.loggedDate.month == now.month &&
        log.loggedDate.day == now.day);

    if (todayIndex != -1) {
      updated[todayIndex] = newEntry;
    } else {
      updated.add(newEntry);
    }

    state = updated;

    // Also synchronize profile's current weight
    final currentProfile = _ref.read(userProfileProvider);
    _ref.read(userProfileProvider.notifier).state = currentProfile.copyWith(
      weightKg: newWeight,
    );
  }
}

final weightLogProvider =
    StateNotifierProvider<WeightLogNotifier, List<WeightLog>>((ref) {
  return WeightLogNotifier(ref);
});
