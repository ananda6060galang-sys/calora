import 'package:flutter_riverpod/legacy.dart';
import '../../../models/food_request.dart';

/// Manages user-submitted food requests.
///
/// All new submissions start with status `pending`.
/// No local approval/rejection is simulated — that is the Admin Web's
/// responsibility once Supabase integration is in place.
class FoodRequestNotifier extends StateNotifier<List<FoodRequest>> {
  FoodRequestNotifier() : super([]);

  void add({
    required String foodName,
    required String categoryId,
    required String servingLabel,
    required int calories,
    required double proteinG,
    required double carbsG,
    required double fatG,
    String? notes,
  }) {
    state = [
      ...state,
      FoodRequest(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        userId: 'mock-user', // replaced by real auth uid later
        foodName: foodName,
        categoryId: categoryId,
        servingLabel: servingLabel,
        calories: calories,
        proteinG: proteinG,
        carbsG: carbsG,
        fatG: fatG,
        status: 'pending',
        notes: notes,
        createdAt: DateTime.now(),
      ),
    ];
  }
}

final foodRequestProvider =
    StateNotifierProvider<FoodRequestNotifier, List<FoodRequest>>(
      (ref) => FoodRequestNotifier(),
    );
