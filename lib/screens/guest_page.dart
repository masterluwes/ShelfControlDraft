import 'package:flutter/material.dart';
import 'package:shelf_control/screens/create_account_page.dart';
import 'package:shelf_control/screens/privacy_overview_screen.dart';
import 'package:shelf_control/screens/dashboard_page.dart';

class GuestPage extends StatelessWidget {
  const GuestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF9E7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),
              const Center(
                child: Text(
                  "Continue as Guest",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                    color: Color(0xFF347928),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Text(
                  "Your data won't be saved permanently. Create an account anytime to keep your pantry info safe and synced!",
                  style: TextStyle(fontSize: 15, color: Color(0xFF6D845F)),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 32),
              Center(
                child: Image.asset(
                  'assets/guest_illustration.png',
                  height: 250,
                ),
              ),

              const SizedBox(height: 40),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to a guest-specific dashboard or a modified dashboard
                    // that uses local storage. For now, let's assume a new GuestDashboardPage.
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const DashboardPage(isGuest: true)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Proceed",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Row(
                children: [
                  Expanded(child: Divider(color: Color(0xFF2E7D32))),
                  SizedBox(width: 10),
                  Text("OR", style: TextStyle(color: Color(0xFF2E7D32))),
                  SizedBox(width: 10),
                  Expanded(child: Divider(color: Color(0xFF2E7D32))),
                ],
              ),

              const SizedBox(height: 20),
              Center(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const CreateAccountPage()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Sign Up",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
