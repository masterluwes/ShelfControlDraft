// lib/pages/recipedetails.dart

import 'package:flutter/material.dart';
import 'dart:ui'; // For BackdropFilter
import 'package:shelf_control/screens/mealsuggest.dart'; // Import to access the Recipe model
import 'package:shelf_control/screens/cooking_view.dart'; // <-- 1. ADD THIS IMPORT

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
                          text: '${widget.recipe.name} ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text: widget.recipe.description.substring(
                            widget.recipe.name.length,
                          ),
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
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        centerTitle: false,
        title: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            fontSize: 32,
            color: _titleColor,
            shadows: _titleColor == Colors.white
                ? [const Shadow(blurRadius: 2, color: Colors.black54)]
                : null,
          ),
          child: Text(recipe.name),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              recipe.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.image_not_supported,
                  color: Colors.grey,
                  size: 60,
                );
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
            Positioned(
              left: 16,
              bottom: 85,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    color: Colors.black.withOpacity(0.25),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${recipe.time} min',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
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
          buildInfoColumn('Difficulty', recipe.difficulty), 
          buildInfoColumn('Estimated Calorie', recipe.calories),
        ],
      ),
    );
  }

  Widget _buildIngredientItem(String name, String amount) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (amount.isNotEmpty)
                  Text(
                    amount,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
              ],
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
