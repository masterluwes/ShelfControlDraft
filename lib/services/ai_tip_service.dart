import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AiTipService {
  final model = GenerativeModel(
    model: "gemini-2.5-flash",
    apiKey: "AIzaSyBOBjJK3CBhBnaQFY-y2uN-lwkXrJvkYOw",
  );

  Future<Map<String, dynamic>> getItemTips({
    required String itemName,
    required String category,
    required int expDays,
    required String weatherLevel,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = "ai_tips_${itemName.toLowerCase()}_${category.toLowerCase()}";

    // 1) TRY CACHE FIRST
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      return jsonDecode(cached);
    }

    // 2) CALL GEMINI IF NO CACHE
    final prompt = """
Generate grocery item tips in JSON only.
Item: $itemName
Category: $category
Days until expiration: $expDays
Weather level: $weatherLevel

Return JSON with keys: weather, preservation, waste, labeling.
Each section contains title, subtitle, details.
""";

    final response = await model.generateContent([
      Content.text(prompt)
    ]);

    final text = response.text;
    if (text == null) return {};

    // Safe JSON extract
    final Map<String, dynamic> data = jsonDecode(
      text.replaceAll("```json", "").replaceAll("```", "")
    );

    // 3) SAVE TO LOCAL CACHE
    prefs.setString(cacheKey, jsonEncode(data));

    return data;
  }
}
