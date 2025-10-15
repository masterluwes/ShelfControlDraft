// lib/services/meal_planner.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelf_control/models/user_prefs_model.dart';

class PantryItem {
  final String name; // normalized lower-case
  final int qty; // quantity available
  final DateTime? expiryAt; // nullable
  final bool consumed; // default false
  final bool nearExpiry; // computed

  PantryItem({
    required this.name,
    required this.qty,
    required this.expiryAt,
    required this.consumed,
    required this.nearExpiry,
  });
}

class RecipeSuggestion {
  final String name;
  final String imageUrl;
  final String servingSize; // string for UI
  final String calories; // e.g. "520 kcal"
  final String time; // e.g. "25 minutes"
  final String description;
  final List<Map<String, String>> ingredients; // [{name, amount}]
  final List<String> directions;

  RecipeSuggestion({
    required this.name,
    required this.imageUrl,
    required this.servingSize,
    required this.calories,
    required this.time,
    required this.description,
    required this.ingredients,
    required this.directions,
  });
}

// [NEAR_EXPIRY_WINDOW] begin
bool _isNearExpiry(DateTime? expiry, {int days = 5}) {
  if (expiry == null) return false;
  final now = DateTime.now();
  if (expiry.isBefore(now)) return false; // already expired
  return expiry.difference(now).inDays <= days;
}
// [NEAR_EXPIRY_WINDOW] end


// [MEAL_PRIORITY_NEAR_EXPIRY] begin
double _nearExpiryScoreBump(
  Iterable<String> usedIngredients,
  Map<String, DateTime?> expiryMap, {
  int days = 5,
  double perItem = 2.0,
}) {
  int count = 0;
  for (final ing in usedIngredients) {
    final exp = expiryMap[ing];
    if (_isNearExpiry(exp, days: days)) count++;
  }
  return count * perItem;
}
// [MEAL_PRIORITY_NEAR_EXPIRY] end

class MealPlanner {
  // --- knobs ---
  static const int defaultNearExpiryDays = 5;
  static const int defaultMaxMissing = 2;
  static const int defaultMaxResults = 12;

  // Staples ignored when counting "missing"
  static const Set<String> _staples = {
    'salt',
    'pepper',
    'oil',
    'olive oil',
    'sugar',
    'soy sauce',
    'vinegar',
    'garlic powder',
    'onion powder',
    'chili flakes',
    'water'
  };

  // Items we consider "not pantry-only" (won’t block, but counted as missing)
  static const Set<String> _blocklistFreshOrFrozen = {
    'chicken',
    'pork',
    'beef',
    'fish fillet',
    'egg',
    'fresh tomato',
    'spinach',
    'lettuce',
    'carrot',
    'onion fresh',
    'garlic fresh',
    'milk',
    'butter',
    'cheese fresh'
  };

  // More granular shelf lives for specific subcategories/keywords (copied from addpantryitem.dart)
  static final Map<String, Map<String, int>> _subcategoryShelfLives = {
    'Bakery': {
      'bread': 7,
      'cake': 7,
      'pastries': 7,
      'buns': 7,
      'muffin': 7,
      'donut': 3,
      'pandesal': 7,
      'ensaymada': 7,
      'mamon': 7,
    },
    'Dairy': {
      'fresh milk': 7,
      'powdered milk': 270,
      'cheese': 60,
      'yogurt': 21,
      'butter': 90,
      'eggs': 30,
    },
    'Beverages': {
      'fresh juice': 7,
      'uht milk': 270,
      'coffee': 365,
      'tea': 730,
      'soda': 180,
      'water': 730,
    },
    'Condiments': {
      'vinegar': 730,
      'soy sauce': 365,
      'ketchup': 365,
      'mustard': 365,
      'dressing': 180,
      'spices': 730,
      'powder': 730,
      'salt': 1825,
    },
    'Dry Goods': {
      'rice': 730,
      'pasta': 730,
      'flour': 180,
      'cereal': 180,
      'oil': 365,
      'beans': 730,
      'sugar': 1825,
    },
    'Snacks': {
      'chips': 90,
      'crackers': 180,
      'cookies': 180,
      'chocolates': 270,
      'biscuits': 180,
      'packed fudge bars': 180,
    }
  };

  // Simple name normalization
  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9 ]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static bool _matchHas(Map<String, int> pantryIndex, String want) {
    // contains-style match: if any pantry key contains the want fragment
    for (final k in pantryIndex.keys) {
      if (k.contains(want)) return true;
    }
    return false;
  }

  // Map ingredient name to a broader category for rule matching
  static String _getCategoryForIngredient(String ingredientName) {
    final name = _norm(ingredientName);
    if (name.contains('bread') ||
        name.contains('cake') ||
        name.contains('pastries') ||
        name.contains('buns') ||
        name.contains('muffin') ||
        name.contains('donut') ||
        name.contains('pandesal') ||
        name.contains('ensaymada') ||
        name.contains('mamon')) {
      return 'Bakery';
    }
    if (name.contains('milk') ||
        name.contains('yogurt') ||
        name.contains('cheese') ||
        name.contains('butter') ||
        name.contains('eggs')) {
      return 'Dairy';
    }
    if (name.contains('coffee') ||
        name.contains('tea') ||
        name.contains('juice') ||
        name.contains('soda') ||
        name.contains('water')) {
      return 'Beverages';
    }
    if (name.contains('canned') ||
        name.contains('tuna') ||
        name.contains('sardines') ||
        name.contains('corned beef') ||
        name.contains('meat loaf') ||
        name.contains('luncheon meat')) {
      return 'Canned Protein'; // Specific category for canned meats
    }
    if (name.contains('rice') ||
        name.contains('pasta') ||
        name.contains('flour') ||
        name.contains('cereal') ||
        name.contains('noodles') ||
        name.contains('oats') ||
        name.contains('sugar')) {
      return 'Staple Carb';
    }
    if (name.contains('chips') ||
        name.contains('crackers') ||
        name.contains('cookies') ||
        name.contains('nuts') ||
        name.contains('candies') ||
        name.contains('chocolates') ||
        name.contains('biscuits')) {
      return 'Snacks';
    }
    if (name.contains('vinegar') ||
        name.contains('soy sauce') ||
        name.contains('ketchup') ||
        name.contains('mustard') ||
        name.contains('dressing') ||
        name.contains('sauce') ||
        name.contains('spices') ||
        name.contains('salt') ||
        name.contains('garlic powder') ||
        name.contains('onion powder') ||
        name.contains('chili flakes')) {
      return 'Condiment';
    }
    if (name.contains('garlic') || name.contains('onion')) {
      // For fresh garlic/onion, if they are ever added
      return 'Aromatic';
    }
    if (name.contains('tomato') ||
        name.contains('spinach') ||
        name.contains('lettuce') ||
        name.contains('carrot') ||
        name.contains('peas')) {
      return 'Vegetable (Canned)'; // For canned vegetables
    }
    if (name.contains('sweetener')) {
      return 'Sweetener';
    }
    return 'Other';
  }

  /// Build PantryItem list from Firestore docs (defensive: supports 'qty' or 'quantity';
  /// 'expiryAt' or 'expirationDate'; Timestamp or ISO string).
  static List<PantryItem> fromSnapshot(QuerySnapshot snap,
      {int nearExpiryDays = defaultNearExpiryDays}) {
    final now = DateTime.now();
    final items = <PantryItem>[];
    for (final d in snap.docs) {
      final data = d.data() as Map<String, dynamic>? ?? {};
      final rawName = (data['name'] ?? '').toString();
      if (rawName.trim().isEmpty) continue;

      final name = _norm(rawName);
      final qty = (data['qty'] ?? data['quantity'] ?? 0) is int
          ? (data['qty'] ?? data['quantity'] ?? 0) as int
          : int.tryParse((data['qty'] ?? data['quantity'] ?? '0').toString()) ??
              0;

      final consumed =
          (data['consumed'] ?? false) == true || (data['status'] == 'Deleted');

      DateTime? expiryAt;
      final ex = data['expiryAt'] ?? data['expirationDate'];
      if (ex is Timestamp) {
        expiryAt = ex.toDate();
      } else if (ex is String && ex.trim().isNotEmpty) {
        expiryAt = DateTime.tryParse(ex);
      }

      final expired = expiryAt != null && expiryAt.isBefore(now);
      if (consumed || expired || qty <= 0) continue;

      final near = expiryAt != null &&
          expiryAt.isBefore(now.add(Duration(days: nearExpiryDays)));
      items.add(PantryItem(
        name: name,
        qty: qty,
        expiryAt: expiryAt,
        consumed: false,
        nearExpiry: near,
      ));
    }
    return items;
  }

  // A tiny rule DSL
  // Each rule defines a "pantry-only" meal with required and optional ingredients.
  // We keep it generic so you can expand later.
  static final List<_Rule> _rules = [
    // --- Existing rules adapted to new structure ---
    _Rule(
      id: 'tuna_pasta',
      titleTemplate: 'Tuna Pantry Pasta',
      imageUrl:
          'https://images.unsplash.com/photo-1523986371872-9d3ba2e2f642?q=80&w=1200',
      requiredIngredients: {'pasta', 'tuna'},
      optionalIngredients: {
        'olive oil',
        'oil',
        'garlic powder',
        'soy sauce',
        'chili flakes'
      },
      baseTimeMin: 20,
      baseKcalPerServing: 520,
      servings: 2,
      descriptionTemplate: 'Quick pantry pasta using canned tuna and staples.',
      stepsTemplate: [
        'Boil pasta in salted water until al dente.',
        'Warm oil in a pan, add tuna and seasonings.',
        'Add a splash of pasta water and toss pasta in the pan.',
        'Season to taste and serve hot.',
      ],
      aliases: {'canned tuna': 'tuna'},
    ),
    _Rule(
      id: 'sardines_pasta',
      titleTemplate: 'Sardines Aglio e Olio',
      imageUrl:
          'https://images.unsplash.com/photo-1512058564366-18510be2db19?q=80&w=1200',
      requiredIngredients: {'pasta', 'sardines'},
      optionalIngredients: {
        'olive oil',
        'oil',
        'garlic powder',
        'chili flakes'
      },
      baseTimeMin: 18,
      baseKcalPerServing: 500,
      servings: 2,
      descriptionTemplate:
          'Spicy garlic oil pasta upgraded with canned sardines.',
      stepsTemplate: [
        'Cook pasta until al dente.',
        'Sauté oil with garlic powder and chili flakes.',
        'Fold in sardines, add pasta and a bit of pasta water.',
        'Toss to coat and serve.',
      ],
      aliases: {'canned sardines': 'sardines'},
    ),
    _Rule(
      id: 'fried_rice',
      titleTemplate: 'Pantry Fried Rice',
      imageUrl:
          'https://images.unsplash.com/photo-1598866594230-a7c12756260c?q=80&w=1200',
      requiredIngredients: {'rice', 'soy sauce'},
      optionalIngredients: {
        'corned beef',
        'tuna',
        'sardines',
        'garlic powder',
        'onion powder'
      },
      baseTimeMin: 15,
      baseKcalPerServing: 480,
      servings: 2,
      descriptionTemplate: 'Fried rice using shelf-stable add-ins.',
      stepsTemplate: [
        'Heat oil in a pan.',
        'Add canned add-ins and dry aromatics.',
        'Add rice and soy sauce, stir-fry until heated through.',
        'Adjust seasoning and serve.',
      ],
      aliases: {'canned corned beef': 'corned beef'},
    ),
    _Rule(
      id: 'rice_beans',
      titleTemplate: 'Rice & Beans Bowl',
      imageUrl:
          'https://images.unsplash.com/photo-1568605114967-8130f3a36994?q=80&w=1200',
      requiredIngredients: {'rice', 'beans'},
      optionalIngredients: {
        'soy sauce',
        'chili flakes',
        'garlic powder',
        'oil'
      },
      baseTimeMin: 20,
      baseKcalPerServing: 520,
      servings: 2,
      descriptionTemplate:
          'Hearty rice and canned beans with pantry seasonings.',
      stepsTemplate: [
        'Warm beans in a pot with seasonings.',
        'Stir through cooked rice.',
        'Finish with soy sauce or chili flakes to taste.',
        'Serve hot.',
      ],
      aliases: {
        'canned beans': 'beans',
        'kidney beans': 'beans',
        'baked beans': 'beans'
      },
    ),
    _Rule(
      id: 'garlic_oil_pasta',
      titleTemplate: 'Garlic Oil Pasta (Pantry)',
      imageUrl:
          'https://images.unsplash.com/photo-1526318472351-c75fcf070305?q=80&w=1200',
      requiredIngredients: {'pasta', 'oil'},
      optionalIngredients: {'garlic powder', 'chili flakes', 'soy sauce'},
      baseTimeMin: 12,
      baseKcalPerServing: 480,
      servings: 2,
      descriptionTemplate: 'Simple garlic oil pasta using shelf-seasonings.',
      stepsTemplate: [
        'Cook pasta in salted water.',
        'Warm oil with garlic powder and chili.',
        'Toss pasta with the oil and a splash of pasta water.',
        'Season and serve.',
      ],
    ),
    _Rule(
      id: 'noodles_upgrade',
      titleTemplate: 'Upgraded Instant Noodles',
      imageUrl:
          'https://images.unsplash.com/photo-1551183053-bf91a1d81141?q=80&w=1200',
      requiredIngredients: {'instant noodles'},
      optionalIngredients: {
        'corned beef',
        'tuna',
        'sardines',
        'soy sauce',
        'garlic powder',
        'chili flakes'
      },
      baseTimeMin: 8,
      baseKcalPerServing: 430,
      servings: 1,
      descriptionTemplate: 'Instant noodles boosted with canned add-ins.',
      stepsTemplate: [
        'Cook noodles per instructions.',
        'Stir in canned add-ins and seasonings.',
        'Serve hot.',
      ],
      aliases: {'ramen': 'instant noodles'},
    ),
    // --- New rules for dynamic meal ideas (Filipino hacks, supermarket focus) ---
    _Rule(
      id: 'breakfast_combo_fast_expiring',
      titleTemplate: '{Bakery Item} with {Dairy Item}',
      imageUrl:
          'https://images.unsplash.com/photo-1583339752135-c1923795795e?q=80&w=1200', // Generic breakfast image
      requiredCategories: {'Bakery', 'Dairy'},
      optionalCategories: {'Sweetener'},
      baseTimeMin: 5,
      baseKcalPerServing: 300,
      servings: 1,
      descriptionTemplate:
          'A quick Filipino breakfast to use up expiring items.',
      stepsTemplate: [
        'Serve {Bakery Item} with {Dairy Item}.',
        'Add {Sweetener} if desired.',
      ],
    ),
    _Rule(
      id: 'ginisang_canned_goods',
      titleTemplate: 'Ginisang {Canned Protein}',
      imageUrl:
          'https://images.unsplash.com/photo-1621996383325-e477b1b7f8b7?q=80&w=1200', // Generic Filipino dish image
      requiredCategories: {'Canned Protein', 'Aromatic'},
      optionalCategories: {'Vegetable (Canned)', 'Condiment', 'Staple Carb'},
      baseTimeMin: 15,
      baseKcalPerServing: 450,
      servings: 2,
      descriptionTemplate:
          'A classic Filipino sautéed dish using pantry staples.',
      stepsTemplate: [
        'Sauté {Aromatic}.',
        'Add {Canned Protein} and {Vegetable (Canned)} if available.',
        'Season with {Condiment} and serve with {Staple Carb} if available.',
      ],
      aliases: {
        'canned tuna': 'tuna',
        'canned sardines': 'sardines',
        'canned corned beef': 'corned beef'
      },
    ),
    _Rule(
      id: 'instant_noodle_boost',
      titleTemplate: 'Upgraded {Instant Noodles}',
      imageUrl:
          'https://images.unsplash.com/photo-1551183053-bf91a1d81141?q=80&w=1200', // Instant noodles image
      requiredCategories: {'Instant Noodles'},
      optionalCategories: {'Egg', 'Canned Protein', 'Spice'},
      baseTimeMin: 8,
      baseKcalPerServing: 430,
      servings: 1,
      descriptionTemplate: 'Elevate your instant noodles with pantry add-ins.',
      stepsTemplate: [
        'Cook {Instant Noodles} per package instructions.',
        'Stir in {Egg} and {Canned Protein} if available.',
        'Season with {Spice} if available.',
        'Serve hot.',
      ],
      aliases: {'ramen': 'instant noodles'},
    ),
  ];

  /// Generate suggestions from pantry items (pure local rules).
  // [GENERATE_SIGNATURE] begin
  static List<RecipeSuggestion> generate({
    required List<PantryItem> pantry,
    required UserPrefs prefs,
    int limit = 12,
    int nearExpiryDays = 5,
    bool pantryOnly = false,
    bool preferNearExpiry = false,
    Map<String, DateTime?>? expiryMap,
  }) {
    // [LOOKUPS_INIT] begin
    final Set<String> pantryNames = {
      for (final p in pantry) p.name, // normalizeName already baked into p.name
    };

    final Map<String, DateTime?> expMap = expiryMap ??
        {
          for (final p in pantry) p.name: p.expiryAt,
        };
// [LOOKUPS_INIT] end

    final now = DateTime.now();
    final atRiskDays = 2; // Define "at-risk" as expiring within 2 days

    // Build a lookup: normalized name -> PantryItem
    final pantryMap = <String, PantryItem>{};
    for (final p in pantry) {
      pantryMap[p.name] = p;
    }

    // Build a lookup: normalized name -> qty
    final pantryIndex = <String, int>{};
    for (final p in pantry) {
      pantryIndex[p.name] = (pantryIndex[p.name] ?? 0) + p.qty;
    }

    // Map categories to available ingredients
    final pantryCategoryMap = <String, List<String>>{};
    for (final p in pantry) {
      final category = _getCategoryForIngredient(p.name);
      pantryCategoryMap.update(category, (list) => list..add(p.name),
          ifAbsent: () => [p.name]);
    }

    final results = <({
      RecipeSuggestion s,
      int score,
      int missingCount,
      List<String> missingIngredients
    })>[];

    for (final rule in _rules) {
      final matchedIngredients =
          <String, String>{}; // Placeholder -> actual ingredient
      final currentMissing = <String>[];
      var currentNearHits = 0;
      var currentAtRiskHits = 0;
      var categoryExpiryScore = 0;

      // --- Check required specific ingredients ---
      for (final reqIng in rule.requiredIngredients) {
        final normalizedReqIng = _norm(reqIng);
        if (_matchHas(pantryIndex, normalizedReqIng)) {
          // Find the actual pantry item that matches
          final actualItem = pantryMap.values.firstWhere(
              (p) =>
                  _norm(p.name).contains(normalizedReqIng) ||
                  normalizedReqIng.contains(_norm(p.name)),
              orElse: () => PantryItem(
                  name: '',
                  qty: 0,
                  consumed: false,
                  nearExpiry: false,
                  expiryAt: null));
          if (actualItem.name.isNotEmpty) {
            matchedIngredients[reqIng] = actualItem.name;
            if (actualItem.nearExpiry) currentNearHits++;
            if (actualItem.expiryAt != null &&
                actualItem.expiryAt!
                    .isBefore(now.add(Duration(days: atRiskDays)))) {
              currentAtRiskHits++;
            }
          }
        } else {
          currentMissing.add(reqIng);
        }
      }

      // --- Check required categories ---
      for (final reqCat in rule.requiredCategories) {
        if (pantryCategoryMap.containsKey(reqCat) &&
            pantryCategoryMap[reqCat]!.isNotEmpty) {
          // Pick one available ingredient from the category, prioritize expiring/at-risk
          String? bestMatch;
          int bestScore = -1; // Higher score is better

          for (final ingName in pantryCategoryMap[reqCat]!) {
            final item = pantryMap[ingName];
            if (item != null) {
              int score = 0;
              if (item.nearExpiry) score += 1;
              if (item.expiryAt != null &&
                  item.expiryAt!
                      .isBefore(now.add(Duration(days: atRiskDays)))) {
                score += 2; // Higher score for at-risk
              }
              if (score > bestScore) {
                bestScore = score;
                bestMatch = ingName;
              }
            }
          }
          if (bestMatch != null) {
            matchedIngredients[reqCat] = bestMatch;
            final item = pantryMap[bestMatch]!;
            if (item.nearExpiry) currentNearHits++;
            if (item.expiryAt != null &&
                item.expiryAt!.isBefore(now.add(Duration(days: atRiskDays)))) {
              currentAtRiskHits++;
            }
            // Add to category expiry score
            final categoryShelfLife =
                _subcategoryShelfLives[reqCat]?[_norm(bestMatch)];
            if (categoryShelfLife != null && item.expiryAt != null) {
              final daysRemaining = item.expiryAt!.difference(now).inDays;
              if (daysRemaining <= categoryShelfLife ~/ 2) {
                // If less than half shelf life remaining
                categoryExpiryScore++;
              }
            }
          } else {
            currentMissing.add(reqCat);
          }
        } else {
          currentMissing.add(reqCat);
        }
      }

      if (pantryOnly && currentMissing.isNotEmpty) continue;

      // --- Collect optional ingredients/categories that are present ---
      final availableOptionalIngredients = <String>[];
      for (final optIng in rule.optionalIngredients) {
        final normalizedOptIng = _norm(optIng);
        if (_matchHas(pantryIndex, normalizedOptIng)) {
          final actualItem = pantryMap.values.firstWhere(
              (p) =>
                  _norm(p.name).contains(normalizedOptIng) ||
                  normalizedOptIng.contains(_norm(p.name)),
              orElse: () => PantryItem(
                  name: '',
                  qty: 0,
                  consumed: false,
                  nearExpiry: false,
                  expiryAt: null));
          if (actualItem.name.isNotEmpty) {
            availableOptionalIngredients.add(actualItem.name);
            if (actualItem.nearExpiry) currentNearHits++;
            if (actualItem.expiryAt != null &&
                actualItem.expiryAt!
                    .isBefore(now.add(Duration(days: atRiskDays)))) {
              currentAtRiskHits++;
            }
          }
        }
      }
      for (final optCat in rule.optionalCategories) {
        if (pantryCategoryMap.containsKey(optCat) &&
            pantryCategoryMap[optCat]!.isNotEmpty) {
          // Pick one available ingredient from the category
          String? bestMatch;
          int bestScore = -1;

          for (final ingName in pantryCategoryMap[optCat]!) {
            final item = pantryMap[ingName];
            if (item != null) {
              int score = 0;
              if (item.nearExpiry) score += 1;
              if (item.expiryAt != null &&
                  item.expiryAt!
                      .isBefore(now.add(Duration(days: atRiskDays)))) {
                score += 2;
              }
              if (score > bestScore) {
                bestScore = score;
                bestMatch = ingName;
              }
            }
          }
          if (bestMatch != null) {
            availableOptionalIngredients.add(bestMatch);
            final item = pantryMap[bestMatch]!;
            if (item.nearExpiry) currentNearHits++;
            if (item.expiryAt != null &&
                item.expiryAt!.isBefore(now.add(Duration(days: atRiskDays)))) {
              currentAtRiskHits++;
            }
            final categoryShelfLife =
                _subcategoryShelfLives[optCat]?[_norm(bestMatch)];
            if (categoryShelfLife != null && item.expiryAt != null) {
              final daysRemaining = item.expiryAt!.difference(now).inDays;
              if (daysRemaining <= categoryShelfLife ~/ 2) {
                categoryExpiryScore++;
              }
            }
          }
        }
      }

      // --- Dynamic Template Filling ---
      String filledTitle = rule.titleTemplate;
      String filledDescription = rule.descriptionTemplate;
      List<String> filledSteps = List.from(rule.stepsTemplate);
      final ingredientsList = <Map<String, String>>[];

      // Combine all used ingredients for display
      final allUsedIngredients = <String>{};
      matchedIngredients.forEach((placeholder, actualIng) {
        allUsedIngredients.add(actualIng);
        filledTitle = filledTitle.replaceAll('{$placeholder}', actualIng);
        filledDescription =
            filledDescription.replaceAll('{$placeholder}', actualIng);
        filledSteps = filledSteps
            .map((step) => step.replaceAll('{$placeholder}', actualIng))
            .toList();
      });
      for (final optIng in availableOptionalIngredients) {
        allUsedIngredients.add(optIng);
      }

      for (final ingName in allUsedIngredients) {
        ingredientsList.add({
          'name': ingName,
          'amount': ''
        }); // Amount can be added if rules specify
      }

      // Final score calculation
      // Prioritize: (1) At-risk items, (2) Near-expiry items, (3) Fast-expiring categories, (4) Fewer missing
      int score = 0;
      score += currentAtRiskHits * 1000; // High weight for at-risk
      score += currentNearHits * 100; // Medium weight for near-expiry
      score += categoryExpiryScore * 50; // Weight for fast-expiring categories
      score -= currentMissing.length * 10; // Penalty for missing ingredients

      if (preferNearExpiry) {
        // allUsedIngredients is already built above; expMap & nearExpiryDays are in scope
        final bump = _nearExpiryScoreBump(allUsedIngredients, expMap,
            days: nearExpiryDays);
        score += bump.toInt(); // cast double -> int to match your score type
      }

      final s = RecipeSuggestion(
        name: filledTitle,
        imageUrl: rule.imageUrl,
        servingSize: rule.servings.toString(),
        calories: '${rule.baseKcalPerServing} kcal',
        time: '${rule.baseTimeMin} minutes',
        description: filledDescription,
        ingredients: ingredientsList,
        directions: filledSteps,
      );

      results.add((
        s: s,
        score: score,
        missingCount: currentMissing.length,
        missingIngredients: currentMissing
      ));
    }

    // Rank: (1) higher score, (2) fewer missing
    results.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.missingCount.compareTo(b.missingCount);
    });

    return results.take(limit).map((e) => e.s).toList();
  }
}

class _Rule {
  final String id;
  final String titleTemplate; // Use template for dynamic titles
  final String imageUrl;
  final Set<String> requiredIngredients; // Specific ingredients
  final Set<String> optionalIngredients; // Specific ingredients
  final Set<String> requiredCategories; // Categories of ingredients
  final Set<String> optionalCategories; // Categories of ingredients
  final int baseTimeMin;
  final int baseKcalPerServing;
  final int servings;
  final String descriptionTemplate; // Use template for dynamic descriptions
  final List<String> stepsTemplate; // Use template for dynamic steps
  final Map<String, String> aliases; // 'canned tuna' -> 'tuna'

  _Rule({
    required this.id,
    required this.titleTemplate,
    required this.imageUrl,
    this.requiredIngredients = const {},
    this.optionalIngredients = const {},
    this.requiredCategories = const {},
    this.optionalCategories = const {},
    required this.baseTimeMin,
    required this.baseKcalPerServing,
    required this.servings,
    required this.descriptionTemplate,
    required this.stepsTemplate,
    this.aliases = const {},
  });
}
