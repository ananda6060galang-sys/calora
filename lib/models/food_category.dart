/// Model for food categories mapping to `public.food_categories`.
class FoodCategory {
  const FoodCategory({required this.id, required this.name});

  final String id;
  final String name;

  factory FoodCategory.fromJson(Map<String, dynamic> json) {
    return FoodCategory(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  @override
  String toString() => name;
}

/// Real default categories matching public.food_categories UUIDs in Supabase.
const defaultFoodCategories = <FoodCategory>[
  FoodCategory(id: '923f801b-ef57-4b33-b62f-477bb90cd3a0', name: 'Rice'),
  FoodCategory(id: '1030a214-f514-4c29-870e-0070f79e2abf', name: 'Carbs'),
  FoodCategory(id: '0645608c-caae-4911-b4b2-4c141d3a9b53', name: 'Meat'),
  FoodCategory(id: 'b75d90b9-f48d-4f85-a226-0673172b93b0', name: 'Protein'),
  FoodCategory(id: 'c872c568-95e6-494d-9e21-df5090423270', name: 'Plant'),
  FoodCategory(id: 'ce602e85-8313-4a5d-8d0b-1485b9a5111b', name: 'Veggies'),
  FoodCategory(id: '9a0f7a21-bc32-435a-a73e-03076f0fb73b', name: 'Snacks'),
  FoodCategory(id: '3603acc9-e57a-4a2f-85df-e7c623ca8163', name: 'Drinks'),
];

/// Backward compatibility alias — uses real UUIDs instead of mock IDs.
const mockFoodCategories = defaultFoodCategories;
