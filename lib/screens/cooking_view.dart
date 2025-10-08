// lib/pages/cooking_view.dart

import 'package:flutter/material.dart';
import 'package:shelf_control/screens/mealsuggest.dart'; // To access the Recipe model
import 'package:shelf_control/screens/mealhistory.dart'; // Import the MealHistoryPage

// --- List of common ingredients that can be ignored for the "Done Cooking" button ---
const List<String> optionalIngredients = [
  'water',
  'cooking oil',
  'sugar',
  'salt and pepper',
  'onions',
  'garlic (optional)',
];

class CookingViewPage extends StatefulWidget {
  final Recipe recipe;
  const CookingViewPage({super.key, required this.recipe});

  @override
  State<CookingViewPage> createState() => _CookingViewPageState();
}

class _CookingViewPageState extends State<CookingViewPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<bool> _checkedIngredients;
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkedIngredients = List<bool>.filled(
      widget.recipe.ingredients.length,
      false,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _areAllRequiredIngredientsDone() {
    for (int i = 0; i < widget.recipe.ingredients.length; i++) {
      final ingredientName = widget.recipe.ingredients[i]['name']!
          .toLowerCase();
      final isOptional = optionalIngredients.contains(ingredientName);
      final isChecked = _checkedIngredients[i];

      if (!isOptional && !isChecked) {
        return false;
      }
    }
    return true;
  }

  void _confirmAndUpdatePantry() {
    // Hide the confirmation overlay
    setState(() {
      _isConfirming = false;
    });

    // Add the meal to the history list
    MealHistoryPage.mealHistory.add(widget.recipe);

    // Show the success dialog
    showDialog(
      context: context,
      barrierDismissible: false, // User cannot dismiss the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 48),
              SizedBox(height: 16),
              Text(
                "Success!",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              SizedBox(height: 8),
              Text(
                "The suggested meal has been saved to your meal history.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                "Pantry inventory has been updated.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        );
      },
    );

    // After 3 seconds, close the dialog and navigate to the history page.
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MealHistoryPage()),
        (Route<dynamic> route) => route.isFirst,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBE6),
      body: Stack(
        children: [
          Column(
            children: [
              _buildImageHeader(),
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF2E7D32),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF2E7D32),
                tabs: const [
                  Tab(text: 'Ingredients'),
                  Tab(text: 'Directions'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildIngredientsList(), _buildDirectionsList()],
                ),
              ),
              _buildDoneCookingButton(),
            ],
          ),
          _buildConfirmationOverlay(),
        ],
      ),
    );
  }

  Widget _buildImageHeader() {
    return Stack(
      children: [
        Image.network(
          widget.recipe.imageUrl,
          height: 250,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        Container(
          height: 250,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black54],
              stops: [0.5, 1.0],
            ),
          ),
        ),
        Positioned(
          top: 40,
          left: 16,
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.4),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.recipe.time,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.recipe.name,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: widget.recipe.ingredients.length,
      itemBuilder: (context, index) {
        final ingredient = widget.recipe.ingredients[index];
        return CheckboxListTile(
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            ingredient['name']!,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: ingredient['amount']!.isNotEmpty
              ? Text(ingredient['amount']!)
              : null,
          value: _checkedIngredients[index],
          onChanged: (bool? value) {
            setState(() {
              _checkedIngredients[index] = value!;
            });
          },
          activeColor: const Color(0xFF2E7D32),
        );
      },
    );
  }

  Widget _buildDirectionsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: widget.recipe.directions.length,
      itemBuilder: (context, index) {
        final direction = widget.recipe.directions[index];
        return ListTile(
          leading: Text(
            '${index + 1}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          title: Text(direction),
        );
      },
    );
  }

  Widget _buildDoneCookingButton() {
    bool isDone = _areAllRequiredIngredientsDone();
    return Container(
      color: const Color(0xFFFFFBE6),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDone ? const Color(0xFF2E7D32) : Colors.grey,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: isDone
            ? () {
                setState(() {
                  _isConfirming = true;
                });
              }
            : null,
        child: const Text(
          'Done Cooking',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationOverlay() {
    return IgnorePointer(
      ignoring: !_isConfirming,
      child: Stack(
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _isConfirming ? 1.0 : 0.0,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isConfirming = false;
                });
              },
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: _isConfirming ? 0 : -MediaQuery.of(context).size.height,
            left: 0,
            right: 0,
            child: _ConfirmationCard(
              recipe: widget.recipe,
              onConfirm: _confirmAndUpdatePantry,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmationCard extends StatefulWidget {
  final Recipe recipe;
  final VoidCallback onConfirm;
  const _ConfirmationCard({required this.recipe, required this.onConfirm});

  @override
  State<_ConfirmationCard> createState() => _ConfirmationCardState();
}

class _ConfirmationCardState extends State<_ConfirmationCard> {
  late List<bool> _usedIngredients;

  @override
  void initState() {
    super.initState();
    _usedIngredients = List<bool>.filled(
      widget.recipe.ingredients.length,
      true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFBE6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pantry Usage',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.recipe.ingredients.length,
                  itemBuilder: (context, index) {
                    final ingredient = widget.recipe.ingredients[index];
                    return CheckboxListTile(
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      title: Text(
                        ingredient['name']!,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: ingredient['amount']!.isNotEmpty
                          ? Text(
                              ingredient['amount']!,
                              style: const TextStyle(fontFamily: 'Roboto'),
                            )
                          : null,
                      value: _usedIngredients[index],
                      onChanged: (bool? value) {
                        setState(() {
                          _usedIngredients[index] = value!;
                        });
                      },
                      activeColor: const Color(0xFF2E7D32),
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: widget.onConfirm,
              child: const Text(
                'Confirm and Update Pantry',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
