// lib/pages/mealhistory.dart

import 'package:flutter/material.dart';
import 'package:guests_main/pages/mealsuggest.dart'; // Import the Recipe model

class MealHistoryPage extends StatefulWidget {
  const MealHistoryPage({super.key});

  // STATIC LIST TO STORE MEAL HISTORY
  // This list will hold the recipes that the user has "cooked".
  static final List<Recipe> mealHistory = [];

  @override
  State<MealHistoryPage> createState() => _MealHistoryPageState();
}

class _MealHistoryPageState extends State<MealHistoryPage> {
  // State to track if we are in "delete mode"
  bool _isDeleting = false;

  // Function to handle deleting an item
  void _deleteItem(int index) {
    // Save the item and its original index before removing
    final removedRecipe = MealHistoryPage.mealHistory.removeAt(index);
    setState(() {}); // Update the UI to reflect the removal

    // Clear any previous SnackBars
    ScaffoldMessenger.of(context).clearSnackBars();
    // Show a SnackBar with an Undo button
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${removedRecipe.name} removed.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // If undo is pressed, re-insert the item at its original position
            setState(() {
              MealHistoryPage.mealHistory.insert(index, removedRecipe);
            });
          },
        ),
      ),
    );
  }

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
          'Meal History',
          style: TextStyle(
            fontFamily: 'Inter',
            color: greenAccent,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          // This button now toggles the delete mode
          IconButton(
            icon: Icon(_isDeleting ? Icons.close : Icons.delete_outline),
            tooltip: _isDeleting ? 'Done' : 'Delete meals',
            onPressed: () {
              setState(() {
                _isDeleting = !_isDeleting;
              });
            },
          ),
        ],
      ),
      body: MealHistoryPage.mealHistory.isEmpty
          ? const Center(
              child: Text(
                'No meals in your history yet.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: MealHistoryPage.mealHistory.length,
              itemBuilder: (context, index) {
                final recipe = MealHistoryPage.mealHistory[index];
                return _buildHistoryItem(
                  recipe: recipe,
                  // Pass the delete function to the item card
                  onDelete: () => _deleteItem(index),
                );
              },
            ),
    );
  }

  Widget _buildHistoryItem({
    required Recipe recipe,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFF2E7D32)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          12,
          12,
          4,
          12,
        ), // Adjust right padding for icon
        child: Row(
          children: [
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
                  const SizedBox(height: 6),
                  Text(
                    'Cooked on: ${DateTime.now().month}/${DateTime.now().day}/${DateTime.now().year}',
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
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
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Conditionally show the delete button if in delete mode
            if (_isDeleting)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}
