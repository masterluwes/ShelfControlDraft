import 'package:flutter/material.dart';
import 'package:shelf_control/screens/recipedetails.dart';
import 'package:shelf_control/screens/mealhistory.dart';

// --- Data Model for a Recipe ---
class Recipe {
  final String name;
  final String imageUrl;
  final String servingSize;
  final String calories;
  final String time;
  final String description;
  final List<Map<String, String>> ingredients;
  final List<String> directions;

  const Recipe({
    required this.name,
    required this.imageUrl,
    required this.servingSize,
    required this.calories,
    required this.time,
    required this.description,
    required this.ingredients,
    required this.directions,
  });
}

// --- Main Widget ---
class MealSuggest extends StatelessWidget {
  const MealSuggest({super.key});

  // Centralized list of recipes
  final List<Recipe> suggestedRecipes = const [
    Recipe(
      name: 'Pork Steak',
      imageUrl:
          'https://imagesvc.meredithcorp.io/v3/mm/image?url=https%3A%2F%2Fstatic.onecms.io%2Fwp-content%2Fuploads%2Fsites%2F43%2F2023%2F01%2F31%2F212911-filipino-beef-steak-ddmfs-3X4-0284.jpg&q=60&c=sc&poi=auto&orient=true&h=512',
      servingSize: '2-3',
      calories: '450 Cal',
      time: '45 minutes',
      description:
          'Pork Steak is a beloved Filipino dish made with tender pork chops marinated in a savory blend of soy sauce and calamansi juice. Simmered until juicy and flavorful, then topped with sautéed onions for a sweet aromatic finish.',
      ingredients: [
        {'name': 'Pork chops', 'amount': '4pcs'},
        {'name': 'Soy Sauce', 'amount': '75 ml or 5 tablespoons'},
        {'name': 'Calamansi juice or Lemon juice', 'amount': '30-50 ml'},
        {'name': 'Water', 'amount': '250-375 ml'},
        {'name': 'Cooking oil', 'amount': '120 ml'},
        {'name': 'Sugar', 'amount': '15 ml'},
        {'name': 'Salt and Pepper', 'amount': ''},
        {'name': 'Onions', 'amount': '1 to 2 medium, sliced into rings'},
        {'name': 'Garlic (Optional)', 'amount': '4 to 6 cloves, minced'},
      ],
      directions: [
        'Marinate pork chops in soy sauce, calamansi juice, and garlic for at least 1 hour.',
        'Heat cooking oil in a pan over medium heat. Pan-fry the marinated pork chops until browned.',
        'Pour in the remaining marinade and water. Bring to a boil and simmer until the pork is tender.',
        'Season with sugar, salt, and pepper to taste.',
        'In a separate pan, sauté the onion rings until tender. Top the pork steak with sautéed onions before serving.',
      ],
    ),
    // Add other recipes here...
  ];

  @override
  Widget build(BuildContext context) {
    const Color pageBg = Color(0xFFFFFBE6);
    const Color greenAccent = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        elevation: 1,
        centerTitle: false,
        titleSpacing: 0.0,
        iconTheme: const IconThemeData(color: greenAccent),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Meal Planner',
          style: TextStyle(
            fontFamily: 'Inter',
            color: greenAccent,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MealHistoryPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildNoteBanner(),
              const SizedBox(height: 20),
              ...suggestedRecipes
                  .map(
                    (recipe) =>
                        _buildMealCard(context: context, recipe: recipe),
                  )
                  .toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteBanner() {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEBFFE5),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF2E7D32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: Color(0xFF2E7D32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Discover delicious recipes using the ingredients you already have at your pantry inventory!',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: Color(0xFF595959),
                    ),
                    children: const [
                      TextSpan(
                        text: 'Note: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text:
                            'Suggestions are based on your pantry. Some meals may repeat if your pantry items don’t change.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard({
    required BuildContext context,
    required Recipe recipe,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF2E7D32)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => RecipeDetailsPage(recipe: recipe),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // <-- MODIFIED: Replaced placeholder with the actual recipe image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    recipe.imageUrl,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.name,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 17,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Serving Size: ${recipe.servingSize}  •  ${recipe.calories}',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          color: Colors.black,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.black,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            recipe.time,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              color: Colors.black,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
