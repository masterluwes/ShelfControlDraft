// lib/services/recipe_suggest_service.dart
import 'dart:math';
import 'package:collection/collection.dart';

import '../models/pantry_item_model.dart';
import '../models/user_prefs_model.dart';
import '../models/suggested_recipe.dart'; // <-- ensure you created this model in Phase 1
import 'spoonacular_client.dart';
import 'normalization.dart';

class RecipeSuggestService {
  RecipeSuggestService(this._spoon);

  final SpoonacularClient _spoon;

  Future<List<SuggestedRecipe>> suggest({
    required List<PantryItemModel> pantry,
    required UserPrefs prefs,
    int limit = 12,
    int nearExpiryDays = 5,
  }) async {
    // 1) Normalize pantry & compute near-expiry set
    final canonPantry = pantry.map((p) => {
          'raw': p.name,
          'canon': normalizeName(p.name),
          // YOUR MODEL uses DateTime? expirationDate
          'expiry': p.expirationDate,
        }).toList();

    final nearExpirySet = canonPantry
        .where((m) => isNearExpiry(m['expiry'] as DateTime?, days: nearExpiryDays))
        .map((m) => m['canon'] as String)
        .toSet();

    // Count canonical ingredients and prioritize near-expiry first
    final counts = <String, int>{};
    for (final m in canonPantry) {
      counts.update(m['canon'] as String, (v) => v + 1, ifAbsent: () => 1);
    }
    final allCanon = counts.keys.toList();
    allCanon.sort((a, b) {
      final ae = nearExpirySet.contains(a) ? 1 : 0;
      final be = nearExpirySet.contains(b) ? 1 : 0;
      final cmpExpiry = be.compareTo(ae);
      return (cmpExpiry != 0) ? cmpExpiry : (counts[b]!).compareTo(counts[a]!);
    });

    // cap includeIngredients for saner API behavior
    final includeIngredients = allCanon.take(15).toList();

    // 2) Map prefs to API params
    final diet = _mapDiet(prefs);                 // from prefs.diets
    final intolerances = _mapIntolerances(prefs); // from prefs.allergens
    final excludes = _mapExclusions(prefs);       // from prefs.dislikes

    // 3) Call Spoonacular (primary)
    List<Map<String, dynamic>> apiResults = const [];
    try {
      apiResults = await _spoon.complexSearch(
        includeIngredients: includeIngredients,
        diet: diet,
        intolerances: intolerances,
        excludeIngredients: excludes,
        number: max(limit * 2, 24),
      );
    } catch (_) {
      // swallow; we'll fallback to AI later
    }

    // 4) Convert & post-filter
    var candidates = apiResults
        .map((r) => _toSuggested(r, canonPantry, nearExpirySet, prefs))
        .whereNotNull()
        .toList();

    // 5) Fallback (AI) if none — TODO: wire your Cloud Function
    if (candidates.isEmpty) {
      // final aiRecipes = await _fallbackAi(...);
      // candidates = aiRecipes;
      return []; // keep stepwise progress for now
    }

    // 6) Score & rank
    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates.take(limit).toList();
  }

  /// Your `UserPrefs` uses `diets` (List<String>)
  String? _mapDiet(UserPrefs prefs) {
    final diets = prefs.diets.map((d) => d.toLowerCase()).toSet();
    if (diets.contains('vegan')) return 'vegan';
    if (diets.contains('vegetarian')) return 'vegetarian';
    // Spoonacular expects 'pescetarian'
    if (diets.contains('pescatarian') || diets.contains('pescetarian')) return 'pescetarian';
    return null;
  }

  /// Intolerances map to your allergens field
  List<String> _mapIntolerances(UserPrefs prefs) => prefs.allergens;

  /// Exclusions map best to your 'dislikes'
  List<String> _mapExclusions(UserPrefs prefs) => prefs.dislikes;

  SuggestedRecipe? _toSuggested(
    Map<String, dynamic> r,
    List<Map<String, dynamic>> canonPantry,
    Set<String> nearExpirySet,
    UserPrefs prefs,
  ) {
    final id = r['id'];
    final title = (r['title'] ?? '').toString().trim();
    if (title.isEmpty) return null;

    final image = (r['image'] as String?);
    final timeMin = r['readyInMinutes'] as int?;
    final servings = r['servings'] as int?;

    // calories may be inside nutrition.nutrients[]
    int? kcal;
    final nutrition = r['nutrition'];
    if (nutrition is Map<String, dynamic>) {
      final nutrients = nutrition['nutrients'] as List?;
      final cal = nutrients?.firstWhereOrNull((n) => n['name'] == 'Calories');
      final amount = cal == null ? null : cal['amount'] as num?;
      kcal = amount?.round();
    }

    // ingredients
    final ingr = <IngredientLine>[];
    final usedCanon = <String>[];
    final ri = (r['extendedIngredients'] as List?) ?? const [];
    for (final i in ri) {
      final name = normalizeName((i['name'] ?? '').toString());
      final qty = (i['amount'] as num?)?.toDouble();
      final unitRaw = (i['unit'] as String?)?.trim();
      final unit = (unitRaw == null || unitRaw.isEmpty) ? null : unitRaw;
      final inPantry = canonPantry.any((p) => p['canon'] == name);
      ingr.add(IngredientLine(name: name, qty: qty, unit: unit, inPantry: inPantry));
      if (inPantry && nearExpirySet.contains(name)) usedCanon.add(name);
    }

    // steps (best effort)
    final steps = <String>[];
    final analyzed = r['analyzedInstructions'] as List?;
    if (analyzed != null && analyzed.isNotEmpty) {
      final stepsList = (analyzed.first['steps'] as List?) ?? const [];
      for (final s in stepsList) {
        final txt = (s['step'] ?? '').toString().trim();
        if (txt.isNotEmpty) steps.add(txt);
      }
    }

    // Final preference gate (in case API didn't filter perfectly)
    if (_violatesPrefs(ingr, prefs)) return null;

    // Score (expiry emphasis + coverage)
    final score = _score(ingr, usedCanon);

    return SuggestedRecipe(
      id: 'spoonacular:$id',
      title: title,
      imageUrl: image,
      ingredients: ingr,
      steps: steps,
      servings: servings,
      timeMin: timeMin,
      kcalPerServing: kcal,
      source: 'spoonacular',
      usesExpiring: usedCanon.toSet().toList(),
      score: score,
    );
  }

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
    final expiry = usedExpiring.length.clamp(0, 3) / 3.0; // up to 3 expiring items counted

    // weight: expiry 0.55, coverage 0.30, bias 0.15
    return 0.55 * expiry + 0.30 * coverage + 0.15;
  }

  // Future<List<SuggestedRecipe>> _fallbackAi(...) async { ... }
}
