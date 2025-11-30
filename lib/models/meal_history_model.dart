// lib/models/meal_history_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class MealHistory {
  final String householdId;
  final String recipeName;
  final String difficulty;
  final int servings;
  final String calories;            // numeric string, e.g. "520"
  final int durationMinutes;        // 12, 15, etc.
  final DateTime cookedAt;
  final List<Map<String, String>> ingredients; // [{name, amount}]
  final String imageUrl;
  final String time;

  MealHistory({
    required this.householdId,
    required this.recipeName,
    required this.difficulty,
    required this.servings,
    required this.calories,
    required this.durationMinutes,
    required this.cookedAt,
    required this.ingredients,
    required this.imageUrl,
    required this.time,
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
      'imageUrl': imageUrl,
      'time': time, 
    };
  }

  static MealHistory fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    final rawIngredients = (d['ingredients'] as List<dynamic>? ?? []);
    final ingredients = rawIngredients.map<Map<String, String>>((i) {
      final m = (i as Map<String, dynamic>);
      final name = (m['name'] ?? '').toString().trim();
      final amount =
          (m['amount'] ?? m['measurement'] ?? '').toString().trim();
      return {
        'name': name,
        'amount': amount,
      };
    }).toList();

    return MealHistory(
      householdId: d['householdId'] ?? '',
      recipeName: d['recipeName'] ?? '',
      difficulty: d['difficulty'] ?? 'Easy',
      servings: (d['servings'] ?? 1) as int,
      calories: d['calories'] ?? '',
      durationMinutes: (d['durationMinutes'] ?? 0) as int,
      cookedAt: (d['cookedAt'] as Timestamp).toDate(),
      ingredients: ingredients,
      imageUrl: d['imageUrl'] ?? '',
      time: d['time'] ?? '',
    );
  }
}
