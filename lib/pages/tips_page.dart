import 'package:flutter/material.dart';
import 'package:shelfcontrol/pages/notification_settings_page.dart';
import 'package:shelfcontrol/pages/profile_page.dart';
import 'package:shelfcontrol/pages/user_guide_page.dart';
import 'package:shelfcontrol/pages/dashboard_page.dart'; // for Home nav

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

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBE6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.group, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),

      drawer: _buildSidePanel(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 15),
            child: Text(
              'Tips & Suggestions',
              style: TextStyle(
                fontSize: 33,
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
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF2E7D32),
        shape: const CircularNotchedRectangle(),
        notchMargin: 10.0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navBarItem(Icons.home, "Home", () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardPage()),
                  (route) => false,
                );
              }),
              _navBarItem(Icons.kitchen, "Pantry", () {}),
              const SizedBox(width: 49), // space for the FAB
              _navBarItem(Icons.shopping_cart, "Shopping List", () {}),
              _navBarItem(Icons.lightbulb, "Tips", () {}),
            ],
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        width: 80,
        height: 80,
        child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: Colors.white,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 36, color: Color(0xFF2E7D32)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _navBarItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 26),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
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

  Widget _buildSidePanel(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF2E7D32),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          children: [
            const Text(
              "ShelfControl",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            _drawerItem(Icons.person, "Profile", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            }),
            _drawerItem(Icons.notifications, "Notification Settings", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsPage(),
                ),
              );
            }),
            _drawerItem(Icons.delete, "Waste Tracker", () {}),
            _drawerItem(Icons.info, "User Guide", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserGuidePage()),
              );
            }),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.feedback, color: Colors.white),
              title: const Text(
                "Feedback",
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                "We would love to hear from you.",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              onTap: () {},
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: const StadiumBorder(),
              ),
              child: const Text("Email Us"),
            ),
            const SizedBox(height: 16),
            _drawerItem(Icons.description, "Terms and Conditions", () {}),
            _drawerItem(Icons.privacy_tip, "Privacy Policy", () {}),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: const StadiumBorder(),
              ),
              child: const Text(
                "Log Out",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
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
