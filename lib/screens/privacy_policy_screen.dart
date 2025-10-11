import 'package:flutter/material.dart';
import 'package:shelf_control/screens/terms_and_conditions_screen.dart';
import 'package:shelf_control/screens/privacy_overview_screen.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  final bool fromGuestFlow;
  const PrivacyPolicyScreen({super.key, this.fromGuestFlow = false});

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
                  if (fromGuestFlow) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const PrivacyOverviewScreen()),
                    );
                  } else {
                    Navigator.pop(context, false); // Return false when going back
                  }
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Privacy Policy',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF228B22), // Forest Green
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Last Updated June 2025',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(15.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'We collect only what’s needed to help you manage your pantry.',
                          style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '1. What Data is Collected:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'We collect your email address for account creation and management. We also collect data related to your pantry items (e.g., food names, quantities, expiration dates) and meal preferences to provide personalized suggestions and tracking features.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '2. Why Data is Collected:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Your data is collected to enable core app functionalities such as syncing your pantry across devices, providing timely reminders for expiring items, and generating personalized meal suggestions based on your inventory and preferences. This helps you manage your food efficiently and reduce waste.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '3. How Data is Stored:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'All your data is stored securely using Firebase, a Google-backed development platform. Firebase employs industry-standard encryption protocols to protect your data both in transit and at rest. Access to your data is strictly controlled and limited to authorized personnel only.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '4. Third-Party Services Used:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'We may integrate with third-party services like Open Food Facts to enhance our meal suggestion and food information features. When using such services, only necessary data is shared, and we ensure these partners adhere to strict privacy standards.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '5. User Rights:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'You have full control over your data. You can view, edit, or delete your personal information and pantry data at any time through your in-app profile settings. For any data-related inquiries or requests, please contact our support team.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'For our full Privacy Policy, please visit: [Link to full Privacy Policy]',
                          style: TextStyle(fontSize: 14, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
                  if (fromGuestFlow) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const TermsAndConditionsScreen(fromGuestFlow: true)),
                    );
                  } else {
                    Navigator.pop(context, true); // Return true when accepted
                  }
                },
                child: const Text('Accept'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
