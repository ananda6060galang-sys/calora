import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/diary_service.dart';
import '../../../models/food.dart';
import '../../../models/mock_data.dart';

final diaryServiceProvider = Provider<DiaryService>((ref) => DiaryService());

class DiaryNotifier extends StateNotifier<List<DiaryEntry>> {
  DiaryNotifier([this._service]) : super([]) {
    _init();
  }

  final DiaryService? _service;

  Future<void> _init() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user != null && _service != null) {
      final remote = await _service.fetchEntries();
      if (remote.isNotEmpty) {
        state = remote;
        return;
      }
    }

    // Default mock data fallback if no remote data exists yet
    state = [
      DiaryEntry(
        id: generateUuidV4(),
        food: demoFoods[3],
        servings: 1,
        meal: 'Breakfast',
        date: DateTime.now(),
        portionGrams: 170,
      ),
      DiaryEntry(
        id: generateUuidV4(),
        food: demoFoods[4],
        servings: 1,
        meal: 'Breakfast',
        date: DateTime.now(),
        portionGrams: 118,
      ),
      DiaryEntry(
        id: generateUuidV4(),
        food: demoFoods[0],
        servings: 1.5,
        meal: 'Lunch',
        date: DateTime.now(),
        portionGrams: 150,
      ),
      DiaryEntry(
        id: generateUuidV4(),
        food: demoFoods[1],
        servings: 1,
        meal: 'Lunch',
        date: DateTime.now(),
        portionGrams: 158,
      ),
    ];
  }

  void add(
    Food food,
    double servings,
    String meal,
    DateTime date, {
    double? portionGrams,
  }) {
    final newEntry = DiaryEntry(
      id: generateUuidV4(),
      food: food,
      servings: servings,
      meal: meal,
      date: date,
      portionGrams: portionGrams,
    );

    // Optimistic state update
    state = [...state, newEntry];

    // Async Supabase persistence
    _service?.insertEntry(newEntry);
  }

  void remove(String id) {
    state = state.where((e) => e.id != id).toList();
    _service?.deleteEntry(id);
  }

  void updateServings(String id, double servings) {
    DiaryEntry? current;
    state = [
      for (final e in state)
        if (e.id == id) ...[
          () {
            current = e;
            return DiaryEntry(
              id: e.id,
              food: e.food,
              servings: servings,
              meal: e.meal,
              date: e.date,
              portionGrams: e.portionGrams,
            );
          }()
        ] else
          e,
    ];

    if (current != null) {
      _service?.updateServings(id, servings, current!);
    }
  }

  Future<void> reload() async {
    if (_service != null) {
      final remote = await _service.fetchEntries();
      if (remote.isNotEmpty) {
        state = remote;
      }
    }
  }
}

final diaryProvider = StateNotifierProvider<DiaryNotifier, List<DiaryEntry>>(
  (ref) => DiaryNotifier(ref.watch(diaryServiceProvider)),
);

final diaryEntriesForDateProvider = Provider.family<List<DiaryEntry>, DateTime>(
  (ref, date) {
    final allEntries = ref.watch(diaryProvider);
    return allEntries.where((e) => DateUtils.isSameDay(e.date, date)).toList();
  },
);

final diaryTotalsForDateProvider = Provider.family<DiaryTotals, DateTime>((
  ref,
  date,
) {
  final entries = ref.watch(diaryEntriesForDateProvider(date));
  final calories = entries.fold<int>(0, (sum, e) => sum + e.calories);
  final protein = entries.fold<double>(0, (sum, e) => sum + e.proteinG);
  final carbs = entries.fold<double>(0, (sum, e) => sum + e.carbsG);
  final fat = entries.fold<double>(0, (sum, e) => sum + e.fatG);
  return DiaryTotals(
    calories: calories,
    proteinG: protein,
    carbsG: carbs,
    fatG: fat,
  );
});

final diaryTotalsProvider = Provider((ref) {
  return ref.watch(diaryTotalsForDateProvider(DateTime.now()));
});

class DiaryTotals {
  const DiaryTotals({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
}
