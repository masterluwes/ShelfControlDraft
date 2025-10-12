// lib/services/meal_planner.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PantryItem {
  final String name;         // normalized lower-case
  final int qty;             // quantity available
  final DateTime? expiryAt;  // nullable
  final bool consumed;       // default false
  final bool nearExpiry;     // computed

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
  final String servingSize;      // string for UI
  final String calories;         // e.g. "520 kcal"
  final String time;             // e.g. "25 minutes"
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

class MealPlanner {
  // --- knobs ---
  static const int defaultNearExpiryDays = 5;
  static const int defaultMaxMissing = 2;
  static const int defaultMaxResults = 12;

  // Staples ignored when counting "missing"
  static const Set<String> _staples = {
    'salt','pepper','oil','olive oil','sugar','soy sauce','vinegar',
    'garlic powder','onion powder','chili flakes','water'
  };

  // Items we consider "not pantry-only" (won’t block, but counted as missing)
  static const Set<String> _blocklistFreshOrFrozen = {
    'chicken','pork','beef','fish fillet','egg','fresh tomato','spinach','lettuce',
    'carrot','onion fresh','garlic fresh','milk','butter','cheese fresh'
  };

  // Simple name normalization
  static String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]+'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  static bool _matchHas(Map<String,int> pantryIndex, String want) {
    // contains-style match: if any pantry key contains the want fragment
    for (final k in pantryIndex.keys) {
      if (k.contains(want)) return true;
    }
    return false;
  }

  /// Build PantryItem list from Firestore docs (defensive: supports 'qty' or 'quantity';
  /// 'expiryAt' or 'expirationDate'; Timestamp or ISO string).
  static List<PantryItem> fromSnapshot(QuerySnapshot snap, {int nearExpiryDays = defaultNearExpiryDays}) {
    final now = DateTime.now();
    final items = <PantryItem>[];
    for (final d in snap.docs) {
      final data = d.data() as Map<String, dynamic>? ?? {};
      final rawName = (data['name'] ?? '').toString();
      if (rawName.trim().isEmpty) continue;

      final name = _norm(rawName);
      final qty = (data['qty'] ?? data['quantity'] ?? 0) is int
          ? (data['qty'] ?? data['quantity'] ?? 0) as int
          : int.tryParse((data['qty'] ?? data['quantity'] ?? '0').toString()) ?? 0;

      final consumed = (data['consumed'] ?? false) == true || (data['status'] == 'Deleted');

      DateTime? expiryAt;
      final ex = data['expiryAt'] ?? data['expirationDate'];
      if (ex is Timestamp) {
        expiryAt = ex.toDate();
      } else if (ex is String && ex.trim().isNotEmpty) {
        expiryAt = DateTime.tryParse(ex);
      }

      final expired = expiryAt != null && expiryAt.isBefore(now);
      if (consumed || expired || qty <= 0) continue;

      final near = expiryAt != null && expiryAt.isBefore(now.add(Duration(days: nearExpiryDays)));
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
    _Rule(
      id: 'tuna_pasta',
      title: 'Tuna Pantry Pasta',
      imageUrl: 'https://images.unsplash.com/photo-1523986371872-9d3ba2e2f642?q=80&w=1200',
      required: {'pasta', 'tuna'}, // canned tuna matched via "tuna"
      optional: {'olive oil','oil','garlic powder','soy sauce','chili flakes'},
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
      aliases: {'canned tuna':'tuna'},
    ),
    _Rule(
      id: 'sardines_pasta',
      title: 'Sardines Aglio e Olio',
      imageUrl: 'https://images.unsplash.com/photo-1512058564366-18510be2db19?q=80&w=1200',
      required: {'pasta','sardines'},
      optional: {'olive oil','oil','garlic powder','chili flakes'},
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
      aliases: {'canned sardines':'sardines'},
    ),
    _Rule(
      id: 'fried_rice',
      title: 'Pantry Fried Rice',
      imageUrl: 'https://images.unsplash.com/photo-1598866594230-a7c12756260c?q=80&w=1200',
      required: {'rice', 'soy sauce'},
      optional: {'corned beef','tuna','sardines','garlic powder','onion powder'},
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
      aliases: {'canned corned beef':'corned beef'},
    ),
    _Rule(
      id: 'rice_beans',
      title: 'Rice & Beans Bowl',
      imageUrl: 'https://images.unsplash.com/photo-1568605114967-8130f3a36994?q=80&w=1200',
      required: {'rice','beans'}, // canned beans matched by "beans"
      optional: {'soy sauce','chili flakes','garlic powder','oil'},
      baseTimeMin: 20,
      baseKcalPerServing: 520,
      servings: 2,
      descriptionTmpl: 'Hearty rice and canned beans with pantry seasonings.',
      steps: [
        'Warm beans in a pot with seasonings.',
        'Stir through cooked rice.',
        'Finish with soy sauce or chili flakes to taste.',
      ],
      aliases: {'canned beans':'beans','kidney beans':'beans','baked beans':'beans'},
    ),
    _Rule(
      id: 'garlic_oil_pasta',
      title: 'Garlic Oil Pasta (Pantry)',
      imageUrl: 'https://images.unsplash.com/photo-1526318472351-c75fcf070305?q=80&w=1200',
      required: {'pasta','oil'},
      optional: {'garlic powder','chili flakes','soy sauce'},
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
      imageUrl: 'https://images.unsplash.com/photo-1551183053-bf91a1d81141?q=80&w=1200',
      required: {'instant noodles'},
      optional: {'corned beef','tuna','sardines','soy sauce','garlic powder','chili flakes'},
      baseTimeMin: 8,
      baseKcalPerServing: 430,
      servings: 1,
      descriptionTmpl: 'Instant noodles boosted with canned add-ins.',
      steps: [
        'Cook noodles per instructions.',
        'Stir in canned add-ins and seasonings.',
        'Serve hot.',
      ],
      aliases: {'ramen':'instant noodles'},
    ),
  ];

  /// Generate suggestions from pantry items (pure local rules).
  static List<RecipeSuggestion> generate({
    required List<PantryItem> pantry,
    int nearExpiryDays = defaultNearExpiryDays,
    int maxMissing = defaultMaxMissing,
    int maxResults = defaultMaxResults,
  }) {
    // Build a lookup: normalized name -> qty
    final pantryIndex = <String,int>{};
    for (final p in pantry) {
      pantryIndex[p.name] = (pantryIndex[p.name] ?? 0) + p.qty;
    }

    // compute near-expiry hits for ranking
    final nearMap = { for (final p in pantry) p.name : p.nearExpiry };

    final results = <({RecipeSuggestion s, int nearHits, int missing, int time})>[];

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
      final ing = <Map<String,String>>[];
      for (final r in required) {
        ing.add({'name': r, 'amount': ''});
      }
      for (final o in rule.optional) {
        if (have(o)) ing.add({'name': _norm(o), 'amount': ''});
      }

      final s = RecipeSuggestion(
        name: rule.title,
        imageUrl: rule.imageUrl,
        servingSize: rule.servings.toString(),
        calories: '${rule.baseKcalPerServing} kcal',
        time: '${rule.baseTimeMin} minutes',
        description: rule.descriptionTmpl,
        ingredients: ing,
        directions: List<String>.from(rule.steps),
      );

      results.add((s: s, nearHits: nearHits, missing: missing, time: rule.baseTimeMin));
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
  final Map<String,String> aliases; // 'canned tuna' -> 'tuna'

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
}
