import 'package:flutter/material.dart';
import 'package:shelf_control/screens/privacy_policy_screen.dart'; // Import the Privacy Policy screen
import 'package:shelf_control/screens/guest_page.dart';

class PrivacyOverviewScreen extends StatelessWidget {
  final bool fromGuestFlow;
  const PrivacyOverviewScreen({super.key, this.fromGuestFlow = false});

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
                    MaterialPageRoute(builder: (context) => const GuestPage()),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Your Data, Your Control',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF228B22), // Forest Green
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'We believe your pantry data should stay private.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              _buildPrivacySection(
                icon: Icons.search,
                heading: 'What We Collect',
                description: 'We only collect what’s needed — like your email and pantry items.',
              ),
              const SizedBox(height: 20),
              _buildPrivacySection(
                icon: Icons.track_changes,
                heading: 'Why We Collect It',
                description: 'To help you track food, plan meals, and avoid waste.',
              ),
              const SizedBox(height: 20),
              _buildPrivacySection(
                icon: Icons.security,
                heading: 'How We Protect It',
                description: 'Your data is encrypted and stored securely using Firebase.',
              ),
              const SizedBox(height: 20),
              _buildPrivacySection(
                icon: Icons.settings,
                heading: 'Your Control',
                description: 'You can view, edit, or delete your data anytime from your profile.',
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF228B22), // Forest Green
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => PrivacyPolicyScreen(fromGuestFlow: true)),
                  );
                },
                child: const Text('Continue'),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'You’ll see our full Privacy Policy next.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacySection({
    required IconData icon,
    required String heading,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF228B22), size: 30), // Forest Green
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                heading,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF228B22), // Forest Green
                ),
              ),
              const SizedBox(height: 5),
              Text(
                description,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
