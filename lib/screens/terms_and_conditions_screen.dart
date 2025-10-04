import 'package:flutter/material.dart';
import 'package:shelf_control/screens/feature_preview_screen.dart';
import 'package:shelf_control/screens/privacy_policy_screen.dart';
class TermsAndConditionsScreen extends StatelessWidget {
  final bool fromGuestFlow;
  const TermsAndConditionsScreen({super.key, this.fromGuestFlow = false});

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
                      MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                    );
                  } else {
                    Navigator.pop(context, false); // Return false when going back
                  }
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Terms and Conditions',
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '1. Confidentiality:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Your personal data, including pantry items and meal preferences, will be kept strictly confidential. We employ robust encryption and access controls to protect your information from unauthorized access, disclosure, alteration, and destruction. We will not share your data with third parties without your explicit consent, except as required by law.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '2. Integrity:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'We are committed to maintaining the accuracy and completeness of your data. All information you provide will be stored and processed in a manner that prevents unauthorized modification or deletion. We use data validation and backup procedures to ensure the integrity of your records.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '3. Availability:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'We strive to ensure that ShelfControl is accessible and operational whenever you need it. We utilize redundant systems and disaster recovery plans to minimize downtime and ensure continuous access to your pantry tracking, grocery planner, and meal suggestion features. While we aim for 24/7 availability, occasional maintenance or unforeseen circumstances may lead to temporary interruptions, which we will communicate in advance whenever possible.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Usage Rules:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          '- Do not use the app for any unlawful purposes.\n'
                          '- Do not attempt to disrupt the app\'s services or data.\n'
                          '- No spam, no resale of data.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          'Disclaimers:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'The app is provided "as is" without any warranties. We are not responsible for any loss or damage arising from your use of the app.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          'Responsibilities:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'You are responsible for maintaining the confidentiality of your account information and for all activities that occur under your account.',
                          style: TextStyle(fontSize: 16),
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
                      MaterialPageRoute(builder: (context) => const FeaturePreviewScreen()),
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
