import 'package:flutter/material.dart';
import 'package:shelf_control/screens/dashboard_page.dart';
import 'package:shelf_control/screens/terms_and_conditions_screen.dart';

class FeaturePreviewScreen extends StatelessWidget {
  const FeaturePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC), // Beige background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF228B22)), // Forest Green
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const TermsAndConditionsScreen(fromGuestFlow: true)),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'ShelfControl let\'s you',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF228B22), // Forest Green
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  children: [
                    _buildFeatureItem(
                      imagePath: 'assets/log_items.png',
                      title: 'Log items',
                    ),
                    _buildFeatureItem(
                      imagePath: 'assets/track_pantry.png',
                      title: 'Track pantry',
                    ),
                    _buildFeatureItem(
                      imagePath: 'assets/never_miss_expiry.png',
                      title: 'Never miss expiry',
                    ),
                    _buildFeatureItem(
                      imagePath: 'assets/get_smart_storage_tips.png',
                      title: 'Get smart storage tips',
                    ),
                    _buildFeatureItem(
                      imagePath: 'assets/share_with_household.png',
                      title: 'Share with household',
                    ),
                    _buildFeatureItem(
                      imagePath: 'assets/plan_groceries.png',
                      title: 'Plan groceries',
                    ),
                    _buildFeatureItem(
                      imagePath: 'assets/see_usage_stats.png',
                      title: 'See usage stats',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const DashboardPage()),
                    );
                  },
                  icon: const Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF228B22), // Forest Green
                    ),
                  ),
                  label: const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF228B22), // Forest Green
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({required String imagePath, required String title}) {
    return Column(
      children: [
        Image.asset(imagePath, height: 100, width: 100),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
