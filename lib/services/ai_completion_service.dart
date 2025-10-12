import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

class AiCompletionService {
  AiCompletionService._();
  static final AiCompletionService instance = AiCompletionService._();

  static final String _apiKey =
      const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  Future<Map<String, dynamic>> fillMissing({
    required String title,
    required List<Map<String,String>> ingredients,
    required List<String> directions,
    required String currentDescription,
    required String currentTime,
    required String currentServing,
  }) async {
    if (_apiKey.isEmpty) return {};

    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
    final ingText = ingredients.map((e) => "- ${e['name']} (${e['amount'] ?? ''})").join("\n");
    final dirText = directions.isEmpty ? "(none)" : directions.map((e) => "- $e").join("\n");

    final prompt = """
You are helping fill missing fields for a pantry-based recipe.

Title: $title

Ingredients:
$ingText

Directions:
$dirText

Existing:
- Description: $currentDescription
- Time: $currentTime
- Servings: $currentServing

Return a strict JSON with keys:
{
  "description": "<short 1-2 sentence appetizing description>",
  "time": "<minutes like '25 minutes'>",
  "servingSize": "<integer or simple string like '2'>",
  "difficulty": "<Easy|Moderate|Hard>"
}
""";

    final resp = await model.generateContent([Content.text(prompt)]);
    final text = resp.text ?? '';
    // naive parse: try to find JSON block
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return {};
    final jsonStr = text.substring(start, end+1);
    try {
      return safeDecode(jsonStr);
    } catch (_) { return {}; }
  }

  Map<String, dynamic> safeDecode(String s) {
    // Tiny permissive JSON parser; use proper jsonDecode in real code and handle errors.
    return (jsonDecode(s) as Map).cast<String, dynamic>();
  }
}
