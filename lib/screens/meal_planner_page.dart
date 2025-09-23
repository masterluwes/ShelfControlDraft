import 'package:flutter/material.dart';

class MealPlannerPage extends StatelessWidget {
  const MealPlannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Fake data for now. Swap with your own later.
    final meals = const [
      {
        'name': 'Beef Kaldereta',
        'image':
            'https://images.unsplash.com/photo-1604908554007-9e9f8b0b0f62?q=80&w=1200&auto=format&fit=crop'
      },
      {
        'name': 'Pork Steak',
        'image':
            'https://images.unsplash.com/photo-1544025162-d76694265947?q=80&w=1200&auto=format&fit=crop'
      },
      {
        'name': 'Pancit Bihon Guisado',
        'image':
            'https://images.unsplash.com/photo-1544025162-8e1ff0d3f1b1?q=80&w=1200&auto=format&fit=crop'
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F0D9), // light cream vibe
      appBar: AppBar(
  backgroundColor: const Color(0xFFF7F0D9),
  elevation: 0,
  iconTheme: const IconThemeData(color: Colors.black87),
  title: const Text(
    'Meal Planner',
    style: TextStyle(
      color: Color(0xFF2E7D32),
      fontWeight: FontWeight.w700,
    ),
  ),
  centerTitle: false,
  actions: [
    IconButton(
      tooltip: 'History',
      onPressed: () {
        // TODO: navigate to History page later.
        // Example (when ready):
        // Navigator.of(context).push(
        //   MaterialPageRoute(builder: (_) => const MealHistoryPage()),
        // );
      },
      icon: const Icon(Icons.history, color: Color(0xFF2E7D32)),
    ),
  ],
  bottom: const PreferredSize(
    preferredSize: Size.fromHeight(1),
    child: Divider(height: 1, color: Colors.black12),
  ),
),
      body: Column(
        children: [
          const SizedBox(height: 8),
          // Pills for Breakfast / Lunch / Dinner / Snack
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _MealSlot(label: 'Breakfast'),
                _MealSlot(label: 'Lunch'),
                _MealSlot(label: 'Dinner'),
                _MealSlot(label: 'Snack'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Colors.transparent),
          const SizedBox(height: 8),
          // Grid of meal cards
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                itemCount: meals.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.82,
                ),
                itemBuilder: (context, index) {
                  final meal = meals[index];
                  return _MealCard(
                    title: meal['name'] as String,
                    imageUrl: meal['image'] as String,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MealSlot extends StatelessWidget {
  final String label;
  const _MealSlot({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundColor: Color(0xFFE6E6E6), // gray placeholder
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  const _MealCard({required this.title, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // TODO: navigate to meal detail if you have it
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            AspectRatio(
              aspectRatio: 16 / 11,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.black12),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
