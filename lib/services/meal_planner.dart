// lib/services/meal_planner.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'spoonacular_service.dart';
import 'ai_completion_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PantryItem {
  final String name; // normalized lower-case
  final int qty; // quantity available
  final String category;
  final DateTime? expiryAt; // nullable
  final bool consumed; // default false
  final bool nearExpiry; // computed
   // e.g., "Canned Goods", "Grains"

  PantryItem({
    required this.name,
    required this.qty,
    required this.category,
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
  final String difficulty; // e.g. "Easy", "Moderate", "Hard"

  RecipeSuggestion({
    required this.name,
    required this.imageUrl,
    required this.servingSize,
    required this.calories,
    required this.time,
    required this.description,
    required this.ingredients,
    required this.directions,
    required this.difficulty,
  });
}

class MealFilters {
  final int maxCookMinutes; // per recipe
  final int allowMissing; // 0..2
  final int servings; // for display only
  final List<String> allergens; // e.g., ["peanut","shellfish"]
  final List<String> dislikes; // e.g., ["cilantro"]
  final bool prioritizeNearExpiry;

  const MealFilters({
    this.maxCookMinutes = 45,
    this.allowMissing = 2,
    this.servings = 2,
    this.allergens = const [],
    this.dislikes = const [],
    this.prioritizeNearExpiry = true,
  });
}

class MealPlanner {
  // --- knobs ---
  static const int defaultNearExpiryDays = 5;
  static const int defaultMaxMissing = 2;
  static const int defaultMaxResults = 12;

  static Future<List<RecipeSuggestion>> generateHybrid({
    required String householdId,
    required List<PantryItem> pantry,
    int apiCount = 10,
    bool addNutrition = false,
  }) async {
    // Temporary fallback for debugging
    return generate(
      pantry: pantry,
      nearExpiryDays: defaultNearExpiryDays,
      maxMissing: defaultMaxMissing,
      maxResults: defaultMaxResults,
    );
  }

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
        category: 'Uncategorized',
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
    _Rule(
      id: 'tuna_pasta',
      title: 'Tuna Pantry Pasta',
      imageUrl:
          'https://images.unsplash.com/photo-1523986371872-9d3ba2e2f642?q=80&w=1200',
      required: {'pasta', 'tuna'}, // canned tuna matched via "tuna"
      optional: {
        'olive oil',
        'oil',
        'garlic powder',
        'soy sauce',
        'chili flakes'
      },
      baseTimeMin: 20,
      baseKcalPerServing: 520,
      servings: 2,
      descriptionTmpl: 'Quick pantry pasta using canned tuna and staples.',
      steps: [
        'Boil pasta in salted water until al dente.',
        'Warm oil in a pan, add tuna and seasonings.',
        'Add a splash of pasta water and toss pasta in the pan.',
        'Season to taste and serve hot.',
      ],
      aliases: {'canned tuna': 'tuna'},
    ),
    _Rule(
      id: 'sardines_pasta',
      title: 'Sardines Aglio e Olio',
      imageUrl:
          'https://images.unsplash.com/photo-1512058564366-18510be2db19?q=80&w=1200',
      required: {'pasta', 'sardines'},
      optional: {'olive oil', 'oil', 'garlic powder', 'chili flakes'},
      baseTimeMin: 18,
      baseKcalPerServing: 500,
      servings: 2,
      descriptionTmpl: 'Spicy garlic oil pasta upgraded with canned sardines.',
      steps: [
        'Cook pasta until al dente.',
        'Sauté oil with garlic powder and chili flakes.',
        'Fold in sardines, add pasta and a bit of pasta water.',
        'Toss to coat and serve.',
      ],
      aliases: {'canned sardines': 'sardines'},
    ),
    _Rule(
      id: 'fried_rice',
      title: 'Pantry Fried Rice',
      imageUrl:
          'https://images.unsplash.com/photo-1598866594230-a7c12756260c?q=80&w=1200',
      required: {'rice', 'soy sauce'},
      optional: {
        'corned beef',
        'tuna',
        'sardines',
        'garlic powder',
        'onion powder'
      },
      baseTimeMin: 15,
      baseKcalPerServing: 480,
      servings: 2,
      descriptionTmpl: 'Fried rice using shelf-stable add-ins.',
      steps: [
        'Heat oil in a pan.',
        'Add canned add-ins and dry aromatics.',
        'Add rice and soy sauce, stir-fry until heated through.',
        'Adjust seasoning and serve.',
      ],
      aliases: {'canned corned beef': 'corned beef'},
    ),
    _Rule(
      id: 'rice_beans',
      title: 'Rice & Beans Bowl',
      imageUrl:
          'https://images.unsplash.com/photo-1568605114967-8130f3a36994?q=80&w=1200',
      required: {'rice', 'beans'}, // canned beans matched by "beans"
      optional: {'soy sauce', 'chili flakes', 'garlic powder', 'oil'},
      baseTimeMin: 20,
      baseKcalPerServing: 520,
      servings: 2,
      descriptionTmpl: 'Hearty rice and canned beans with pantry seasonings.',
      steps: [
        'Warm beans in a pot with seasonings.',
        'Stir through cooked rice.',
        'Finish with soy sauce or chili flakes to taste.',
      ],
      aliases: {
        'canned beans': 'beans',
        'kidney beans': 'beans',
        'baked beans': 'beans'
      },
    ),
    _Rule(
      id: 'garlic_oil_pasta',
      title: 'Garlic Oil Pasta (Pantry)',
      imageUrl:
          'https://images.unsplash.com/photo-1526318472351-c75fcf070305?q=80&w=1200',
      required: {'pasta', 'oil'},
      optional: {'garlic powder', 'chili flakes', 'soy sauce'},
      baseTimeMin: 12,
      baseKcalPerServing: 480,
      servings: 2,
      descriptionTmpl: 'Simple garlic oil pasta using shelf-seasonings.',
      steps: [
        'Cook pasta in salted water.',
        'Warm oil with garlic powder and chili.',
        'Toss pasta with the oil and a splash of pasta water.',
        'Season and serve.',
      ],
    ),
    _Rule(
      id: 'noodles_upgrade',
      title: 'Upgraded Instant Noodles',
      imageUrl:
          'https://images.unsplash.com/photo-1551183053-bf91a1d81141?q=80&w=1200',
      required: {'instant noodles'},
      optional: {
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
      descriptionTmpl: 'Instant noodles boosted with canned add-ins.',
      steps: [
        'Cook noodles per instructions.',
        'Stir in canned add-ins and seasonings.',
        'Serve hot.',
      ],
      aliases: {'ramen': 'instant noodles'},
    ),
  ];

  // --- Difficulty Evaluator ---
  /// Returns a difficulty level based on ingredient count, time, or missing items
  // Put this inside class MealPlanner (above/below generate)
  static String _computeDifficulty({
    required int ingredientCount,
    required int steps,
    required int minutes,
    int missingCount = 0,
  }) {
    if (minutes <= 20 && ingredientCount <= 5 && missingCount == 0) {
      return 'Easy';
    } else if (minutes <= 45 && ingredientCount <= 8) {
      return 'Moderate';
    } else {
      return 'Hard';
    }
  }

  static Future<List<RecipeSuggestion>> suggestOnDemand({
    required String householdId,
    required List<PantryItem> pantry,
    required MealFilters filters,
    int maxResults = 12,
  }) async {
    // 1) Get candidates (Phase 2: API + local + cache)
    var cands = await MealPlanner.generateHybrid(
      householdId: householdId,
      pantry: pantry,
      apiCount: maxResults * 2, // ask a bit more, we’ll filter down
      addNutrition: false,
    );

    int minutesOf(String t) =>
        int.tryParse(t.replaceAll(RegExp(r'[^0-9]'), '').trim()) ?? 0;

    bool conflicts(List<Map<String, String>> ings, List<String> needles) {
      final names = ings.map((i) => (i['name'] ?? '').toLowerCase()).toList();
      return needles.any((n) => names.any((x) => x.contains(n.toLowerCase())));
    }

    // 2) Apply filters
    cands = cands.where((r) {
      if (minutesOf(r.time) > filters.maxCookMinutes) return false;
      if (conflicts(r.ingredients, filters.allergens)) return false;
      if (conflicts(r.ingredients, filters.dislikes)) return false;
      return true;
    }).toList();

    // 3) Recompute coverage/missing against pantry for final scoring
    List<String> pantryNames = pantry.map((p) => p.name.toLowerCase()).toList();
    bool isNear(PantryItem p) =>
        p.nearExpiry; // you already compute this upstream

    double score(RecipeSuggestion r) {
      // coverage
      final ingNames =
          r.ingredients.map((i) => (i['name'] ?? '').toLowerCase());
      int have = 0;
      int missing = 0;
      int nearUsed = 0;
      for (final n in ingNames) {
        final hit = pantry.firstWhere(
          (p) => p.name.toLowerCase().contains(n),
          orElse: () => PantryItem(
            name: '',
            qty: 0,
            category: '',
            expiryAt: null,
            nearExpiry: false,
            consumed: false,
          ),
        );
        if (hit.name.isEmpty) {
          missing++;
        } else {
          have++;
          if (isNear(hit)) nearUsed++;
        }
      }
      if (missing > filters.allowMissing) return -1e6; // hard filter

      // base components
      final cov = have / (have + missing == 0 ? 1 : (have + missing));
      final near = filters.prioritizeNearExpiry
          ? (nearUsed / (have == 0 ? 1 : have))
          : 0.0;
      final time = minutesOf(r.time);
      final timeScore = 1.0 - (time.clamp(0, 60) / 60.0);

      // Difficulty nudge (Easy > Moderate > Hard)
      final diffNudge = (r.difficulty == 'Easy')
          ? 0.05
          : (r.difficulty == 'Moderate' ? 0.02 : 0.0);

      return 0.55 * cov + 0.25 * timeScore + 0.15 * near + diffNudge;
    }

    cands.sort((a, b) => score(b).compareTo(score(a)));

    // 4) Trim to top maxResults and return
    return cands.take(maxResults).toList();
  }

  /// Generate suggestions from pantry items (pure local rules).
  static List<RecipeSuggestion> generate({
    required List<PantryItem> pantry,
    int nearExpiryDays = defaultNearExpiryDays,
    int maxMissing = defaultMaxMissing,
    int maxResults = defaultMaxResults,
  }) {
    // Build a lookup: normalized name -> qty
    final pantryIndex = <String, int>{};
    for (final p in pantry) {
      pantryIndex[p.name] = (pantryIndex[p.name] ?? 0) + p.qty;
    }

    // compute near-expiry hits for ranking
    final nearMap = {for (final p in pantry) p.name: p.nearExpiry};

    final results =
        <({RecipeSuggestion s, int nearHits, int missing, int time})>[];

    for (final rule in _rules) {
      // Expand required with aliases
      final required = <String>{};
      for (final r in rule.required) {
        required.add(_norm(r));
        for (final entry in rule.aliases.entries) {
          if (_norm(entry.value) == _norm(r)) {
            required.add(_norm(entry.key));
          }
        }
      }

      // OPTIONAL set merged with staples (staples never count as missing)
      final optional = {
        ...rule.optional.map(_norm),
        ..._staples.map(_norm),
      };

      // Check missing count
      var missing = 0;
      var nearHits = 0;

      bool have(String want) => _matchHas(pantryIndex, _norm(want));

      for (final r in required) {
        if (!have(r)) {
          // if it’s blocked fresh/frozen, count as missing but allowed
          if (_blocklistFreshOrFrozen.contains(r)) {
            missing++;
          } else {
            missing++;
          }
        } else {
          // count near-expiry utilization for ranking
          if (nearMap.entries.any((e) => e.key.contains(r) && e.value)) {
            nearHits++;
          }
        }
      }

      if (missing > maxMissing) continue;

      // Build ingredients list from required+optional that we actually have
      final ing = <Map<String, String>>[];
      for (final r in required) {
        ing.add({'name': r, 'amount': ''});
      }
      for (final o in rule.optional) {
        if (have(o)) ing.add({'name': _norm(o), 'amount': ''});
      }

      String computeDifficulty({
        required int ingredientCount,
        required int steps,
        required int minutes,
        int missingCount = 0,
      }) {
        if (minutes <= 20 && ingredientCount <= 5 && missingCount == 0) {
          return 'Easy';
        } else if (minutes <= 45 && ingredientCount <= 8) {
          return 'Moderate';
        } else {
          return 'Hard';
        }
      }

      // If your code tracks “missing” as a list, use its length.
// If it’s already an int, this will use it as-is.
      final int missingCount =
          (missing is int) ? missing : (missing as List).length;

// Make sure these values are ints; parse if you store strings.
      final int minutes = rule.baseTimeMin;
      final int ingredientCount = ing.length;
      final int steps = rule.steps.length;

// NOW compute difficulty
      final String difficulty = computeDifficulty(
        ingredientCount: ingredientCount,
        steps: steps,
        minutes: minutes,
        missingCount: missingCount,
      );

      final s = RecipeSuggestion(
        name: rule.title,
        imageUrl: rule.imageUrl,
        servingSize: rule.servings.toString(),
        calories: '${rule.baseKcalPerServing} kcal',
        time: '${rule.baseTimeMin} minutes',
        description: rule.descriptionTmpl,
        ingredients: ing,
        directions: List<String>.from(rule.steps),
        difficulty: difficulty, // <-- REQUIRED
      );

      results.add(
          (s: s, nearHits: nearHits, missing: missing, time: rule.baseTimeMin));
    }

    // Rank: (1) more near-expiry used, (2) fewer missing, (3) shorter time
    results.sort((a, b) {
      final byNear = b.nearHits.compareTo(a.nearHits);
      if (byNear != 0) return byNear;
      final byMissing = a.missing.compareTo(b.missing);
      if (byMissing != 0) return byMissing;
      return a.time.compareTo(b.time);
    });

    return results.take(maxResults).map((e) => e.s).toList();
  }
}

class _Rule {
  final String id;
  final String title;
  final String imageUrl;
  final Set<String> required;
  final Set<String> optional;
  final int baseTimeMin;
  final int baseKcalPerServing;
  final int servings;
  final String descriptionTmpl;
  final List<String> steps;
  final Map<String, String> aliases; // 'canned tuna' -> 'tuna'

  _Rule({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.required,
    required this.optional,
    required this.baseTimeMin,
    required this.baseKcalPerServing,
    required this.servings,
    required this.descriptionTmpl,
    required this.steps,
    this.aliases = const {},
  });

  // ---- Cache (simple SharedPreferences JSON) ----
  static Future<void> _cachePut(String key, String json) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(key, json);
  }

  static Future<String?> _cacheGet(String key) async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(key);
  }

  static String _cacheKeyFor(String householdId, List<PantryItem> pantry) {
    final names = pantry.map((p) => p.name).toSet().toList()..sort();
    return 'spoonacular:$householdId:${names.join(",")}';
  }

// ---- API mapper ----
  static RecipeSuggestion _mapSpoonacularToSuggestion(Map<String, dynamic> r) {
    final title = (r['title'] ?? '').toString();
    final image = (r['image'] ?? '').toString();
    final servings = (r['servings'] ?? 0) as int? ?? 0;
    final minutes = (r['readyInMinutes'] ?? 0) as int? ?? 0;

    final ext = r['extendedIngredients'] as List? ?? const [];
    final ings = <Map<String, String>>[];
    for (final e in ext) {
      final m = e as Map<String, dynamic>;
      final name = (m['name'] ?? '').toString();
      final amount = (m['original'] ?? '').toString();
      if (name.isNotEmpty) ings.add({'name': name, 'amount': amount});
    }

    final dirs = <String>[];
    final analyzed = r['analyzedInstructions'] as List? ?? const [];
    if (analyzed.isNotEmpty) {
      final first = analyzed.first as Map<String, dynamic>;
      final steps = first['steps'] as List? ?? const [];
      for (final s in steps) {
        final sm = s as Map<String, dynamic>;
        final step = (sm['step'] ?? '').toString().trim();
        if (step.isNotEmpty) dirs.add(step);
      }
    }

    // calories (if nutrition added)
    String calories = '';
    if (r['nutrition'] is Map && (r['nutrition']['nutrients'] is List)) {
      final nutrs = (r['nutrition']['nutrients'] as List).cast<Map>();
      final cal = nutrs.firstWhere(
        (n) => (n['name']?.toString().toLowerCase() ?? '') == 'calories',
        orElse: () => {},
      );
      if (cal['amount'] != null) {
        calories = '${cal['amount']} kcal';
      }
    }

    final difficulty = MealPlanner._computeDifficulty(
      ingredientCount: ings.isEmpty ? (ext.length) : ings.length,
      steps: dirs.isEmpty ? 3 : dirs.length,
      minutes: minutes == 0 ? 20 : minutes,
      missingCount: 0,
    );

    return RecipeSuggestion(
      name: title,
      imageUrl: image,
      servingSize: servings == 0 ? '2' : servings.toString(),
      calories: calories,
      time: minutes == 0 ? '20 minutes' : '$minutes minutes',
      description: title,
      ingredients: ings,
      directions: dirs.isEmpty
          ? ['Follow package directions and season to taste.']
          : dirs,
      difficulty: difficulty,
    );
  }

// ---- API fetch + AI enrichment + merge with local rules ----
  static Future<List<RecipeSuggestion>> generateHybrid({
    required String householdId,
    required List<PantryItem> pantry,
    int apiCount = 10,
    bool addNutrition = false,
  }) async {
    if (pantry.isEmpty) return const [];

    // Build includeIngredients CSV (prioritize near-expiry)
    final near = pantry.where((p) => p.nearExpiry).map((p) => p.name).toList();
    final rest = pantry.where((p) => !p.nearExpiry).map((p) => p.name).toList();
    final ordered = <dynamic>{...near, ...rest}.toList();
    final topCsv = ordered.take(12).join(',');

    // Cache check
    final cacheKey = _cacheKeyFor(householdId, pantry);
    try {
      final hit = await _cacheGet(cacheKey);
      if (hit != null && hit.isNotEmpty) {
        final list = (jsonDecode(hit) as List).cast<Map<String, dynamic>>();
        final suggestions = list.map(_mapSpoonacularToSuggestion).toList();
        return _mergeWithLocalRules(pantry, suggestions);
      }
    } catch (_) {}

    // API call
    List<Map<String, dynamic>> apiResults = [];
    try {
      apiResults = await SpoonacularService.instance.searchByIngredients(
        includeIngredientsCsv: topCsv,
        number: apiCount,
        addNutrition: addNutrition,
      );

      // filter by <=2 missing ingredients if available
      apiResults = apiResults.where((r) {
        final missed = (r['missedIngredientCount'] ?? 0) as int? ?? 0;
        return missed <= 2;
      }).toList();

      // cache raw results
      try {
        await _cachePut(cacheKey, jsonEncode(apiResults));
      } catch (_) {}
    } catch (_) {
      // ignore network errors; fallback to local
    }

    // Map to our model
    var suggestions = apiResults.map(_mapSpoonacularToSuggestion).toList();

    // Enrich with Gemini if fields are thin
    suggestions = await _maybeEnrichWithAI(suggestions);

    // Merge with local rule-based generator
    return _mergeWithLocalRules(pantry, suggestions);
  }

  static Future<List<RecipeSuggestion>> _maybeEnrichWithAI(
      List<RecipeSuggestion> list) async {
    final out = <RecipeSuggestion>[];
    for (final s in list) {
      final needs = (s.description.isEmpty ||
          s.directions.isEmpty ||
          s.servingSize.isEmpty ||
          s.time.isEmpty);
      if (!needs) {
        out.add(s);
        continue;
      }

      try {
        final filled = await AiCompletionService.instance.fillMissing(
          title: s.name,
          ingredients: s.ingredients,
          directions: s.directions,
          currentDescription: s.description,
          currentTime: s.time,
          currentServing: s.servingSize,
        );
        out.add(RecipeSuggestion(
          name: s.name,
          imageUrl: s.imageUrl,
          servingSize: (filled['servingSize'] ?? s.servingSize).toString(),
          calories: s.calories,
          time: (filled['time'] ?? s.time).toString(),
          description: (filled['description'] ?? s.description).toString(),
          ingredients: s.ingredients,
          directions: s.directions.isEmpty && (filled['description'] is String)
              ? [(filled['description'] as String)]
              : s.directions,
          difficulty: (filled['difficulty'] ?? s.difficulty).toString(),
        ));
      } catch (_) {
        out.add(s);
      }
    }
    return out;
  }

// Merge & rank: prefer near-expiry usage, fewer missing, shorter time
  static List<RecipeSuggestion> _mergeWithLocalRules(
    List<PantryItem> pantry,
    List<RecipeSuggestion> fromApi,
  ) {
    final local = MealPlanner.generate(pantry: pantry, maxResults: 8);
    final byName = {for (final s in fromApi) s.name.toLowerCase(): s};
    for (final s in local) {
      byName.putIfAbsent(s.name.toLowerCase(), () => s);
    }
    final merged = byName.values.toList();

    // Basic re-rank (you already have coverage logic; keep it simple here)
    int minutesOf(String t) {
      final n = int.tryParse(t.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return n;
    }

    merged.sort((a, b) => minutesOf(a.time).compareTo(minutesOf(b.time)));
    return merged;
  }
}
