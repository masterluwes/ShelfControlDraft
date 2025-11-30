import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiTipService {
  late final GenerativeModel model;

  AiTipService() {
    final apiKey = dotenv.env['TIPS_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("API_KEY is missing. Check your .env file.");
    }

    model = GenerativeModel(
      model: "gemini-2.5-flash",
      apiKey: apiKey,
    );
  }

  Future<Map<String, dynamic>> getItemTips({
    required String itemName,
    required String category,
    required int expDays,
    required String weatherLevel,
  }) async {

    final prefs = await SharedPreferences.getInstance();
    final cacheKey =
        "ai_tips_${itemName.toLowerCase()}_${category.toLowerCase()}";

    // 1) Try cache
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      return jsonDecode(cached);
    }

    // 2) Build prompt
    final prompt = """
Generate grocery item tips in JSON only.
Item: $itemName
Category: $category
Days until expiration: $expDays
Weather level: $weatherLevel

Return JSON with keys: weather, preservation, waste, labeling.
Each section must contain: title, subtitle, details.
""";

    // 3) Gemini request
    final response = await model.generateContent([
      Content.text(prompt)
    ]);

    final text = response.text;
    if (text == null) return {};

    // Clean JSON if wrapped in Markdown
    final Map<String, dynamic> data = jsonDecode(
      text.replaceAll("```json", "").replaceAll("```", "")
    );

    // Cache result locally
    await prefs.setString(cacheKey, jsonEncode(data));

    return data;
  }
}
