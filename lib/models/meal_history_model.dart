import 'package:cloud_firestore/cloud_firestore.dart';

class MealHistory {
  final String householdId;
  final String recipeName;
  final String difficulty;
  final int servings;
  final String calories; // keep as string to match your UI
  final int durationMinutes;
  final DateTime cookedAt;
  final List<Map<String,String>> ingredients; // [{name, amount}]

  MealHistory({
    required this.householdId,
    required this.recipeName,
    required this.difficulty,
    required this.servings,
    required this.calories,
    required this.durationMinutes,
    required this.cookedAt,
    required this.ingredients,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'householdId': householdId,
      'recipeName': recipeName,
      'difficulty': difficulty,
      'servings': servings,
      'calories': calories,
      'durationMinutes': durationMinutes,
      'cookedAt': Timestamp.fromDate(cookedAt),
      'ingredients': ingredients,
    };
  }

  static MealHistory fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MealHistory(
      householdId: d['householdId'],
      recipeName: d['recipeName'],
      difficulty: d['difficulty'] ?? 'Easy',
      servings: (d['servings'] ?? 1) as int,
      calories: d['calories'] ?? '',
      durationMinutes: (d['durationMinutes'] ?? 0) as int,
      cookedAt: (d['cookedAt'] as Timestamp).toDate(),
      ingredients: (d['ingredients'] as List<dynamic>)
          .map((e) => Map<String,String>.from(e as Map))
          .toList(),
    );
  }
}
