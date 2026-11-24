import 'package:shared_preferences/shared_preferences.dart';
import '../../models/scan_history_item.dart';

class ScanHistoryService {
  static const String _storageKey = 'calora_scan_history_v1';
  static const int _maxHistoryLimit = 60;

  Future<List<ScanHistoryItem>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_storageKey);
      if (rawList == null || rawList.isEmpty) return [];

      final items = <ScanHistoryItem>[];
      for (final rawJson in rawList) {
        try {
          items.add(ScanHistoryItem.fromJson(rawJson));
        } catch (_) {}
      }

      // Sort descending by scannedAt (newest first)
      items.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
      return items;
    } catch (_) {
      return [];
    }
  }

  Future<void> addItem(ScanHistoryItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentList = await getHistory();

      // Avoid immediate consecutive duplicate by ID or exact same food name & time (< 5 sec)
      currentList.removeWhere((e) =>
          e.id == item.id ||
          (e.foodName.toLowerCase() == item.foodName.toLowerCase() &&
              item.scannedAt.difference(e.scannedAt).inSeconds.abs() < 5));

      currentList.insert(0, item);

      // Enforce max history limit
      if (currentList.length > _maxHistoryLimit) {
        currentList.removeRange(_maxHistoryLimit, currentList.length);
      }

      final stringList = currentList.map((e) => e.toJson()).toList();
      await prefs.setStringList(_storageKey, stringList);
    } catch (_) {}
  }

  Future<void> removeItem(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentList = await getHistory();
      currentList.removeWhere((e) => e.id == id);
      final stringList = currentList.map((e) => e.toJson()).toList();
      await prefs.setStringList(_storageKey, stringList);
    } catch (_) {}
  }

  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }
}
