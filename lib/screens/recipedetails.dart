// lib/pages/recipedetails.dart

import 'package:flutter/material.dart';
import 'dart:ui'; // For BackdropFilter
import 'package:shelf_control/screens/mealsuggest.dart'; // Import to access the Recipe model
import 'package:shelf_control/screens/cooking_view.dart'; // <-- 1. ADD THIS IMPORT

String _truncate(String? s, int max) {
  final v = (s ?? '');
  return (v.length <= max) ? v : v.substring(0, max);
}

/// Make long ingredient names shorter but still meaningful.
String simplifyIngredientName(String? name) {
  final original = (name ?? '').toLowerCase().trim();
  if (original.isEmpty) return '';

  final stopWords = <String>{
    'brand',
    'creamy',
    'cream-filled',
    'filled',
    'bar',
    'pcs',
    'piece',
    'pieces',
    'pack',
    'packet',
    'cup',
    'cups',
    'ml',
    'g',
    'kg',
    'bottle',
    'can',
    'slice',
    'sliced',
    'whole',
    'loaf',
  };

  // Split into words
  final words = original.split(RegExp(r'\s+'));

  // Remove quantity values (numbers)
  final noNumbers = words.where((w) => !RegExp(r'^\d').hasMatch(w)).toList();

  // Remove generic + packaging words
  final filtered = noNumbers.where((w) => !stopWords.contains(w)).toList();

  // Prefer 1–2 meaningful words
  List<String> shortened;
  if (filtered.isNotEmpty) {
    shortened = filtered.take(2).toList();
  } else {
    // Fallback: at least keep one word
    shortened = noNumbers.take(1).toList();
  }

  // Convert back to Title Case
  return shortened
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

/// Build a short, aesthetic recipe title from the first two ingredients.
String buildDynamicRecipeTitle(Recipe recipe) {
  final ingredients = recipe.ingredients;

  if (ingredients.isEmpty) {
    return recipe.name;
  }

  final names = ingredients
      .map((i) => simplifyIngredientName(i['name'])) // i['name'] is String?
      .where((n) => n.isNotEmpty)
      .toList();

  if (names.isEmpty) {
    return recipe.name;
  }

  if (names.length == 1) {
    return names.first;
  }

  return '${names[0]} with ${names[1]}';
}

class RecipeDetailsPage extends StatefulWidget {
  final Recipe recipe;
  const RecipeDetailsPage({super.key, required this.recipe});

  @override
  State<RecipeDetailsPage> createState() => _RecipeDetailsPageState();
}

class _RecipeDetailsPageState extends State<RecipeDetailsPage> {
  late ScrollController _scrollController;
  Color _titleColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    const scrollThreshold = 200.0;

    if (_scrollController.offset >= scrollThreshold) {
      if (_titleColor != Colors.black) {
        setState(() {
          _titleColor = Colors.black;
        });
      }
    } else {
      if (_titleColor != Colors.white) {
        setState(() {
          _titleColor = Colors.white;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color greenAccent = Color(0xFF2E7D32);
    const Color pageBg = Color(0xFFFFFBE6);

    const descriptionStyle = TextStyle(
      fontFamily: 'Roboto',
      fontSize: 15,
      color: Colors.black87,
      height: 1.5,
    );

    return Scaffold(
      backgroundColor: pageBg,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(widget.recipe, context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text.rich(
                    TextSpan(
                      style: descriptionStyle,
                      children: [
                        TextSpan(
                          text: '${buildDynamicRecipeTitle(widget.recipe)} ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: (() {
                            final desc = widget.recipe.description ?? '';
                            // Remove the name prefix only if the description actually starts with the name
                            if (desc.startsWith(widget.recipe.name)) {
                              final start = widget.recipe.name.length;
                              // Guard against RangeError by clamping the start within string bounds
                              final safeStart =
                                  start > desc.length ? desc.length : start;
                              final rest = desc.substring(safeStart).trimLeft();
                              return rest.isEmpty ? desc : rest;
                            }
                            return desc;
                          })(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildInfoBox(widget.recipe),
                  const SizedBox(height: 24),
                  const Text(
                    'Ingredients',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: widget.recipe.ingredients
                          .map(
                            (ing) => _buildIngredientItem(
                              ing['name']!,
                              ing['amount']!,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      // <-- 2. UPDATE THE CALL TO PASS THE RECIPE DATA
      bottomNavigationBar: _buildBottomButton(
        context,
        widget.recipe,
        greenAccent,
      ),
    );
  }

  Widget _buildSliverAppBar(Recipe recipe, BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300.0,
      pinned: true,
      backgroundColor: const Color(0xFFFFFBE6),
      elevation: 1,
      iconTheme: const IconThemeData(color: Colors.white),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              color: Colors.black.withOpacity(0.2),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(bottom: 20),
        centerTitle: true,

        title: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Time row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${recipe.time}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: _titleColor,
                    shadows: _titleColor == Colors.white
                        ? [const Shadow(blurRadius: 2, color: Colors.black54)]
                        : null,
                  ),
                  child: Text(buildDynamicRecipeTitle(recipe)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        // Background image + gradient stay here, as siblings of `title`
        background: Stack(
          fit: StackFit.expand,
          children: [
            Builder(
              builder: (context) {
                final String img = (recipe.imageUrl).trim();
                const String fallbackAsset = 'assets/meals.jpg';

                final bool isAsset = img.startsWith('assets/');
                final bool isHttp =
                    img.startsWith('http://') || img.startsWith('https://');

                if (isAsset) {
                  return Image.asset(
                    img,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        fallbackAsset,
                        fit: BoxFit.cover,
                      );
                    },
                  );
                } else if (isHttp) {
                  return Image.network(
                    img,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        fallbackAsset,
                        fit: BoxFit.cover,
                      );
                    },
                  );
                } else {
                  return Image.asset(
                    fallbackAsset,
                    fit: BoxFit.cover,
                  );
                }
              },
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                  stops: [0.5, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(Recipe recipe) {
    const labelStyle = TextStyle(
      fontFamily: 'Roboto',
      color: Color(0xFF595959),
      fontSize: 14,
    );
    const valueStyle = TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );

    Widget buildInfoColumn(String label, String value) {
      return Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: labelStyle),
            const SizedBox(height: 8),
            Text(value, style: valueStyle),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.7)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          buildInfoColumn('Serving Size', recipe.servingSize),
          buildInfoColumn('Difficulty', 'Easy'),
          buildInfoColumn('Estimated Calorie', recipe.calories),
        ],
      ),
    );
  }

  String _toTitleCase(String text) {
    return text.split(' ').map((word) {
      if (word.trim().isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  Widget _buildIngredientItem(String name, String amount) {
    // Format name to Title Case
    final formattedName = _toTitleCase(name.trim());

    // If amount exists → append "(amount)"
    final displayText =
        amount.trim().isNotEmpty ? "$formattedName ($amount)" : formattedName;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayText,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // <-- 3. UPDATE THE WIDGET SIGNATURE AND ONPRESSED LOGIC
  Widget _buildBottomButton(BuildContext context, Recipe recipe, Color color) {
    return Container(
      color: const Color(0xFFFFFBE6),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CookingViewPage(recipe: recipe),
            ),
          );
        },
        child: const Text(
          'Start Cooking',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
