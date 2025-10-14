// lib/services/recipe_suggest_service.dart
import 'dart:math';
import 'package:collection/collection.dart';

import '../models/pantry_item_model.dart';
import '../models/user_prefs_model.dart';
import '../models/suggested_recipe.dart';
import 'meal_planner.dart'; // Import MealPlanner
import 'normalization.dart';
import 'spoonacular_service.dart';
import 'ai_recipe_service.dart';

// Local copy just for this file (names are local and won't clash with other files)
String _toGenericIngredientLocal(String raw) {
  var s = raw.toLowerCase().trim();
  for (final sep in ['|', '–', '-', '—']) {
    if (s.contains(sep)) s = s.split(sep)[0].trim();
  }
  s = s
      .replaceAll(
          RegExp(r'\b\d+(\.\d+)?\s*(g|kg|ml|l|pcs|pc|pack|packs)\b'), '')
      .trim();
  s = s
      .replaceAll(
          RegExp(
              r'\b(adult|plus|amazing|premium|original|classic|loaf|drink)\b'),
          '')
      .trim();
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

  const canon = {
    'bear brand': 'milk powder',
    'powdered milk': 'milk powder',
    'powdered milk drink': 'milk powder',
    'banana catsup': 'banana ketchup',
    'catsup': 'ketchup',
    'butterscotch': 'bread',
    'butterscotch loaf': 'bread',
    'gardenia': 'bread',
    'loaf': 'bread',
  };
  if (canon.containsKey(s)) return canon[s]!;
  if (s.contains('catsup')) return 'ketchup';
  if (s.contains('ketchup')) return 'banana ketchup';
  if (s.contains('milk')) return 'milk powder';
  if (s.contains('bread')) return 'bread';
  return s;
}

// Accepts nullable name and always returns a non-null String
String _toSpoonNameLocal(String? name) {
  final base = (name ?? '').trim().toLowerCase();
  if (base.isEmpty) return '';
  return _toGenericIngredientLocal(base);
}

// [NEAR_EXPIRY_LOCAL_HELPER] begin
bool _isNearExpiryLocal(DateTime? expiry, {int days = 5}) {
  if (expiry == null) return false;
  final now = DateTime.now();
  if (expiry.isBefore(now)) return false; // already expired
  return expiry.difference(now).inDays <= days;
}
// [NEAR_EXPIRY_LOCAL_HELPER] end

class RecipeSuggestService {
  RecipeSuggestService();
  // No SpoonacularClient needed

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

    // Functions base URL from your deploy output
    const String functionsBase =
        "https://asia-southeast1-<your-project-id>.cloudfunctions.net";
    final spoonClient = SpoonacularService(baseUrl: functionsBase);
    final aiClient = AiRecipeService(baseUrl: functionsBase);

    // Cloud Functions base URL (from deploy)
    const String _functionsBase =
        "https://asia-southeast1-shelfcontrol-8f5ab.cloudfunctions.net";

    // [CALL_GENERATE_FIX] begin
    final localSuggestions = MealPlanner.generate(
        pantry: mealPlannerPantry,
        prefs: prefs,
        limit: limit, // use 'limit', not 'maxResults'
        nearExpiryDays: nearExpiryDays,
        pantryOnly: true, // strict pantry-only instead of 'maxMissing'
        preferNearExpiry: true);
    // optional, hybrid pass
// [CALL_GENERATE_FIX] end
    if (localSuggestions.isNotEmpty) {
      final mapped =
          localSuggestions.map(_mapLocalToSuggested).take(limit).toList();
      return mapped;
    }

    // Spoonacular second pass (only if local is empty and client available)
    // Spoonacular second pass (only if local is empty)
    // Build normalized, generic ingredient names from pantry (null-safe)
    final ingredients = pantry
        .map((p) =>
            _toSpoonNameLocal(p.name)) // p.name may be null; helper handles it
        .where((s) => s.isNotEmpty)
        .toSet()
        .take(40)
        .toList();

    print("[spoon] sending ${ingredients.length} ingredients: $ingredients");

    final found = await spoonClient.findByIngredients(
      ingredients: ingredients,
      number: 24,
      ranking: 1, // maximize used ingredients
    );

    print("[spoon] found=${found.length}");

    /// allow common “staples” to be missing
    const stapleSet = {
      'water',
      'salt',
      'pepper',
      'black pepper',
      'oil',
      'cooking oil',
      'olive oil',
      'vegetable oil',
      'canola oil'
    };

    final strict = found.where((m) {
      final missed = (m['missedIngredients'] as List?) ?? const [];
      for (final x in missed) {
        final name = (x is Map && x['name'] != null)
            ? x['name'].toString().toLowerCase()
            : '';
        if (name.isEmpty) return false;
        if (!stapleSet.contains(name)) return false;
      }
      return true;
    }).toList();

    print("[spoon] strict=${strict.length}");

    if (strict.isNotEmpty) {
      // hydrate details
      final hydrated = <Map<String, dynamic>>[];
      for (final m in strict.take(limit * 2)) {
        final id = m['id'] as int?;
        if (id == null) continue;
        try {
          final info = await spoonClient.getRecipeInfo(id: id);
          hydrated.add({'find': m, 'info': info});
        } catch (_) {
          // skip bad ids
        }
      }

      final mapped = hydrated
          .map((h) => _mapSpoonacularToSuggested(
                h,
                nearExpiryDays: nearExpiryDays,
                pantry: pantry,
              ))
          .toList();

      // sort: more near-expiry hits first, then shorter time
      mapped.sort((a, b) {
        final aExp = a.usesExpiring.length, bExp = b.usesExpiring.length;
        if (aExp != bExp) return bExp.compareTo(aExp);
        final at = a.timeMin ?? 9999, bt = b.timeMin ?? 9999;
        return at.compareTo(bt);
      });

      if (mapped.isNotEmpty) {
        final sliced = mapped.take(limit).toList();
        final enhanced = await aiClient.enhance(sliced, locale: 'en-PH');
        return enhanced;
      }
    }

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

    // Gemini fallback if both local and spoonacular returned nothing
    // Gemini fallback if both local and spoonacular returned nothing
    final pantryNames = pantry
        .map((p) => (p.name ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toList();

// If you later add fields on UserPrefs, populate this map accordingly.
// For now, keep it empty so we don't depend on non-existent getters.
    final Map<String, dynamic> prefsPayload = <String, dynamic>{};

    final aiList = await aiClient.suggestFromPantry(
      pantryNames: pantryNames,
      prefs: prefsPayload,
      nearExpiryDays: nearExpiryDays,
    );

    if (aiList.isNotEmpty) {
      return aiList.take(limit).toList();
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
// Builds SuggestedRecipe from a { find, info } pair
  SuggestedRecipe _mapSpoonacularToSuggested(
    Map<String, dynamic> h, {
    required int nearExpiryDays,
    required List<PantryItemModel> pantry,
  }) {
    final find = h['find'] as Map<String, dynamic>;
    final info = h['info'] as Map<String, dynamic>;

    final title = (info['title'] ?? find['title'] ?? '').toString();
    final image = (info['image'] ?? find['image'])?.toString();
    final servings = (info['servings'] as num?)?.toInt();
    final readyInMinutes = (info['readyInMinutes'] as num?)?.toInt();

    // Ingredients from info.extendedIngredients if present; else from find.usedIngredients
    final List ingredientsRaw = (info['extendedIngredients'] as List?) ??
        (find['usedIngredients'] as List? ?? const []);

    final ingredientLines = ingredientsRaw.map((e) {
      final m = e as Map<String, dynamic>;
      final name =
          (m['name'] ?? m['originalName'] ?? m['aisle'] ?? '').toString();
      final amount = (m['amount'] as num?)?.toDouble();
      final unit = (m['unit'] ?? '').toString();
      // Pantry-only pass means everything used should be in pantry
      return IngredientLine(
        name: name,
        qty: amount,
        unit: unit.isEmpty ? null : unit,
        inPantry: true,
      );
    }).toList();

    // Steps (if analyzedInstructions present)
    final steps = <String>[];
    final List instructions =
        (info['analyzedInstructions'] as List?) ?? const [];
    if (instructions.isNotEmpty) {
      final first = instructions.first as Map<String, dynamic>;
      final List st = (first['steps'] as List?) ?? const [];
      for (final s in st) {
        final sm = s as Map<String, dynamic>;
        steps.add((sm['step'] ?? '').toString());
      }
    }

    // Estimate kcal if available
    int? kcal;
    final nutrition = info['nutrition'];
    if (nutrition is Map && nutrition['nutrients'] is List) {
      final nutrients = nutrition['nutrients'] as List;
      final cal = nutrients.cast<Map<String, dynamic>>().firstWhere(
            (n) => (n['name'] as String?)?.toLowerCase() == 'calories',
            orElse: () => const {},
          );
      final val = cal['amount'];
      if (val is num) kcal = val.toInt();
    }

    // Compute “usesExpiring” from pantry expiry windows
    final pantryByName = {
      for (final p in pantry) normalizeName(p.name): p,
    };
    final usesExpiring = <String>[];
    for (final ing in ingredientLines) {
      final key = normalizeName(ing.name);
      final p = pantryByName[key];
      if (p != null) {
        final exp = p.expirationDate;
        if (exp != null) {
          final now = DateTime.now();
          if (!exp.isBefore(now) &&
              exp.difference(now).inDays <= nearExpiryDays) {
            usesExpiring.add(ing.name);
          }
        }
      }
    }

    return SuggestedRecipe(
      id: title.isEmpty
          ? 'spoon_${find['id']}'
          : title.replaceAll(' ', '_').toLowerCase(),
      title: title,
      imageUrl: image,
      ingredients: ingredientLines,
      steps: steps,
      servings: servings,
      timeMin: readyInMinutes,
      kcalPerServing: kcal,
      source: 'spoonacular',
      usesExpiring: usesExpiring,
      missingIngredients: const [], // strict pantry-only in this pass
      score: 1.0,
    );
  }

  SuggestedRecipe _mapLocalToSuggested(RecipeSuggestion s) {
    final ingr = (s.ingredients as List).map((e) {
      final m = e as Map<String, dynamic>;
      final name = (m['name'] ?? '').toString();

      final qtyRaw = m['qty'];
      double? qty;
      if (qtyRaw is num) qty = qtyRaw.toDouble();
      if (qty == null && qtyRaw is String) {
        qty = double.tryParse(qtyRaw.replaceAll(RegExp(r'[^0-9.]'), ''));
      }

      final unit = (m['unit'] ?? '').toString();

      return IngredientLine(
        name: name,
        qty: qty,
        unit: unit.isEmpty ? null : unit,
        inPantry: true,
      );
    }).toList();

    final steps = (s.directions is List)
        ? (s.directions as List).map((x) => x.toString()).toList()
        : <String>[];

    final servings = int.tryParse(
        (s.servingSize ?? '').toString().replaceAll(RegExp(r'[^0-9]'), ''));
    final timeMin = int.tryParse(
        (s.time ?? '').toString().replaceAll(RegExp(r'[^0-9]'), ''));
    final kcal = int.tryParse(
        (s.calories ?? '').toString().replaceAll(RegExp(r'[^0-9]'), ''));

    final id = s.name.replaceAll(' ', '_').toLowerCase();

    return SuggestedRecipe(
      id: id,
      title: s.name,
      imageUrl: s.imageUrl,
      ingredients: ingr,
      steps: steps,
      servings: servings,
      timeMin: timeMin,
      kcalPerServing: kcal,
      source: 'local',
      usesExpiring: const [],
      missingIngredients: const [],
      score: 1.0,
    );
  }

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
