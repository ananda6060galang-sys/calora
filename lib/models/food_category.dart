/// Lightweight model for food categories.
///
/// Designed to later map 1-to-1 with the `food_categories` Supabase table.
/// For now the UI reads from [mockFoodCategories]; when the backend is
/// wired up this list is replaced by a Riverpod provider that queries the
/// database — no UI rewrite needed.
class FoodCategory {
  const FoodCategory({required this.id, required this.name});

  final String id;
  final String name;

  @override
  String toString() => name;
}

/// Mock data — will be replaced by `food_categories` table query.
final mockFoodCategories = <FoodCategory>[
  const FoodCategory(id: 'c1', name: 'Protein'),
  const FoodCategory(id: 'c2', name: 'Carbs'),
  const FoodCategory(id: 'c3', name: 'Fats'),
  const FoodCategory(id: 'c4', name: 'Dairy'),
  const FoodCategory(id: 'c5', name: 'Fruit'),
  const FoodCategory(id: 'c6', name: 'General'),
];
