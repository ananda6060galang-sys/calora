import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../core/services/scan_history_service.dart';
import '../../../models/scan_history_item.dart';

final scanHistoryServiceProvider =
    Provider<ScanHistoryService>((ref) => ScanHistoryService());

class ScanHistoryNotifier extends StateNotifier<List<ScanHistoryItem>> {
  ScanHistoryNotifier(this._service) : super([]) {
    load();
  }

  final ScanHistoryService _service;

  Future<void> load() async {
    final list = await _service.getHistory();
    state = list;
  }

  Future<void> addScan({
    required String id,
    required String foodName,
    required int calories,
    required double proteinG,
    required double carbsG,
    required double fatG,
    required ScanType scanType,
    double? portionGrams,
    String? servingLabel,
    String? imagePath,
    String? barcode,
    String? suggestedMeal,
  }) async {
    final item = ScanHistoryItem(
      id: id,
      foodName: foodName,
      calories: calories,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      scannedAt: DateTime.now(),
      scanType: scanType,
      portionGrams: portionGrams,
      servingLabel: servingLabel,
      imagePath: imagePath,
      barcode: barcode,
      suggestedMeal: suggestedMeal,
    );

    // Optimistic update
    state = [item, ...state.where((e) => e.id != id)];
    await _service.addItem(item);
  }

  Future<void> deleteScan(String id) async {
    state = state.where((e) => e.id != id).toList();
    await _service.removeItem(id);
  }

  Future<void> clearHistory() async {
    state = [];
    await _service.clearAll();
  }
}

final scanHistoryProvider =
    StateNotifierProvider<ScanHistoryNotifier, List<ScanHistoryItem>>((ref) {
  final service = ref.watch(scanHistoryServiceProvider);
  return ScanHistoryNotifier(service);
});
