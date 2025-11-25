// lib/pages/cooking_view.dart

import 'package:flutter/material.dart';
import 'package:shelf_control/screens/mealsuggest.dart'; // To access the Recipe model
import 'package:shelf_control/screens/mealhistory.dart'; // Import the MealHistoryPage
import 'package:provider/provider.dart';
import 'package:shelf_control/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelf_control/screens/pantryinventory.dart';
import 'package:shelf_control/models/meal_history_model.dart';
import 'package:shelf_control/screens/dashboard_page.dart';

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

String _toTitleCase(String text) {
  return text
      .split(' ')
      .map((w) => w.isEmpty
          ? w
          : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');
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
    final ingLen = widget.recipe.ingredients.length;
    _checkedIngredients = List<bool>.filled(ingLen, false);
  }

  @override
  void didUpdateWidget(covariant CookingViewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If ingredients list changes (hot reload / different recipe), keep lengths in sync.
    final ingLen = widget.recipe.ingredients.length;
    if (_checkedIngredients.length != ingLen) {
      _checkedIngredients = List<bool>.filled(ingLen, false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _toTitleCase(String text) {
    return text
        .split(' ')
        .map((w) => w.isEmpty
            ? w
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  bool _areAllRequiredIngredientsDone() {
    for (int i = 0; i < widget.recipe.ingredients.length; i++) {
      final ingredientName =
          widget.recipe.ingredients[i]['name']!.toLowerCase();
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
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
      bottomNavigationBar: _buildBottomCTA(), // <-- NEW
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
        Builder(
          builder: (context) {
            final String img = (widget.recipe.imageUrl).trim();
            const String fallbackAsset = 'assets/meals.jpg';

            final bool isAsset = img.startsWith('assets/');
            final bool isHttp =
                img.startsWith('http://') || img.startsWith('https://');

            if (isAsset) {
              return Image.asset(
                img,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                  fallbackAsset,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              );
            } else if (isHttp) {
              return Image.network(
                img,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                  fallbackAsset,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              );
            } else {
              return Image.asset(
                fallbackAsset,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
              );
            }
          },
        ),

        // --- keep your existing overlays below ---
        Positioned.fill(
          child: Container(
            height: 250,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.0),
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          left: 16,
          top: 160, // adjust if you want higher/lower
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
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
                  '${widget.recipe.time}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        Positioned(
          left: 16,
          bottom: 16,
          right: 16,
          child: Text(
            widget.recipe.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
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
        final name = ingredient['name'] ?? '';
        return CheckboxListTile(
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            _toTitleCase(name.trim()),
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

  Widget _buildBottomCTA() {
    final isDone = _areAllRequiredIngredientsDone();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                    _isConfirming = true; // <-- this will show the overlay
                  });
                }
              : null,
          child: Text(
            isDone ? 'Done Cooking' : 'Check required ingredients to continue',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationOverlay() {
    if (!_isConfirming)
      return const SizedBox.shrink(); // <-- do not render at all

    return Stack(
      children: [
        // Dim background
        GestureDetector(
          onTap: () {
            setState(() {
              _isConfirming = false;
            });
          },
          child: Container(color: Colors.black.withOpacity(0.5)),
        ),
        // Bottom sheet-style card
        Align(
          alignment: Alignment.bottomCenter,
          child: _ConfirmationCard(
            recipe: widget.recipe,
            onConfirm: () {},
          ),
        ),
      ],
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
  bool _isDone = false;

  @override
  void initState() {
    super.initState();
    _usedIngredients = List<bool>.filled(
      widget.recipe.ingredients.length,
      true,
    );
  }

  Future<void> _deductPantryItems() async {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final householdId = firestore.selectedHouseholdId;

    if (householdId == null) return;

    // Get pantry list from this household
    final pantryList = await firestore.getPantryForHousehold(householdId);

    for (int i = 0; i < widget.recipe.ingredients.length; i++) {
      if (!_usedIngredients[i]) continue; // only deduct if checkbox is checked

      final ingredient = widget.recipe.ingredients[i];
      final ingName = ingredient['name']!.toLowerCase();

      final matchingItems = pantryList.where(
        (p) => p.name.toLowerCase().trim() == ingName.trim(),
      );

      if (matchingItems.isEmpty) {
        continue; // no match found → skip safely
      }

      final match = matchingItems.first;

      final newQty = match.qty - 1;

// Correct Firestore path
      final docRef =
          FirebaseFirestore.instance.collection('pantryItems').doc(match.id);

      if (newQty <= 0) {
        await docRef.delete();
      } else {
        await docRef.update({'qty': newQty});
      }
    }
  }

  Future<void> _saveMealHistory() async {
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    // Try to parse numbers, but fall back safely
    final servings = int.tryParse(widget.recipe.servingSize) ?? 1;
    final duration = int.tryParse(widget.recipe.time) ?? 0;

    final meal = MealHistory(
      householdId: firestore.selectedHouseholdId ?? "",
      recipeName: widget.recipe.name,
      difficulty: 'Not specified', // Recipe has no difficulty field
      servings: servings, // from servingSize
      calories: widget.recipe.calories, // already a String
      durationMinutes: duration,
      cookedAt: DateTime.now(),
      ingredients: widget.recipe.ingredients, // List<Map<String, String>>
    );

    await firestore.db.collection('mealHistory').add(meal.toFirestore());
  }

  Future<void> _onDoneCooking() async {
    try {
      await _deductPantryItems();
      await _saveMealHistory();

      setState(() {
        _isDone = true;
      });

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const DashboardPage(
            initialIndex: 1, // 0 = DashboardHome, 1 = REAL Pantry tab
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                        _toTitleCase((ingredient['name'] ?? '').trim()),
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
              onPressed: _onDoneCooking,
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
