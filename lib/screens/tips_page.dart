import 'package:flutter/material.dart';

class TipsPage extends StatelessWidget {
  const TipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> tips = [
      {
        'title': 'Know your food labels',
        'subtitle':
            'Not sure what "Best Before" really means? Read labels the right way so you don\'t toss food too early.',
        'details':
            'Food labels provide important info like expiry dates, storage instructions, and nutritional values. "Best Before" = quality; "Use By" = safety.',
      },
      {
        'title': 'How to Store This Properly',
        'subtitle':
            'Keep your food fresh for longer! Find out where and how to store each item the smart way.',
        'details':
            'Proper storage prevents spoilage. Keep potatoes in a cool dark place, bread in a breadbox, leafy greens in the fridge with a damp paper towel.',
      },
      {
        'title': 'Search pantry item’s nutrition facts',
        'subtitle':
            'Want to know what’s in your food? Quickly check the nutrition info to stay on top of your health goals.',
        'details':
            'Checking nutrition facts helps you make informed choices. Compare sugar, sodium, and fats to choose healthier options.',
      },
      {
        'title': 'How to Use This Before It Expires',
        'subtitle':
            'Running out of time? Get quick ideas on how to use up items before they go bad.',
        'details':
            'Use soon-to-expire items in soups, smoothies, or baked goods. Freeze portions if you can’t finish them in time.',
      },
      {
        'title': 'Tips to Reduce Food Waste',
        'subtitle':
            'Small changes make a big difference. Try these simple tips to waste less and save more.',
        'details':
            'Plan meals, store food properly, and use leftovers creatively. Donate excess food where possible.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 15),
          child: Text(
            'Tips & Suggestions',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: tips.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final t = tips[index];
              return _buildTipCard(
                context,
                t['title']!,
                t['subtitle']!,
                t['details']!,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTipCard(
    BuildContext context,
    String title,
    String subtitle,
    String details,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TipDetailPage(title: title, details: details),
          ),
        );
      },
      child: Card(
        color: const Color(0xFFB2DF8A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TipDetailPage extends StatelessWidget {
  final String title;
  final String details;

  const TipDetailPage({super.key, required this.title, required this.details});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBE6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          details,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
      ),
    );
  }
}