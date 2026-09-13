import 'dart:math';

String generateUuidV4() {
  final rng = Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
}

class FoodServing {
  const FoodServing({
    required this.servingId,
    required this.servingDescription,
    this.metricServingAmount,
    this.metricServingUnit,
    this.numberOfUnits = 1.0,
    this.measurementDescription,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  final String servingId;
  final String servingDescription;
  final double? metricServingAmount;
  final String? metricServingUnit;
  final double numberOfUnits;
  final String? measurementDescription;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  factory FoodServing.fromJson(Map<String, dynamic> json) {
    return FoodServing(
      servingId: json['servingId'] as String? ?? '',
      servingDescription:
          json['servingDescription'] as String? ?? '1 serving',
      metricServingAmount:
          (json['metricServingAmount'] as num?)?.toDouble(),
      metricServingUnit: json['metricServingUnit'] as String?,
      numberOfUnits:
          (json['numberOfUnits'] as num?)?.toDouble() ?? 1.0,
      measurementDescription:
          json['measurementDescription'] as String?,
      calories: (json['calories'] as num?)?.round() ?? 0,
      proteinG: (json['proteinG'] as num?)?.toDouble() ?? 0.0,
      carbsG: (json['carbsG'] as num?)?.toDouble() ?? 0.0,
      fatG: (json['fatG'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'servingId': servingId,
      'servingDescription': servingDescription,
      'metricServingAmount': metricServingAmount,
      'metricServingUnit': metricServingUnit,
      'numberOfUnits': numberOfUnits,
      'measurementDescription': measurementDescription,
      'calories': calories,
      'proteinG': proteinG,
      'carbsG': carbsG,
      'fatG': fatG,
    };
  }
}

class Food {
  const Food({
    required this.id,
    required this.name,
    required this.servingLabel,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.category = 'General',
    this.isPrivate = false,
    this.portionGrams,
    this.source = 'local',
    this.servings = const [],
  });

  final String id;
  final String name;
  final String servingLabel;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String category;
  final bool isPrivate;
  final double? portionGrams;
  final String source; // 'local' | 'fatsecret'
  final List<FoodServing> servings;

  factory Food.fromJson(Map<String, dynamic> json) {
    final rawServings = json['servings'] as List<dynamic>? ?? [];
    String parsedCategory = 'General';
    final rawCategory = json['category'];
    if (rawCategory is String) {
      parsedCategory = rawCategory;
    } else if (rawCategory is Map && rawCategory['description'] != null) {
      parsedCategory = rawCategory['description'].toString();
    }

    return Food(
      id: json['id'] as String? ?? generateUuidV4(),
      name: json['name'] as String? ?? 'Food',
      servingLabel: json['servingLabel'] as String? ?? '1 serving',
      calories: (json['calories'] as num?)?.round() ?? 0,
      proteinG: (json['proteinG'] as num?)?.toDouble() ?? 0.0,
      carbsG: (json['carbsG'] as num?)?.toDouble() ?? 0.0,
      fatG: (json['fatG'] as num?)?.toDouble() ?? 0.0,
      category: parsedCategory,
      isPrivate: json['isPrivate'] as bool? ?? false,
      portionGrams: (json['portionGrams'] as num?)?.toDouble(),
      source: json['source'] as String? ?? 'fatsecret',
      servings: rawServings
          .whereType<Map<String, dynamic>>()
          .map(FoodServing.fromJson)
          .toList(),
    );
  }

  Food copyWith({
    String? id,
    String? name,
    String? servingLabel,
    int? calories,
    double? proteinG,
    double? carbsG,
    double? fatG,
    String? category,
    bool? isPrivate,
    double? portionGrams,
    String? source,
    List<FoodServing>? servings,
  }) {
    return Food(
      id: id ?? this.id,
      name: name ?? this.name,
      servingLabel: servingLabel ?? this.servingLabel,
      calories: calories ?? this.calories,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      category: category ?? this.category,
      isPrivate: isPrivate ?? this.isPrivate,
      portionGrams: portionGrams ?? this.portionGrams,
      source: source ?? this.source,
      servings: servings ?? this.servings,
    );
  }
}

class DiaryEntry {
  const DiaryEntry({
    required this.id,
    required this.food,
    required this.servings,
    required this.meal,
    required this.date,
    this.portionGrams,
  });

  final String id;
  final Food food;
  final double servings;
  final String meal; // Breakfast / Lunch / Dinner / Snack
  final DateTime date;
  final double? portionGrams;

  int get calories => (food.calories * servings).round();
  double get proteinG => food.proteinG * servings;
  double get carbsG => food.carbsG * servings;
  double get fatG => food.fatG * servings;

  Map<String, dynamic> toSupabase(String userId) {
    return {
      'id': id,
      'user_id': userId,
      'food_name': food.name,
      'meal_type': meal.toLowerCase(),
      'calories': calories,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
      'portion_grams': portionGrams,
      'servings': servings,
      'serving_label': food.servingLabel,
      'logged_date': date.toIso8601String().substring(0, 10),
    };
  }

  factory DiaryEntry.fromSupabase(Map<String, dynamic> row) {
    final food = Food(
      id: row['id'] as String? ?? generateUuidV4(),
      name: row['food_name'] as String? ?? 'Food',
      servingLabel: row['serving_label'] as String? ?? '1 serving',
      calories: (row['calories'] as num?)?.round() ?? 0,
      proteinG: (row['protein_g'] as num?)?.toDouble() ?? 0.0,
      carbsG: (row['carbs_g'] as num?)?.toDouble() ?? 0.0,
      fatG: (row['fat_g'] as num?)?.toDouble() ?? 0.0,
    );

    final loggedDateStr = row['logged_date'] as String?;
    final date = loggedDateStr != null
        ? DateTime.tryParse(loggedDateStr) ?? DateTime.now()
        : DateTime.now();

    final rawMeal = row['meal_type'] as String? ?? 'breakfast';
    final meal = rawMeal.isNotEmpty
        ? rawMeal[0].toUpperCase() + rawMeal.substring(1).toLowerCase()
        : 'Breakfast';

    return DiaryEntry(
      id: row['id'] as String,
      food: food,
      servings: (row['servings'] as num?)?.toDouble() ?? 1.0,
      meal: meal,
      date: date,
      portionGrams: (row['portion_grams'] as num?)?.toDouble(),
    );
  }
}
