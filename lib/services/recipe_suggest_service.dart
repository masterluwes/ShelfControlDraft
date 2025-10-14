// lib/services/recipe_suggest_service.dart
import 'dart:math';
import 'package:collection/collection.dart';

import '../models/pantry_item_model.dart';
import '../models/user_prefs_model.dart';
import '../models/suggested_recipe.dart';
import 'meal_planner.dart'; // Import MealPlanner
import 'normalization.dart';

// [NEAR_EXPIRY_LOCAL_HELPER] begin
bool _isNearExpiryLocal(DateTime? expiry, {int days = 5}) {
  if (expiry == null) return false;
  final now = DateTime.now();
  if (expiry.isBefore(now)) return false; // already expired
  return expiry.difference(now).inDays <= days;
}
// [NEAR_EXPIRY_LOCAL_HELPER] end

class RecipeSuggestService {
  RecipeSuggestService(); // No SpoonacularClient needed

  Future<List<SuggestedRecipe>> suggest({
    required List<PantryItemModel> pantry,
    required UserPrefs prefs,
    int limit = 12,
    int nearExpiryDays = 5,
  }) async {
    // Convert PantryItemModel to MealPlanner's PantryItem
    // Convert PantryItemModel to MealPlanner's PantryItem
    final mealPlannerPantry = pantry.map((model) {
      return PantryItem(
        name: normalizeName(model.name),
        qty: model.qty,
        expiryAt: model.expirationDate,
        consumed: model.status == 'Consumed',
        nearExpiry:
            _isNearExpiryLocal(model.expirationDate, days: nearExpiryDays),
      );
    }).toList();

    // [CALL_GENERATE_FIX] begin
    final localSuggestions = MealPlanner.generate(
        pantry: mealPlannerPantry,
        prefs: prefs,
        limit: limit, // use 'limit', not 'maxResults'
        nearExpiryDays: nearExpiryDays,
        pantryOnly: true, // strict pantry-only instead of 'maxMissing'
        preferNearExpiry: true);
// [CALL_GENERATE_FIX] end

    if (localSuggestions.isEmpty) {
      final regular = MealPlanner.generate(
        pantry: mealPlannerPantry,
        prefs: prefs,
        limit: limit,
        nearExpiryDays: nearExpiryDays,
        pantryOnly: true,
        preferNearExpiry: false,
      );
      // then map 'regular' instead of 'localSuggestions' below if non-empty
    }

    // Convert MealPlanner's RecipeSuggestion to SuggestedRecipe
    final candidates = localSuggestions.map((s) {
      final ingr = s.ingredients
          .map((i) => IngredientLine(
                name: normalizeName(i['name'] ?? ''),
                qty: double.tryParse(i['amount'] ?? '0'),
                unit: '', // MealPlanner doesn't provide units in this format
                inPantry:
                    true, // Assuming all ingredients from local suggestions are in pantry
              ))
          .toList();

      return SuggestedRecipe(
        id: s.name.replaceAll(' ', '_').toLowerCase(), // Generate a simple ID
        title: s.name,
        imageUrl: s.imageUrl,
        ingredients: ingr,
        steps: s.directions,
        servings: int.tryParse(s.servingSize),
        timeMin: int.tryParse(s.time.replaceAll(RegExp(r'[^0-9]'), '')),
        kcalPerServing:
            int.tryParse(s.calories.replaceAll(RegExp(r'[^0-9]'), '')),
        source: 'local',
        usesExpiring: [], // Local planner doesn't explicitly track this yet
        missingIngredients: const [],
        score: 1.0, // Default score for local recipes
      );
    }).toList();

    // 5) Fallback (AI) if none — TODO: wire your Cloud Function
    if (candidates.isEmpty) {
      // final aiRecipes = await _fallbackAi(...);
      // candidates = aiRecipes;
      return []; // keep stepwise progress for now
    }

    // 6) Score & rank (if needed, for now local recipes have score 1.0)
    // candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates.take(limit).toList();
  }

  // Remove Spoonacular-specific mapping methods
  // String? _mapDiet(UserPrefs prefs) { ... }
  // List<String> _mapIntolerances(UserPrefs prefs) { ... }
  // List<String> _mapExclusions(UserPrefs prefs) { ... }

  // Remove Spoonacular-specific _toSuggested method
  // SuggestedRecipe? _toSuggested(...) { ... }

  // Keep _violatesPrefs and _score if they are generic enough or adapt them
  bool _violatesPrefs(List<IngredientLine> ingr, UserPrefs prefs) {
    final names = ingr.map((i) => i.name).toSet();

    // dislikes & allergens are hard exclusions
    if (prefs.dislikes.any(names.contains)) return true;
    if (prefs.allergens.any(names.contains)) return true;

    // diet basics (expand if you add more diet types)
    final diets = prefs.diets.map((d) => d.toLowerCase()).toSet();
    if (diets.contains('vegan') &&
        names.any((n) => [
              'egg',
              'cheese',
              'milk',
              'butter',
              'pork',
              'beef',
              'chicken',
              'fish'
            ].contains(n))) return true;

    if (diets.contains('vegetarian') &&
        names.any((n) => ['pork', 'beef', 'chicken', 'fish'].contains(n))) {
      return true;
    }

    return false;
  }

  double _score(List<IngredientLine> ingr, List<String> usedExpiring) {
    final total = ingr.length;
    final have = ingr.where((i) => i.inPantry).length;
    final coverage = total == 0 ? 0.0 : have / total;
    final expiry =
        usedExpiring.length.clamp(0, 3) / 3.0; // up to 3 expiring items counted

    // weight: expiry 0.55, coverage 0.30, bias 0.15
    return 0.55 * expiry + 0.30 * coverage + 0.15;
  }
}
