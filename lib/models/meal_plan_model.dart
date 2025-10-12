class MealPlanEntry {
  final String recipeName;
  final String imageUrl;
  final String time;         // "30 minutes"
  final String calories;     // "500 kcal"
  final String difficulty;
  final int servings;
  final List<Map<String, String>> ingredients;

  const MealPlanEntry({
    required this.recipeName,
    required this.imageUrl,
    required this.time,
    required this.calories,
    required this.difficulty,
    required this.servings,
    required this.ingredients,
  });

  Map<String, dynamic> toFirestore() => {
    'recipeName': recipeName,
    'imageUrl': imageUrl,
    'time': time,
    'calories': calories,
    'difficulty': difficulty,
    'servings': servings,
    'ingredients': ingredients,
  };

  factory MealPlanEntry.fromFirestore(Map<String, dynamic> m) => MealPlanEntry(
    recipeName: m['recipeName'] ?? '',
    imageUrl: m['imageUrl'] ?? '',
    time: m['time'] ?? '',
    calories: m['calories'] ?? '',
    difficulty: m['difficulty'] ?? 'Easy',
    servings: (m['servings'] ?? 2) as int,
    ingredients: (m['ingredients'] as List?)?.cast<Map<String, dynamic>>()
                   .map((x) => x.map((k,v)=>MapEntry(k, v?.toString() ?? ''))).toList()
                 ?? const [],
  );
}

class MealPlanDay {
  final DateTime date;
  final MealPlanEntry? lunch;
  final MealPlanEntry? dinner; // (add breakfast if you want 3 meals/day)

  const MealPlanDay({required this.date, this.lunch, this.dinner});

  Map<String, dynamic> toFirestore() => {
    'date': date.toIso8601String(),
    'lunch': lunch?.toFirestore(),
    'dinner': dinner?.toFirestore(),
  };
}

class MealPlan {
  final String id;              // doc id
  final String householdId;
  final DateTime weekStart;     // Monday (or today)
  final List<MealPlanDay> days; // 7 items

  const MealPlan({
    required this.id,
    required this.householdId,
    required this.weekStart,
    required this.days,
  });

  Map<String, dynamic> toFirestore() => {
    'householdId': householdId,
    'weekStart': weekStart.toIso8601String(),
    'days': days.map((d) => d.toFirestore()).toList(),
  };
}
