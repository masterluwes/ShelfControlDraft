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
                'Last Updated: October 2025 \nEffective Date: October 12, 2025',
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
                          '1. Agreement and Acceptance of Terms',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'The Terms and Conditions (the Terms) are a legally binding contract between the user and the ShelfControl Team (Company, we, us or our) with regards to your usage of and access to the ShelfControl mobile application (the App).',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          'BY ACCESSING OR USING SHELFCONTROL, YOU ACKNOWLEDGE THAT YOU HAVE READ, UNDERSTOOD, AND AGREED TO BE BOUND BY THESE TERMS AND CONDITIONS. IN CASE YOU DISAGREE WITH ALL THESE TERMS THEN YOU SHALL NOT ACCESS OR USE THE APP.',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '2. Privacy and Data Principles',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'All collection and processing of personal information shall comply with Republic Act No. 10173 (Data Privacy Act of 2012) and the ShelfControl Privacy Policy available at [insert URL]. ShelfControl shall uphold the principles of confidentiality, integrity, availability, accuracy, security, and accountability in all processing activities.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          'Principle\nCommitment',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Confidentiality\nNo personal information (including pantry items) will be shared with unauthorized third parties unless you expressly agree that the data is shared, as per the law.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Integrity\nWe keep our security and backup procedures reasonable and appropriate so as to make sure that your records are accurate and complete.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Availability\nWe aim to make sure that the ShelfControl App is available and working. It will inform anticipated disruptions or significant maintenance beforehand when feasible.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '3. User Accounts and Responsibilities',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'All activities that take place on your account are of your responsibility. \nAccount Confidentiality: It is your duty to keep your login information and password confidential.\nPrompt Reporting: You should immediately notify us through the prompt notification about any known or suspected unauthorized use or a breach of security with respect to your account.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          'You are responsible for all actions performed under your account, whether by you or an authorized household member. You shall promptly notify ShelfControl at shelfcontrol9@gmail.com upon discovery of unauthorized access. Failure to do so may result in suspension for security purposes.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '4. Usage Rules and Prohibited Activities',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'You are granted a limited, non-exclusive, non-transferable, revocable license to use the App solely for personal household management.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          'You agree not to:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Any use of the App in a manner which is unlawful or against any law in the Republic of the Philippines.\nAlter, disrupt, or disrupt the services, data or the host networks of the App.\nInterfere with the services, data of the App, such as by introducing viruses, denial-of-service attacks, or use of automated systems to harvest data (No scraping).\nSend spam, abuse, harass or solicit fellow users of the App.\nResell, license or otherwise utilize any information or services of the App.\nAttempt to reverse engineer or decompile the App or its code.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          'Any unauthorized access, interference, or data breach attempt may constitute an offense under Republic Act No. 10175 (Cybercrime Prevention Act of 2012) and will be reported to authorities.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '5. Intellectual Property Rights',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'ShelfControl source code, features, visual interfaces, interactive elements, graphics, design, and all other related content is the property of ShelfControl Team and is under copyright in the Philippines. You receive only a restricted license to use the App; you do not obtain any rights of ownership. All rights not expressly granted are reserved. Copying, modifying, or distributing any part of ShelfControl without written authorization from the Development Team is strictly prohibited.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '6. Disclaimers and Limitation of Liability',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'A. AS IS AND AS AVAILABLE DISCLAIMER \nTHE APP IS BEING OFFERED “AS IS” AND “AS AVAILABLE” WITHOUT ANY WARRANTY OF ANY KIND. WE SPECIFICALLY DISCLAIM ANY AND ALL WARRANTIES, IMPLIED OR EXPRESSED, INCLUDING BUT NOT LIMITED TO IMPLIED WARRANTIES OF QUALITY, SUITABILITY TO A SPECIFIC PURPOSE OR NON-INFRINGEMENT.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          'B. HEALTH and SAFETY DISCLAIMER (CRITICAL) \nShelfControl is an expiry tracking assistant only, which is not a replacement to a professional food safety practice, medical guidance, or even a visual examination of food. We will not be liable to any loss or damage (including foodborne illness, financial loss, or damage to property) because you relied on the data provided by the App, expired item notifications, or did not properly inspect and store food.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          'C. LIMITATION OF LIABILITY\nTo the fullest extent allowed by Philippine Laws, ShelfControl and its Developers shall not be liable for any direct, indirect, incidental, special, or consequential damages incurred by you as a result of your use of the App, including the loss of data, technical failure or the actions of any third-party service provider.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '7. Termination',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Without any warning, we can suspend or cancel your account and prevent access to the App in case of a violation of these Terms.\nEffect of Termination: Once your account has been terminated, your right to use the App will be automatically transferred. Any data stored is going to be processed according to the Privacy Policy.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          'Upon termination, your right to use the App shall immediately cease. Data associated with the account will be handled in accordance with the ShelfControl Privacy Policy.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '8. Governing Law and Dispute Resolution',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'These Terms shall be governed by and construed in accordance with the laws of the Republic of the Philippines. Any court proceeding or legal action of any kind that comes up based on these Terms shall be initiated in an appropriate court of the Republic of Manila, Philippines.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '9. Contact Information',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'For any questions or concerns regarding these Terms, please contact us:\nEmail: shelfcontrol9@gmail.com',
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
