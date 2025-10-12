import 'dart:convert';
import 'package:http/http.dart' as http;

class SpoonacularConfig {
  static const String host = 'spoonacular-recipe-food-nutrition-v1.p.rapidapi.com';
  static const String apiKey = String.fromEnvironment('RAPIDAPI_KEY', defaultValue: '');
}

class SpoonacularService {
  SpoonacularService._();
  static final SpoonacularService instance = SpoonacularService._();

  final _client = http.Client();
  static const _timeout = Duration(seconds: 10);

  Future<Map<String, dynamic>> _get(String path, Map<String, String> query) async {
    final uri = Uri.https(SpoonacularConfig.host, path, query);
    final res = await _client.get(uri, headers: {
      'x-rapidapi-host': SpoonacularConfig.host,
      'x-rapidapi-key': SpoonacularConfig.apiKey,
    }).timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('Spoonacular ${res.statusCode}: ${res.body}');
    }
    return json.decode(res.body) as Map<String, dynamic>;
  }

  /// Complex search; addRecipeInformation=true returns ingredients & steps.
  Future<List<Map<String, dynamic>>> searchByIngredients({
    required String includeIngredientsCsv,
    int number = 10,
    int offset = 0,
    bool addNutrition = false,
  }) async {
    final query = <String, String>{
      'includeIngredients': includeIngredientsCsv,
      'instructionsRequired': 'true',
      'addRecipeInformation': 'true',
      'fillIngredients': 'true',
      'number': '$number',
      'offset': '$offset',
      if (addNutrition) 'addRecipeNutrition': 'true',
      // You can add: diet, intolerances, type, sort, etc.
      // 'sort': 'min-missing-ingredients',
    };

    final map = await _get('/recipes/complexSearch', query);
    final results = (map['results'] as List?) ?? const [];
    return results.cast<Map<String, dynamic>>();
  }
}
