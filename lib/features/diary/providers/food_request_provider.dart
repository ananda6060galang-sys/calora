import 'package:flutter_riverpod/legacy.dart';
import '../../../core/services/food_request_service.dart';
import '../../../models/food_request.dart';
import '../../auth/providers/auth_provider.dart';

/// Manages user-submitted food requests against `public.food_request`.
class FoodRequestNotifier extends StateNotifier<List<FoodRequest>> {
  FoodRequestNotifier(this._service) : super([]) {
    reload();
  }

  final FoodRequestService _service;

  Future<void> reload() async {
    try {
      final requests = await _service.fetchUserRequests();
      state = requests;
    } catch (_) {
      // Keep existing state if offline or error
    }
  }

  Future<bool> add({
    required String foodName,
    required String categoryId,
    required String servingLabel,
    required int calories,
    required double proteinG,
    required double carbsG,
    required double fatG,
    String? notes,
    String? barcode,
  }) async {
    try {
      final created = await _service.submitRequest(
        foodName: foodName,
        categoryId: categoryId,
        servingLabel: servingLabel,
        calories: calories,
        proteinG: proteinG,
        carbsG: carbsG,
        fatG: fatG,
        notes: notes,
        barcode: barcode,
      );

      if (created != null) {
        state = [created, ...state];
        return true;
      }
    } catch (e) {
      // If error occurs, rethrow or return false
      rethrow;
    }
    return false;
  }

  Future<bool> update({
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
    try {
      final updated = await _service.updateRequest(
        id: id,
        foodName: foodName,
        categoryId: categoryId,
        servingLabel: servingLabel,
        calories: calories,
        proteinG: proteinG,
        carbsG: carbsG,
        fatG: fatG,
        notes: notes,
      );

      if (updated != null) {
        state = [
          for (final req in state)
            if (req.id == id) updated else req,
        ];
        return true;
      }
    } catch (e) {
      rethrow;
    }
    return false;
  }

  Future<void> delete(String id) async {
    // Optimistic removal
    final previous = state;
    state = state.where((req) => req.id != id).toList();

    try {
      await _service.withdrawRequest(id);
    } catch (_) {
      state = previous; // Rollback on failure
    }
  }
}

final foodRequestProvider =
    StateNotifierProvider<FoodRequestNotifier, List<FoodRequest>>((ref) {
  ref.watch(currentUserProvider);
  final service = ref.watch(foodRequestServiceProvider);
  return FoodRequestNotifier(service);
});
