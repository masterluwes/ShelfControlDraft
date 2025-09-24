import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'dart:math';

/// Output shape we’ll pass to ListItemsPage via RouteSettings.arguments.
/// Keep this structure “plain” so ListItemsPage can rehydrate into its Item model.
class BudgetGenItem {
  final String id; // stable-ish ID from name
  final String name; // product name (sans weight)
  final String? brand; // crude brand heuristic
  final String category; // MUST match your app categories
  final String? sizeText; // e.g. "350g", "1L"
  final int qty;
  final double price; // ✅ add price so we can budget-select

  BudgetGenItem({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.sizeText,
    required this.qty,
    required this.price, // ✅
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'brand': brand,
    'category': category,
    'sizeText': sizeText,
    'qty': qty,
    'price': price, // ✅
  };

  BudgetGenItem copyWith({
    String? id,
    String? name,
    String? brand,
    String? category,
    String? sizeText,
    int? qty,
    double? price,
  }) {
    return BudgetGenItem(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      sizeText: sizeText ?? this.sizeText,
      qty: qty ?? this.qty,
      price: price ?? this.price,
    );
  }
}

class BudgetGenerator {
  static const _assetPath = 'assets/data/smmarkets_pantry_full.csv';

  /// App categories you already use
  static const _categories = <String>{
    'Beverages',
    'Baked Goods',
    'Condiments',
    'Canned Goods',
    'Dairy',
    'Produce',
    'Snacks',
    'Other',
  };

  /// “Staple groups” => (category, keywords)
  /// We’ll pick the **cheapest** item per group.
  static final List<_StapleRule> _stapleRules = [
    _StapleRule('Rice', 'Other', [
      'rice',
      'sinandomeng',
      'jasmine',
      'dinorado',
    ]),
    _StapleRule('Cooking Oil', 'Other', [
      'oil',
      'palm oil',
      'canola',
      'vegetable oil',
    ]),
    _StapleRule('Sugar', 'Other', ['sugar', 'white sugar', 'brown sugar']),
    _StapleRule('Salt', 'Other', ['salt']),
    _StapleRule('Soy Sauce', 'Condiments', [
      'soy sauce',
      'toyo',
      'kikkoman',
      'silver swan',
    ]),
    _StapleRule('Vinegar', 'Condiments', ['vinegar', 'suka', 'cane vinegar']),
    _StapleRule('Ketchup', 'Condiments', ['ketchup', 'catsup']),
    _StapleRule('Sardines', 'Canned Goods', ['sardines']),
    _StapleRule('Canned Tuna', 'Canned Goods', ['tuna']),
    _StapleRule('Corned Beef', 'Canned Goods', ['corned beef']),
    _StapleRule('Instant Noodles', 'Other', [
      'instant noodles',
      'pancit canton',
      'bihon',
      'mami',
      'ramen',
      'sotanghon',
    ]),
    _StapleRule('Evap/UHT Milk', 'Dairy', [
      'evaporated milk',
      'evap',
      'condensed milk',
      'uht milk',
      'fresh milk',
    ]),
    _StapleRule('Coffee', 'Beverages', ['coffee', 'kopiko', 'nescafe', '3in1']),
    _StapleRule('Bread/Flour', 'Baked Goods', [
      'bread',
      'loaf',
      'pandesal',
      'flour',
    ]),
    _StapleRule('Snacks', 'Snacks', [
      'biscuit',
      'cookies',
      'chips',
      'crackers',
    ]),
    // Add/adjust rules as you like
  ];

  /// Main entry: builds a list of cheapest staples from CSV.
  static Future<List<BudgetGenItem>> budgetFriendlyStaples({
    int qtyEach = 1,
  }) async {
    final raw = await rootBundle.loadString(_assetPath);
    final rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(raw);

    // Expect header: Name, Net weight, Price
    if (rows.isEmpty) return [];

    final header = rows.first.map((e) => (e ?? '').toString().trim()).toList();
    final idxName = header.indexOf('Name');
    final idxNet = header.indexOf('Net weight');
    final idxPrice = header.indexOf('Price');

    if (idxName < 0 || idxNet < 0 || idxPrice < 0) {
      // Fallback: try lowercase headers, just in case
      final lower = header.map((e) => e.toLowerCase()).toList();
      final iN = lower.indexOf('name');
      final iW = lower.indexOf('net weight');
      final iP = lower.indexOf('price');
      if (iN >= 0) {
        /* rebind */
      }
      // For brevity, assume standard header is present.
    }

    // Normalize lines into records
    final List<_Rec> recs = [];
    for (var i = 1; i < rows.length; i++) {
      final r = rows[i];
      if (r.length <= idxPrice) continue;
      final name = (r[idxName] ?? '').toString().trim();
      if (name.isEmpty) continue;

      final netStr = (r[idxNet] ?? '').toString().trim();
      final priceStr = (r[idxPrice] ?? '').toString().trim();

      final price = double.tryParse(priceStr.replaceAll(',', ''));
      if (price == null) continue;

      recs.add(_Rec(name: name, net: netStr, price: price));
    }

    // For each staple rule, pick the cheapest matching record
    final List<BudgetGenItem> out = [];
    for (final rule in _stapleRules) {
      final matches = recs.where((r) => rule.matches(r.name)).toList();
      if (matches.isEmpty) continue;

      matches.sort((a, b) => a.price.compareTo(b.price));
      final best = matches.first;

      final parsed = _parseName(best.name);
      final brand = parsed.$1;
      final baseName = parsed.$2; // sans weight decorations
      final sizeText =
          _extractSize(best.name) ??
          (best.net?.isNotEmpty == true ? best.net : null);

      out.add(
        BudgetGenItem(
          id: _slug(baseName),
          name: baseName,
          brand: brand,
          category: _categories.contains(rule.category)
              ? rule.category
              : 'Other',
          sizeText: sizeText,
          qty: qtyEach,
          price: best.price,
        ),
      );
    }

    return out;
  }

  /// Return cheapest staples but trimmed to fit the given budget (PHP).
  /// If budget <= 0, it returns all cheapest-per-staple.
  /// Always returns at least 1 item (the overall cheapest), even if over budget.
  static Future<List<BudgetGenItem>> budgetStaplesUnder(
    double budgetPHP, {
    int qtyEach = 1,
  }) async {
    final all = await budgetFriendlyStaples(
      qtyEach: qtyEach,
    ); // has price filled

    if (budgetPHP <= 0) {
      return all;
    }

    // Priority order so results don't start with the same random brand every time.
    // You can tweak this to your liking.
    const priority = <String>[
      'Rice',
      'Cooking Oil',
      'Soy Sauce',
      'Vinegar',
      'Salt',
      'Sugar',
      'Canned Tuna',
      'Sardines',
      'Corned Beef',
      'Instant Noodles',
      'Evap/UHT Milk',
      'Coffee',
      'Bread/Flour',
      'Ketchup',
      'Snacks',
    ];

    // Map label->item by matching the rule label prefix inside 'name' or 'category' heuristically
    // (We didn't keep the label with each item; we’ll approximate by category+keywords.)
    // Simpler: sort by (priority index, then price).
    int prioIndex(BudgetGenItem it) {
      // Try to infer the label from the item name/category
      final n = (it.name + ' ' + (it.brand ?? '')).toLowerCase();
      int idx = priority.length; // default end
      void trySet(String key, int i) {
        if (n.contains(key.toLowerCase())) idx = idx < i ? idx : i;
      }

      // lighten-weight heuristics matching
      trySet('rice', 0);
      trySet('oil', 1);
      trySet('soy', 2);
      trySet('toyo', 2);
      trySet('vinegar', 3);
      trySet('suka', 3);
      trySet('salt', 4);
      trySet('sugar', 5);
      trySet('tuna', 6);
      trySet('sardines', 7);
      trySet('corned beef', 8);
      trySet('noodles', 9);
      trySet('bihon', 9);
      trySet('pancit', 9);
      trySet('milk', 10);
      trySet('coffee', 11);
      trySet('bread', 12);
      trySet('flour', 12);
      trySet('loaf', 12);
      trySet('ketchup', 13);
      trySet('catsup', 13);
      trySet('biscuit', 14);
      trySet('cookies', 14);
      trySet('chips', 14);
      trySet('snack', 14);

      return idx;
    }

    final sorted = [...all]
      ..sort((a, b) {
        final pa = prioIndex(a);
        final pb = prioIndex(b);
        if (pa != pb) return pa.compareTo(pb);
        return a.price.compareTo(b.price);
      });

    final chosen = <BudgetGenItem>[];
    double sum = 0;

    for (final it in sorted) {
      if ((sum + it.price) <= budgetPHP) {
        chosen.add(it);
        sum += it.price;
      }
    }

    // Ensure at least one item
    if (chosen.isEmpty && sorted.isNotEmpty) {
      chosen.add(sorted.first);
    }

    return chosen;
  }

  /// Split brand + product heuristic:
  /// Take first 1–2 capitalized tokens as brand if they look like brand names (e.g., "Datu Puti").
  static (String?, String) _parseName(String raw) {
    final cleaned = raw.split('|').first.trim(); // drop " | 350g"
    final tokens = cleaned.split(RegExp(r'\s+'));
    if (tokens.length == 1) return (null, cleaned);

    String? brand;
    String product;

    // Try first two tokens as brand if both look Capitalized
    bool isCap(String s) => s.isNotEmpty && s[0] == s[0].toUpperCase();
    if (tokens.length >= 2 && isCap(tokens[0]) && isCap(tokens[1])) {
      brand = '${tokens[0]} ${tokens[1]}';
      product = tokens.skip(2).join(' ').trim();
      if (product.isEmpty) {
        // fallback: first token brand
        brand = tokens.first;
        product = tokens.skip(1).join(' ').trim();
      }
    } else {
      brand = isCap(tokens[0]) ? tokens[0] : null;
      product = brand == null ? cleaned : tokens.skip(1).join(' ').trim();
    }
    return (brand, product.isEmpty ? cleaned : product);
  }

  static String? _extractSize(String name) {
    final m = RegExp(r'(\d+(\.\d+)?\s?(g|kg|ml|l|L|G|KG|ML))').firstMatch(name);
    return m?.group(0);
  }

  static String _slug(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');

  /// Picks a varied set of items whose total stays within [budget] PHP.
  /// Results are randomized each call.
  static Future<List<BudgetGenItem>> pickWithinBudget({
    required double budget,
    int maxItems = 60,
  }) async {
    if (budget < 200) return [];

    // 1) Load CSV
    final raw = await rootBundle.loadString(_assetPath);
    final rows = const CsvToListConverter(
      eol: '\n',
      shouldParseNumbers: false,
    ).convert(raw);

    if (rows.isEmpty) return [];
    final header = rows.first.map((e) => (e ?? '').toString().trim()).toList();
    final idxName = header.indexOf('Name');
    final idxNet = header.indexOf('Net weight');
    final idxPrice = header.indexOf('Price');
    if (idxName < 0 || idxNet < 0 || idxPrice < 0) return [];

    // 2) Normalize rows into BudgetGenItem
    List<BudgetGenItem> catalog = [];
    for (int i = 1; i < rows.length; i++) {
      final r = rows[i];
      if (r.length <= idxPrice) continue;

      final name = (r[idxName] ?? '').toString().trim();
      if (name.isEmpty) continue;

      final net = (r[idxNet] ?? '').toString().trim();
      final priceStr = (r[idxPrice] ?? '').toString();
      final price =
          double.tryParse(priceStr.replaceAll(RegExp(r'[^\d\.]'), '')) ?? 0.0;
      if (price <= 0) continue;

      final cat = _inferCategoryForName(name) ?? 'Other';
      final brand = _inferBrandFromName(name);

      catalog.add(
        BudgetGenItem(
          id: _slugify(name),
          name: _stripSizeFromName(name),
          brand: brand,
          category: _categories.contains(cat) ? cat : 'Other',
          sizeText: net.isEmpty ? null : net,
          qty: 1,
          price: price,
        ),
      );
    }

    if (catalog.isEmpty) return [];

    // 3) Shuffle for randomness
    final rnd = Random(DateTime.now().millisecondsSinceEpoch);
    catalog.shuffle(rnd);

    // 4) Cheap-first within category for better variety
    // group by category, sort each by price asc
    final byCat = <String, List<BudgetGenItem>>{};
    for (final p in catalog) {
      byCat.putIfAbsent(p.category, () => []).add(p);
    }
    for (final list in byCat.values) {
      list.sort((a, b) => a.price.compareTo(b.price));
    }

    // 5) Simple per-category quota so one category doesn’t dominate
    final perCatQuota = {
      for (final c in byCat.keys) c: 8, // tweak as needed
    };

    // 6) Greedy pack: iterate categories round-robin to ensure diversity
    final picks = <BudgetGenItem>[];
    double spent = 0.0;

    // Prebuild iterators
    final catOrder = byCat.keys.toList()..shuffle(rnd);
    final catIdx = {for (final c in catOrder) c: 0};

    bool anyAdded = true;
    while (spent < budget && picks.length < maxItems && anyAdded) {
      anyAdded = false;

      for (final c in catOrder) {
        final list = byCat[c]!;
        final idx = catIdx[c]!;
        if (idx >= list.length) continue;
        if ((perCatQuota[c] ?? 0) <= 0) continue;

        final candidate = list[idx];
        // Try qty 1..3 randomly if it still fits
        final maxQty = 1 + rnd.nextInt(3); // 1 to 3
        int chosenQty = 0;
        for (int q = 1; q <= maxQty; q++) {
          final nextCost = spent + candidate.price * q;
          if (nextCost <= budget) {
            chosenQty = q;
          } else {
            break;
          }
        }
        if (chosenQty == 0) continue;

        // Add it
        picks.add(candidate.copyWith(qty: chosenQty));
        spent += candidate.price * chosenQty;
        perCatQuota[c] = (perCatQuota[c] ?? 0) - 1;
        catIdx[c] = idx + 1;
        anyAdded = true;

        if (spent >= budget * 0.995) break; // close enough
        if (picks.length >= maxItems) break;
      }
    }

    // If still too few items (e.g., very high budget), do a cheaper flood pass
    if (picks.length < 20 && spent < budget * 0.8) {
      // flatten cheap catalog globally
      final cheap = [...catalog]..sort((a, b) => a.price.compareTo(b.price));
      for (final it in cheap) {
        if (picks.length >= maxItems) break;
        final nextCost = spent + it.price;
        if (nextCost <= budget) {
          picks.add(it.copyWith(qty: 1));
          spent = nextCost;
        } else {
          break;
        }
      }
    }

    // 🔥 Shuffle the final list so results change order each time
    final items = picks.toList()..shuffle();
    return items;
  }

  // ---- Helpers (reuse/borrow from your existing rules) ----
  static String _slugify(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

  static String _stripSizeFromName(String s) {
    // naive: drop trailing size like " 350g", " 1L"
    return s
        .replaceAll(
          RegExp(r'\s*(\d+(\.\d+)?)(ml|l|g|kg|oz)\b', caseSensitive: false),
          '',
        )
        .trim();
  }

  static String? _inferCategoryForName(String name) {
    // Reuse staple rules to map to your app categories
    for (final rule in _stapleRules) {
      if (rule.matches(name)) return rule.category;
    }
    // fallback heuristics
    final n = name.toLowerCase();
    if (n.contains('coffee') ||
        n.contains('juice') ||
        n.contains('milk') ||
        n.contains('soda')) {
      return 'Beverages';
    }
    if (n.contains('bread') || n.contains('flour') || n.contains('loaf')) {
      return 'Baked Goods';
    }
    if (n.contains('ketchup') ||
        n.contains('soy') ||
        n.contains('vinegar') ||
        n.contains('mayonnaise')) {
      return 'Condiments';
    }
    if (n.contains('sardine') ||
        n.contains('tuna') ||
        n.contains('corned beef') ||
        n.contains('canned')) {
      return 'Canned Goods';
    }
    if (n.contains('cheese') || n.contains('butter')) {
      return 'Dairy';
    }
    if (n.contains('chips') ||
        n.contains('cookies') ||
        n.contains('biscuit') ||
        n.contains('snack')) {
      return 'Snacks';
    }
    return null;
  }

  static String? _inferBrandFromName(String name) {
    // very light heuristic: brand is first capitalized token that is not the first word if present
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0][0] == parts[0][0].toUpperCase()) {
      return parts[0];
    }
    return null;
  }
}

class _Rec {
  final String name;
  final String? net;
  final double price;
  _Rec({required this.name, required this.net, required this.price});
}

class _StapleRule {
  final String label; // human-friendly group
  final String category; // must match app categories
  final List<String> keywords;
  _StapleRule(this.label, this.category, this.keywords);

  bool matches(String text) {
    final t = text.toLowerCase();
    return keywords.any((k) => t.contains(k.toLowerCase()));
  }
}
