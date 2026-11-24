import 'dart:convert';
import 'food.dart';

enum ScanType { ai, barcode }

class ScanHistoryItem {
  const ScanHistoryItem({
    required this.id,
    required this.foodName,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.scannedAt,
    required this.scanType,
    this.portionGrams,
    this.servingLabel,
    this.imagePath,
    this.barcode,
    this.suggestedMeal,
  });

  final String id;
  final String foodName;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final DateTime scannedAt;
  final ScanType scanType;
  final double? portionGrams;
  final String? servingLabel;
  final String? imagePath;
  final String? barcode;
  final String? suggestedMeal;

  Food toFood() {
    return Food(
      id: id,
      name: foodName,
      servingLabel: servingLabel ?? '1 porsi (${portionGrams?.round() ?? 100}g)',
      calories: calories,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      portionGrams: portionGrams,
      category: suggestedMeal ?? 'Lunch',
      source: scanType == ScanType.ai ? 'ai_scan' : 'barcode',
      barcode: barcode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'foodName': foodName,
      'calories': calories,
      'proteinG': proteinG,
      'carbsG': carbsG,
      'fatG': fatG,
      'scannedAt': scannedAt.toIso8601String(),
      'scanType': scanType.name,
      'portionGrams': portionGrams,
      'servingLabel': servingLabel,
      'imagePath': imagePath,
      'barcode': barcode,
      'suggestedMeal': suggestedMeal,
    };
  }

  factory ScanHistoryItem.fromMap(Map<String, dynamic> map) {
    return ScanHistoryItem(
      id: map['id'] as String,
      foodName: map['foodName'] as String? ?? 'Food',
      calories: (map['calories'] as num?)?.round() ?? 0,
      proteinG: (map['proteinG'] as num?)?.toDouble() ?? 0.0,
      carbsG: (map['carbsG'] as num?)?.toDouble() ?? 0.0,
      fatG: (map['fatG'] as num?)?.toDouble() ?? 0.0,
      scannedAt: DateTime.tryParse(map['scannedAt'] as String? ?? '') ?? DateTime.now(),
      scanType: (map['scanType'] as String?) == 'barcode' ? ScanType.barcode : ScanType.ai,
      portionGrams: (map['portionGrams'] as num?)?.toDouble(),
      servingLabel: map['servingLabel'] as String?,
      imagePath: map['imagePath'] as String?,
      barcode: map['barcode'] as String?,
      suggestedMeal: map['suggestedMeal'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory ScanHistoryItem.fromJson(String source) =>
      ScanHistoryItem.fromMap(json.decode(source) as Map<String, dynamic>);
}
