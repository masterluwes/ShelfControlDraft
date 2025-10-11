import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelf_control/screens/recipedetails.dart';
import 'package:shelf_control/screens/mealhistory.dart';
import 'package:shelf_control/services/meal_planner.dart';
import 'package:shelf_control/services/firestore_service.dart'; // Import FirestoreService
import 'package:provider/provider.dart'; // Import Provider


// ===== CONFIG =====
const double kMinCoverageToShow = 0.5; // 50% pantry coverage
const List<String> kStaples = [
  'water',
  'salt',
  'pepper',
  'cooking oil',
  'oil',
  'sugar',
];

// --- Data Model for a Recipe (kept as your original STRING fields) ---
class Recipe {
  final String name;
  final String imageUrl;
  final String servingSize;
  final String calories;
  final String time;
  final String description;
  final List<Map<String, String>> ingredients;
  final List<String> directions;
  final String difficulty;

  const Recipe({
    required this.name,
    required this.imageUrl,
    required this.servingSize,
    required this.calories,
    required this.time,
    required this.description,
    required this.ingredients,
    required this.directions,
    this.difficulty = 'Easy',
  });

  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // — helpers —
    String asString(dynamic v) => v == null ? '' : v.toString();

    List<Map<String, String>> parseIngredients(dynamic raw) {
      final out = <Map<String, String>>[];

      if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            final m = item
                .map((k, v) => MapEntry(k.toString(), (v ?? '').toString()));
            out.add({
              'name': (m['name'] ?? '').toString(),
              'amount': (m['amount'] ?? '').toString(),
            });
          } else if (item is String) {
            // Allow list of plain strings
            out.add({'name': item, 'amount': ''});
          } else {
            // Unknown entry type -> skip
          }
        }
      } else if (raw is Map) {
        // Some folks store ingredients as a map of name -> amount
        raw.forEach((k, v) {
          out.add({'name': k.toString(), 'amount': (v ?? '').toString()});
        });
      } else if (raw is String) {
        // Split by newlines or commas
        final parts = raw
            .split(RegExp(r'[\r\n,]+'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty);
        for (final p in parts) {
          out.add({'name': p, 'amount': ''});
        }
      }
      return out;
    }

    List<String> parseDirections(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => e.toString()).toList();
      } else if (raw is String) {
        // Split multiline into steps
        return raw
            .split(RegExp(r'[\r\n]+'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return const [];
    }

    final ingredients = parseIngredients(data['ingredients']);
    final directions = parseDirections(data['directions']);

    return Recipe(
      name: asString(data['name']),
      imageUrl: asString(data['imageUrl']),
      servingSize: asString(data['servingSize']),
      calories: asString(data['calories']),
      time: asString(data['time']),
      description: asString(data['description']),
      ingredients: ingredients,
      directions: directions,
    );
  }
}

// --- Main Widget (same UI as yours, but dynamic) ---
class MealSuggest extends StatefulWidget {
  const MealSuggest({super.key});

  @override
  State<MealSuggest> createState() => _MealSuggestState();
}

class _MealSuggestState extends State<MealSuggest> {
  bool _refreshing = false;
  late FirestoreService _firestoreService; // Declare FirestoreService

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
  }

  // Normalization helpers
  String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  bool _isOptionalLine(String ingredientName) {
    final n = _norm(ingredientName);
    if (n.contains('optional')) return true;
    return kStaples.contains(n);
  }

  // Returns (coverage: 0..1, missingNames)
  (double, List<String>) _coverage(Recipe r, Map<String, num> pantryCounts) {
    final ingr = r.ingredients;
    if (ingr.isEmpty) return (0, const []);

    int requiredCount = 0;
    int haveCount = 0;
    final missing = <String>[];

    for (final line in ingr) {
      final rawName = (line['name'] ?? '').toString();
      final name = _norm(rawName);
      if (name.isEmpty) continue;

      final isOptional = _isOptionalLine(name);
      if (!isOptional) requiredCount++;

      final hasIt = pantryCounts.entries.any((e) {
        final pn = _norm(e.key);
        final qty = e.value;
        return qty > 0 &&
            (pn == name || pn.contains(name) || name.contains(pn));
      });

      if (hasIt) {
        haveCount++;
      } else if (!isOptional) {
        missing.add(rawName);
      }
    }

    final denom = requiredCount == 0 ? ingr.length : requiredCount;
    final coverage =
        denom == 0 ? 1.0 : (haveCount / denom).clamp(0, 1).toDouble();

    return (coverage, missing);
  }

  Future<void> _manualRefresh() async {
    setState(() => _refreshing = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    const Color pageBg = Color(0xFFFFFBE6);
    const Color greenAccent = Color(0xFF2E7D32);

    // Streams
    final pantryStream = _firestoreService.selectedHouseholdId == null
        ? FirebaseFirestore.instance
            .collection(
                'non_existent_pantry_items') // Query a collection that will always be empty
            .snapshots()
        : FirebaseFirestore.instance
            .collection('pantries')
            .doc(_firestoreService.selectedHouseholdId!)
            .collection('pantryItems')
            .snapshots();

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        elevation: 1,
        shadowColor: Colors.grey.shade300,
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
          IconButton(
            icon: _refreshing
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator())
                : const Icon(Icons.refresh),
            onPressed: _manualRefresh,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const MealHistoryPage()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: pantryStream,
        builder: (context, pantrySnap) {
          if (pantrySnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (pantrySnap.hasError) {
            return Center(
                child: Text('Error loading pantry: ${pantrySnap.error}'));
          }
          if (!pantrySnap.hasData) {
            return const Center(child: Text('No pantry data.'));
          }

          // 1) Build pantry items from Firestore snapshot (filters expired/consumed inside)
          final pantryItems = MealPlanner.fromSnapshot(pantrySnap.data!);

          // 2) Generate suggestions from pantry (near-expiry prioritized, <=2 missing)
          final suggestions = MealPlanner.generate(
            pantry: pantryItems,
            nearExpiryDays: 5,
            maxMissing: 2,
            maxResults: 12,
          );

          // 3) Map to your existing Recipe model (string fields)
          final suggested = suggestions
              .map((s) => Recipe(
                    name: s.name,
                    imageUrl: s.imageUrl,
                    servingSize: s.servingSize,
                    calories: s.calories,
                    time: s.time,
                    description: s.description,
                    ingredients: s.ingredients,
                    directions: s.directions,
                    difficulty: s.difficulty, // ✅ dynamically assigned
                  ))
              .toList();

          // 4) Build the UI (same layout you already use)
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildNoteBanner(),
                  const SizedBox(height: 20),
                  if (suggested.isEmpty)
                    const Text('No suggestions yet. Add more pantry items!')
                  else
                    ...suggested.map(
                        (r) => _buildMealCard(context: context, recipe: r)),
                ],
              ),
            ),
          );
        },
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
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: Color(0xFF2E7D32)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discover delicious recipes using the ingredients you already have at your pantry inventory!',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: Color(0xFF595959),
                    ),
                    children: [
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
