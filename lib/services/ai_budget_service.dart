import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Minimal product shape to send to the model
class AiProduct {
  final String name;
  final String? brand;
  final String category; // must match your app categories
  final double price;    // PHP
  final String? sizeText;

  AiProduct({
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    required this.sizeText,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'brand': brand,
        'category': category,
        'price': price,
        'sizeText': sizeText,
      };
}

/// What we expect back
class AiPick {
  final List<AiChosenItem> items;
  final double total;

  AiPick({required this.items, required this.total});

  factory AiPick.fromJson(Map<String, dynamic> m) => AiPick(
        items: (m['items'] as List)
            .whereType<Map>()
            .map((x) => AiChosenItem.fromJson(x.cast<String, dynamic>()))
            .toList(),
        total: (m['total'] as num).toDouble(),
      );
}

class AiChosenItem {
  final String name;
  final String? brand;
  final String category;
  final String? sizeText;
  final int qty;
  final double unitPrice;
  final String reason;

  AiChosenItem({
    required this.name,
    required this.brand,
    required this.category,
    required this.sizeText,
    required this.qty,
    required this.unitPrice,
    required this.reason,
  });

  factory AiChosenItem.fromJson(Map<String, dynamic> m) => AiChosenItem(
        name: (m['name'] ?? '').toString(),
        brand: m['brand'] as String?,
        category: (m['category'] ?? 'Other').toString(),
        sizeText: m['sizeText'] as String?,
        qty: (m['qty'] is int) ? m['qty'] as int : int.tryParse('${m['qty']}') ?? 1,
        unitPrice: (m['unitPrice'] is num)
            ? (m['unitPrice'] as num).toDouble()
            : double.tryParse('${m['unitPrice']}') ?? 0,
        reason: (m['reason'] ?? '').toString(),
      );
}

class AiBudgetService {
  static final _apiKey = const String.fromEnvironment('GEMINI_API_KEY');
  static final _model = GenerativeModel(
    model: 'gemini-1.5-flash', // fast & cheap; switch to 1.5-pro if you prefer
    apiKey: _apiKey,
  );

  /// Ask Gemini to pick staple goods within [budget].
  /// [catalog] should already be filtered to pantry staples (and deduped/compacted).
  static Future<AiPick> pickStaplesUnderBudget({
    required double budget,
    required List<AiProduct> catalog,
  }) async {
    if (_apiKey.isEmpty) {
      throw StateError('GEMINI_API_KEY is missing. Pass via --dart-define.');
    }

    // Keep payload small (token-friendly). Send top-N cheapest per category.
    final byCat = <String, List<AiProduct>>{};
    for (final p in catalog) {
      byCat.putIfAbsent(p.category, () => []).add(p);
    }
    for (final list in byCat.values) {
      list.sort((a, b) => a.price.compareTo(b.price));
    }
    // Take up to 10 per category to limit tokens
    final compact = byCat.values.expand((lst) => lst.take(10)).toList();

    final system =
        'You are a shopping assistant for pantry staples in the Philippines. '
        'Choose items that maximize value under the user\'s budget, favoring staple categories '
        '(Rice, Cooking Oil, Sugar, Salt, Soy Sauce, Vinegar, Sardines, Tuna, Corned Beef, Instant Noodles, Milk, Coffee, Bread/Flour, Snacks). '
        'Respect the given categories. Pantry-only, no fresh meat/produce unless categorized as "Produce" here. '
        'Prefer cheaper options and avoid redundant duplicates.';

    final schema = '''
Return ONLY valid JSON, no extra text, with this shape:
{
  "items": [
    {
      "name": "string",
      "brand": "string or null",
      "category": "Beverages | Baked Goods | Condiments | Canned Goods | Dairy | Produce | Snacks | Other",
      "sizeText": "string or null",
      "qty": 1,
      "unitPrice": 0,
      "reason": "short explanation"
    }
  ],
  "total": 0
}
''';

    final user = {
      'budgetPHP': budget,
      'catalog': compact.map((e) => e.toJson()).toList(),
    };

    final prompt = [
      Content.text(system),
      Content.text(schema),
      Content.text('User request and catalog (JSON):\n${jsonEncode(user)}\n\n'
          'IMPORTANT: Output ONLY the JSON. No backticks.'),
    ];

    final resp = await _model.generateContent(prompt);
    final text = resp.text ?? '{}';
    final decoded = jsonDecode(text) as Map<String, dynamic>;
    return AiPick.fromJson(decoded);
  }
}
