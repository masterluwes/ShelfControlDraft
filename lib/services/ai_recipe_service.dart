import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/suggested_recipe.dart';

class AiRecipeService {
  final String baseUrl; // https://asia-southeast1-<project>.cloudfunctions.net
  AiRecipeService({required this.baseUrl});

  Future<List<SuggestedRecipe>> enhance(List<SuggestedRecipe> input,
      {String locale = 'en-PH'}) async {
    if (input.isEmpty) return input;
    final uri = Uri.parse('$baseUrl/aiEnhanceRecipes');
    final payload = input
        .map((r) => {
              'id': r.id,
              'steps': r.steps,
              'timeMin': r.timeMin,
              'kcalPerServing': r.kcalPerServing,
              'title': r.title,
            })
        .toList();

    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'recipes': payload, 'locale': locale}),
    );
    if (resp.statusCode != 200) return input;

    final List data = jsonDecode(resp.body) as List;
    final map = {
      for (final e in data)
        (e['id'] ?? '').toString(): e as Map<String, dynamic>
    };

    return input.map((r) {
      final upd = map[r.id];
      if (upd == null) return r;

      final newSteps =
          (upd['steps'] as List?)?.map((x) => x.toString()).toList() ?? r.steps;

      final newTimeMin = (upd['timeMin'] as num?)?.toInt() ?? r.timeMin;

      final newKcal =
          (upd['kcalPerServing'] as num?)?.toInt() ?? r.kcalPerServing;

      // Rebuild a fresh SuggestedRecipe preserving all other fields
      return SuggestedRecipe(
        id: r.id,
        title: r.title,
        imageUrl: r.imageUrl,
        ingredients: r.ingredients,
        steps: newSteps,
        servings: r.servings,
        timeMin: newTimeMin,
        kcalPerServing: newKcal,
        source: r.source,
        usesExpiring: r.usesExpiring,
        missingIngredients: r.missingIngredients,
        score: r.score,
      );
    }).toList();
  }

  Future<List<SuggestedRecipe>> suggestFromPantry({
    required List<String> pantryNames,
    Map<String, dynamic>? prefs,
    int nearExpiryDays = 5,
  }) async {
    final uri = Uri.parse('$baseUrl/aiSuggestFromPantry');
    final resp = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'pantry': pantryNames,
          'prefs': prefs ?? {},
          'nearExpiryDays': nearExpiryDays,
        }));
    if (resp.statusCode != 200) return const [];
    final List data = jsonDecode(resp.body) as List;
    return data.map((e) {
      final m = e as Map<String, dynamic>;
      final ingr = (m['ingredients'] as List? ?? const []).map((x) {
        final xm = x as Map<String, dynamic>;
        return IngredientLine(
          name: (xm['name'] ?? '').toString(),
          qty: (xm['qty'] as num?)?.toDouble(),
          unit: (xm['unit'] as String?)?.isEmpty ?? true
              ? null
              : (xm['unit'] as String),
          inPantry: true,
        );
      }).toList();
      return SuggestedRecipe(
        id: (m['id'] ?? m['title']).toString(),
        title: (m['title'] ?? '').toString(),
        imageUrl: null,
        ingredients: ingr,
        steps:
            (m['steps'] as List? ?? const []).map((x) => x.toString()).toList(),
        servings: (m['servings'] as num?)?.toInt(),
        timeMin: (m['timeMin'] as num?)?.toInt(),
        kcalPerServing: (m['kcalPerServing'] as num?)?.toInt(),
        source: 'ai',
        usesExpiring: const [],
        missingIngredients: const [],
        score: 1.0,
      );
    }).toList();
  }
}
