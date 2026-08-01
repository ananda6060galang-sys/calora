import 'food.dart';
import 'user_profile.dart';

final demoProfile = const UserProfile(
  name: 'TESTT',
  age: 24,
  gender: Gender.male,
  heightCm: 174,
  weightKg: 71,
  activityLevel: ActivityLevel.moderate,
  goal: Goal.leanBulk,
);

final demoFoods = <Food>[
  const Food(
    id: 'f1',
    name: 'Grilled Chicken Breast',
    servingLabel: '100 g',
    calories: 165,
    proteinG: 31,
    carbsG: 0,
    fatG: 3.6,
    category: 'Protein',
  ),
  const Food(
    id: 'f2',
    name: 'Steamed White Rice',
    servingLabel: '1 cup (158 g)',
    calories: 205,
    proteinG: 4.3,
    carbsG: 45,
    fatG: 0.4,
    category: 'Carbs',
  ),
  const Food(
    id: 'f3',
    name: 'Avocado',
    servingLabel: '1/2 fruit (100 g)',
    calories: 160,
    proteinG: 2,
    carbsG: 8.5,
    fatG: 14.7,
    category: 'Fats',
  ),
  const Food(
    id: 'f4',
    name: 'Greek Yogurt Plain',
    servingLabel: '170 g cup',
    calories: 100,
    proteinG: 17,
    carbsG: 6,
    fatG: 0.5,
    category: 'Dairy',
  ),
  const Food(
    id: 'f5',
    name: 'Banana',
    servingLabel: '1 medium (118 g)',
    calories: 105,
    proteinG: 1.3,
    carbsG: 27,
    fatG: 0.4,
    category: 'Fruit',
  ),
];
