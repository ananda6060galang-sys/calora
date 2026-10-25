/// Model for user-submitted food requests.
///
/// Field names and types are aligned with the final ERD `food_request`
/// entity in Supabase.
///
/// Status values are: `pending`, `approved`, `rejected`.
class FoodRequest {
  const FoodRequest({
    required this.id,
    required this.userId,
    required this.foodName,
    required this.categoryId,
    this.categoryName,
    required this.servingLabel,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.status = 'pending',
    this.notes,
    this.barcode,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String foodName;
  final String categoryId; // maps to food_categories.id
  final String? categoryName;
  final String servingLabel;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  /// One of: `pending`, `approved`, `rejected`.
  final String status;

  final String? notes;
  final String? barcode;
  final DateTime createdAt;

  factory FoodRequest.fromSupabase(Map<String, dynamic> row) {
    String? catName;
    if (row['food_categories'] is Map) {
      catName = (row['food_categories'] as Map)['name']?.toString();
    }

    return FoodRequest(
      id: row['id']?.toString() ?? '',
      userId: row['user_id']?.toString() ?? '',
      foodName: row['food_name']?.toString() ?? '',
      categoryId: row['category_id']?.toString() ?? '',
      categoryName: catName,
      servingLabel: row['serving_label']?.toString() ?? '1 serving',
      calories: (row['calories'] as num?)?.round() ?? 0,
      proteinG: (row['protein_g'] as num?)?.toDouble() ?? 0.0,
      carbsG: (row['carbs_g'] as num?)?.toDouble() ?? 0.0,
      fatG: (row['fat_g'] as num?)?.toDouble() ?? 0.0,
      status: row['status']?.toString() ?? 'pending',
      notes: row['notes']?.toString(),
      barcode: row['barcode']?.toString(),
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'user_id': userId,
      'category_id': categoryId.isNotEmpty ? categoryId : null,
      'food_name': foodName,
      'serving_label': servingLabel,
      'calories': calories,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
      'notes': notes,
      if (barcode != null && barcode!.isNotEmpty) 'barcode': barcode,
    };
  }

  FoodRequest copyWith({
    String? id,
    String? userId,
    String? foodName,
    String? categoryId,
    String? categoryName,
    String? servingLabel,
    int? calories,
    double? proteinG,
    double? carbsG,
    double? fatG,
    String? status,
    String? notes,
    String? barcode,
    DateTime? createdAt,
  }) {
    return FoodRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      foodName: foodName ?? this.foodName,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      servingLabel: servingLabel ?? this.servingLabel,
      calories: calories ?? this.calories,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      barcode: barcode ?? this.barcode,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
