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
}

class DiaryEntry {
  const DiaryEntry({
    required this.id,
    required this.food,
    required this.servings,
    required this.meal,
    required this.date,
  });

  final String id;
  final Food food;
  final double servings;
  final String meal; // Breakfast / Lunch / Dinner / Snacks
  final DateTime date;

  int get calories => (food.calories * servings).round();
  double get proteinG => food.proteinG * servings;
  double get carbsG => food.carbsG * servings;
  double get fatG => food.fatG * servings;
}
