import 'package:flutter/material.dart';

class RecipeSuggestionsPage extends StatelessWidget {
  final String itemName;

  const RecipeSuggestionsPage({super.key, required this.itemName});

  // Dummy recipe data for demonstration
  static final Map<String, List<Map<String, String>>> _recipes = {
    'milk': [
      {'name': 'Pancakes', 'description': 'Fluffy pancakes perfect for breakfast.', 'link': 'https://www.allrecipes.com/recipe/20177/best-pancakes/'},
      {'name': 'Creamy Pasta Sauce', 'description': 'A rich and creamy sauce for your favorite pasta.', 'link': 'https://www.allrecipes.com/recipe/228862/creamy-tomato-pasta-sauce/'},
      {'name': 'Fruit Smoothie', 'description': 'Healthy and refreshing fruit smoothie.', 'link': 'https://www.allrecipes.com/recipe/213008/berry-smoothie/'},
    ],
    'canned tuna': [
      {'name': 'Tuna Salad Sandwich', 'description': 'Classic tuna salad for a quick lunch.', 'link': 'https://www.allrecipes.com/recipe/20516/best-tuna-salad-sandwich/'},
      {'name': 'Tuna Pasta Bake', 'description': 'Comforting tuna pasta bake.', 'link': 'https://www.bbcgoodfood.com/recipes/tuna-pasta-bake'},
      {'name': 'Spicy Tuna Bowl', 'description': 'A quick and spicy tuna bowl with rice.', 'link': 'https://www.budgetbytes.com/spicy-tuna-bowls/'},
    ],
    'bread': [
      {'name': 'French Toast', 'description': 'Sweet and delicious French toast.', 'link': 'https://www.allrecipes.com/recipe/7016/french-toast-i/'},
      {'name': 'Garlic Bread', 'description': 'Easy homemade garlic bread.', 'link': 'https://www.allrecipes.com/recipe/24022/garlic-bread-spread/'},
      {'name': 'Bread Pudding', 'description': 'A classic dessert to use up old bread.', 'link': 'https://www.allrecipes.com/recipe/7017/bread-pudding-i/'},
    ],
    'cupcakes': [
      {'name': 'Cupcake Milkshake', 'description': 'Turn leftover cupcakes into a delicious milkshake.', 'link': 'https://www.food.com/recipe/cupcake-milkshake-499000'},
    ],
    // Add more items and recipes as needed
  };

  List<Map<String, String>> _getRecipesForItem(String item) {
    // Normalize item name for lookup (e.g., convert to lowercase)
    final normalizedItem = item.toLowerCase();
    return _recipes[normalizedItem] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final recipes = _getRecipesForItem(itemName);
    final Color headerGreen = const Color(0xFF2E7D32);
    final Color softCream = const Color(0xFFFFFBE6);

    return Scaffold(
      backgroundColor: softCream,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2E7D32)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    'Back',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Recipes for "${itemName}"',
                style: TextStyle(
                  color: headerGreen,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: recipes.isEmpty
                  ? Center(
                      child: Text(
                        'No recipe suggestions found for "${itemName}".',
                        style: const TextStyle(fontSize: 16, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: recipes.length,
                      itemBuilder: (context, index) {
                        final recipe = recipes[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            title: Text(
                              recipe['name']!,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: headerGreen,
                              ),
                            ),
                            subtitle: Text(recipe['description']!),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            onTap: () {
                              // TODO: Open recipe link in a browser
                              print('Opening recipe: ${recipe['link']}');
                              // Example: launch URL (requires url_launcher package)
                              // launchUrl(Uri.parse(recipe['link']!));
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
