import 'dart:convert';
import 'package:http/http.dart' as http;
// Turns branded/pack sizes into generic ingredient names Spoonacular understands
String _toGenericIngredient(String raw) {
  var s = raw.toLowerCase().trim();
  // split on common brand separators
  for (final sep in ['|', '–', '-', '—']) {
    if (s.contains(sep)) s = s.split(sep)[0].trim();
  }
  // remove size and units
  s = s.replaceAll(RegExp(r'\b\d+(\.\d+)?\s*(g|kg|ml|l|pcs|pc|pack|packs)\b'), '').trim();
  // remove extra descriptors
  s = s.replaceAll(RegExp(r'\b(adult|plus|amazing|premium|original|classic|loaf|drink)\b'), '').trim();
  // fix spacing
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

  // canonical map for local terms/brands → generic
  const canon = {
    'bear brand': 'milk powder',
    'powdered milk': 'milk powder',
    'powdered milk drink': 'milk powder',
    'banana catsup': 'banana ketchup',
    'catsup': 'ketchup',
    'butterscotch': 'bread', // best-effort; use as "bread"
    'butterscotch loaf': 'bread',
    'gardenia': 'bread',
    'loaf': 'bread',
  };
  if (canon.containsKey(s)) return canon[s]!;
  // last-mile tweaks
  if (s.contains('catsup')) return 'ketchup';
  if (s.contains('ketchup')) return 'banana ketchup'; // prefer banana ketchup if user’s brand says so
  if (s.contains('milk')) return 'milk powder';
  if (s.contains('bread')) return 'bread';
  return s;
}

// Existing name→Spoonacular map (keep yours if you added it); now call _toGenericIngredient first
String _toSpoonName(String name) {
  final g = _toGenericIngredient(name);
  // add/keep any Filipino→English mappings you already had here
  return g;
}


class SpoonacularService {
  final String baseUrl; // e.g., "https://asia-southeast1-<project>.cloudfunctions.net"

  SpoonacularService({required this.baseUrl});

  Future<List<Map<String, dynamic>>> findByIngredients({
    required List<String> ingredients,
    int number = 24,
    int ranking = 1,
  }) async {
    final uri = Uri.parse('$baseUrl/spoonacularFindByIngredients');
    final resp = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ingredients': ingredients,
          'number': number,
          'ranking': ranking,
        }));
    if (resp.statusCode != 200) {
      throw Exception('Spoonacular findByIngredients: ${resp.statusCode} ${resp.body}');
    }
    final data = jsonDecode(resp.body) as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getRecipeInfo({required int id}) async {
    final uri = Uri.parse('$baseUrl/spoonacularGetRecipeInfo');
    final resp = await http.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id}));
    if (resp.statusCode != 200) {
      throw Exception('Spoonacular getRecipeInfo: ${resp.statusCode} ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }
}
