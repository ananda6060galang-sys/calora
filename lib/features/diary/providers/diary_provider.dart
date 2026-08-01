import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../models/food.dart';
import '../../../models/mock_data.dart';

class DiaryNotifier extends StateNotifier<List<DiaryEntry>> {
  DiaryNotifier()
      : super([
          DiaryEntry(id: 'd1', food: demoFoods[3], servings: 1, meal: 'Breakfast'),
          DiaryEntry(id: 'd2', food: demoFoods[4], servings: 1, meal: 'Breakfast'),
          DiaryEntry(id: 'd3', food: demoFoods[0], servings: 1.5, meal: 'Lunch'),
          DiaryEntry(id: 'd4', food: demoFoods[1], servings: 1, meal: 'Lunch'),
        ]);

  void add(Food food, double servings, String meal) {
    state = [
      ...state,
      DiaryEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        food: food,
        servings: servings,
        meal: meal,
      ),
    ];
  }

  void remove(String id) {
    state = state.where((e) => e.id != id).toList();
  }

  void updateServings(String id, double servings) {
    state = [
      for (final e in state)
        if (e.id == id)
          DiaryEntry(id: e.id, food: e.food, servings: servings, meal: e.meal)
        else
          e,
    ];
  }
}

final diaryProvider =
    StateNotifierProvider<DiaryNotifier, List<DiaryEntry>>((ref) => DiaryNotifier());

final diaryTotalsProvider = Provider((ref) {
  final entries = ref.watch(diaryProvider);
  final calories = entries.fold<int>(0, (sum, e) => sum + e.calories);
  final protein = entries.fold<double>(0, (sum, e) => sum + e.proteinG);
  final carbs = entries.fold<double>(0, (sum, e) => sum + e.carbsG);
  final fat = entries.fold<double>(0, (sum, e) => sum + e.fatG);
  return DiaryTotals(calories: calories, proteinG: protein, carbsG: carbs, fatG: fat);
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
