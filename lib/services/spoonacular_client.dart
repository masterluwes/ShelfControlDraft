import 'dart:convert';
import 'package:http/http.dart' as http;

class SpoonacularClient {
  SpoonacularClient(this.apiKey);

  final String apiKey;

  Future<List<Map<String, dynamic>>> complexSearch({
    required List<String> includeIngredients,
    String? diet,
    List<String>? intolerances,
    List<String>? excludeIngredients,
    int number = 24,
  }) async {
    final uri = Uri.https(
      'api.spoonacular.com',
      '/recipes/complexSearch',
      {
        'apiKey': apiKey,
        'includeIngredients': includeIngredients.join(','),
        if (diet != null && diet.isNotEmpty) 'diet': diet,
        if (intolerances != null && intolerances.isNotEmpty) 'intolerances': intolerances.join(','),
        if (excludeIngredients != null && excludeIngredients.isNotEmpty) 'excludeIngredients': excludeIngredients.join(','),
        'addRecipeInformation': 'true',
        'fillIngredients': 'true',
        'number': '$number',
      },
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Spoonacular error ${res.statusCode}: ${res.body}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final results = (body['results'] as List?) ?? const [];
    return results.cast<Map<String, dynamic>>();
  }
}
