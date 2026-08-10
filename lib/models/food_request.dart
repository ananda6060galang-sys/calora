/// Model for user-submitted food requests.
///
/// Field names and types are aligned with the final ERD `food_request`
/// entity so this class can later be constructed directly from a Supabase
/// row without breaking changes.
///
/// Status values are **only**: `pending`, `approved`, `rejected`.
class FoodRequest {
  const FoodRequest({
    required this.id,
    required this.userId,
    required this.foodName,
    required this.categoryId,
    required this.servingLabel,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String foodName;
  final String categoryId; // maps to food_categories.id
  final String servingLabel;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  /// One of: `pending`, `approved`, `rejected`.
  final String status;

  final String? notes;
  final DateTime createdAt;
}
