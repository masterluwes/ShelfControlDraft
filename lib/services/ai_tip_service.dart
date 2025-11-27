import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

class AiTipService {
  final _model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: 'AIzaSyCaH-tn2-xwujUIN5M71d3UK04YSIEycgI',
  );

  Future<Map<String, dynamic>> getItemTips({
    required String itemName,
    required String category,
    required int expDays,
    required String weatherLevel,
  }) async {
    final prompt = """
You are an expert food safety assistant. Generate dynamic storage, safety, and labeling guidance for a single food item.

ITEM NAME: $itemName  
CATEGORY: $category  
DAYS UNTIL EXPIRATION: $expDays  
WEATHER LEVEL: $weatherLevel

Return **ONLY pure JSON** (no explanations, no markdown, no backticks).

The format MUST be:

{
  "weather": {
    "title": "Current Suggestion (Weather)",
    "subtitle": "Short subtitle about weather effects",
    "details": "A paragraph explaining how current weather affects storage for this item."
  },
  "preservation": {
    "title": "Food Preservation Tips",
    "subtitle": "Short one-line summary",
    "details": "A detailed paragraph explaining how to preserve this specific item."
  },
  "waste": {
    "title": "Waste Reduction Tips",
    "subtitle": "Short one-line summary",
    "details": "Ideas for using up this item before it spoils."
  },
  "labeling": {
    "title": "Food Labeling & Definitions",
    "subtitle": "Short one-line summary",
    "details": "Explain labeling terms relevant to this item (Best Before, Use By, etc)."
  }
}
""";

    try {
      final response = await _model.generateContent([
        Content.text(prompt)
      ]);

      final raw = response.text;

      if (raw == null) return {};

      // Gemini sometimes wraps JSON with extra text → clean it
      final cleaned = _extractJson(raw);

      return jsonDecode(cleaned);
    } catch (e) {
      print("AI TIP ERROR: $e");
      return {}; // Fail silently → let app use fallback rules
    }
  }

  /// Cleans model output to extract ONLY JSON map.
  String _extractJson(String input) {
    final start = input.indexOf('{');
    final end = input.lastIndexOf('}');
    if (start != -1 && end != -1) {
      return input.substring(start, end + 1);
    }
    return "{}";
  }
}
