class SuggestedRecipe {
  final String id;
  final String title;
  final String? imageUrl;
  final List<IngredientLine> ingredients;
  final List<String> steps;
  final int? servings;
  final int? timeMin;
  final int? kcalPerServing;
  final String source;              // "spoonacular" | "ai"
  final List<String> usesExpiring;
  final double score;

  SuggestedRecipe({
    required this.id,
    required this.title,
    this.imageUrl,
    required this.ingredients,
    required this.steps,
    this.servings,
    this.timeMin,
    this.kcalPerServing,
    required this.source,
    required this.usesExpiring,
    required this.score,
  });
}

class IngredientLine {
  final String name;
  final double? qty;
  final String? unit;
  final bool inPantry;

  IngredientLine({required this.name, this.qty, this.unit, required this.inPantry});
}
