import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelf_control/services/firestore_service.dart';
import 'package:provider/provider.dart';

class MealHistoryPage extends StatelessWidget {
  const MealHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final householdId = firestore.selectedHouseholdId;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBE6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFBE6),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2E7D32)),
        title: const Text(
          "Meal History",
          style: TextStyle(
            fontFamily: "Inter",
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
      ),
      body: householdId == null
          ? const Center(child: Text("No household selected"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("mealHistory")
                  .where("householdId", isEqualTo: householdId)
                  .orderBy("cookedAt", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No meals in your history yet.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final meals = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: meals.length,
                  itemBuilder: (context, index) {
                    final meal = meals[index].data() as Map<String, dynamic>;

                    return _MealHistoryCard(meal: meal);
                  },
                );
              },
            ),
    );
  }
}

class _MealHistoryCard extends StatelessWidget {
  final Map<String, dynamic> meal;
  const _MealHistoryCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF2E7D32), width: 1),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            child: Builder(
              builder: (_) {
                final img = (meal["imageUrl"] ?? "").toString().trim();

                final isAsset = img.startsWith("assets/");
                final isHttp =
                    img.startsWith("http://") || img.startsWith("https://");

                if (isAsset) {
                  return Image.asset(
                    img,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Image.asset("assets/meals.jpg", width: 90, height: 90),
                  );
                }

                if (isHttp) {
                  return Image.network(
                    img,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Image.asset("assets/meals.jpg", width: 90, height: 90),
                  );
                }

                // Fallback for unknown / empty image paths
                return Image.asset(
                  "assets/meals.jpg",
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                );
              },
            ),
          ),

          // Text info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal["recipeName"] ?? "Unknown Meal",
                    style: const TextStyle(
                      fontFamily: "Inter",
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Serving Size: ${meal["servings"]} servings • ${meal["calories"]}",
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 14, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 4),
                      Builder(
                        builder: (_) {
                          final raw = meal["durationMinutes"];
                          final int duration = raw is int
                              ? raw
                              : int.tryParse(raw?.toString() ?? '') ?? 0;

                          return Text(
                            "$duration min",
                            style: const TextStyle(fontSize: 12),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
