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
                          'The Republic Act No. 10173 or Data Privacy Act (DPA) of 2012 (and its Implementing Rules and Regulations) are implemented by the National Privacy Commission (NPC).',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          'This Privacy Policy defines how the developers of ShelfControl (“we,” “us,” “our”) collect, use, store, and protect personal information in accordance with the Data Privacy Act of 2012 (RA 10173), its Implementing Rules and Regulations, and the privacy principles outlined in ISO/IEC 29100. It applies to all users of the ShelfControl mobile application and to all personal data processed through its associated Firebase infrastructure and third-party integrations.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '1. Data Privacy Principles (DPA General Principles)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Under processing your data, we follow the following principles:',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Transparency: You understand the nature, purpose and scope of the processing of personal data.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Legitimate Purpose: Your data is used to work only on the declared, specified and lawful purposes that are directly connected with the functioning of ShelfControl.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Proportionality: Only the data are collected and kept in amounts that are sufficient, relevant, suitable, and necessary to achieve the stated purposes.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '2. Personal Information Collected and Processed',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'We will only store and process your personal information when it is needed as per the main functionality of the ShelfControl application.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          'Category of Personal Data\nSpecific Data Collected\nSource of Data\nLegal Justification of Processing (DPA)\nPurpose',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Identifiers\nEmail Address\nDirectly from the User (Account Registration)\nContractual Necessity\nAccount creation and authentication',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Pantry Data (Content Data)\nName of Pantry Item, Quantity, Storage Place, Expiration Date\nDirectly from the User (Manual Entry/Scanning)\nContractual Necessity\nCore service for inventory tracking',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Technical Data\nDevice ID (e.g., Firebase ID), IP Address, App Usage/Crash Logs\nBy default by Third-Party SDKs (Firebase)\nLegitimate Interest\nSecurity and performance',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Optional Data\nPhotos of Pantry Item (if enabled)\nDirectly from the User (Camera/Gallery Access)\nData Subject Consent\nPhysical identification of items',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '3. Purpose and Use of Collected Data (Legitimate Purpose)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'The data that we process is solely used to meet the following purposes that were announced:',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          'Purpose Category\nSpecific Use of Data',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Core Service Functionality\nTo allow you to log in and out of different accounts, synchronize across the devices regarding pantry items in a single or multiple households, and receive alerts when something is about to expire.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'App Performance & Improvement\nTo examine the anonymized and aggregated usage data to detect the software bugs, enhance the stability of the application, and optimize the user interface.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Security and Fraud Prevention\nTo control and detect fraud or illegal use of the ShelfControl service.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Legal Compliance\nTo act in a way that would fulfill any legal requirement, such as the need to act on a lawful request by the National Privacy Commission (NPC) or a court of competent jurisdiction.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '4. Third-Party Data Sharing (Transparency and Accountability)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'ShelfControl uses external processors bound by Data Processing Agreements compliant with RA 10173 (Section 20) and ISO 27018',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          'Third-Party Service\nData Handled\nPurpose\nSafeguards',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Google Firebase\nEncrypted identifiers and inventory records\nAuthentication, cloud hosting, storage\nISO 27001/SOC 2 certified; Standard Contractual Clauses applied',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Open Food Facts\nNon-personal food names only\nPublic food metadata lookup\nData minimization',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          'Cross-border data transfers occur only where adequate protection is ensured through binding corporate rules or standard contractual clauses.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '5. Security Measures and Data Retention',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'A. Data Security',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'ShelfControl shall implement prudent and suitable organizational, physical, and technical security measures to ensure that your personal information is not lost, modified, and disclosed due to an accident or illegally. These measures include:',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Encryption: Data is encrypted during transmission (through SSL/TLS) and at rest (Firebase).',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Access Controls: The database is accessed and only authorized development personnel can access it using Multi-Factor Authentication (MFA) based access controls (need to know).',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          'B. Data Retention and Disposal',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Data Type\nRetention Period\nDisposal Method',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Account Data\nUntil user requests deletion or after 12 months of inactivity\nLogical deletion; 30-day purge',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Pantry and Household Data\nWhile account active + 90 days backup\nAutomated purge scripts',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Audit and Usage Logs\n12 months from creation\nOverwrite via log rotation',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Optional Images\nUser deletion or 90 days post deactivation\nSecure Cloud erase API',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          'After expiry, data are permanently and irreversibly deleted using Firebase’s secure erasure mechanisms.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '6. Rights of Data Subject (DPA Rights)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Under RA 10173 (Section 16) and ISO 29100 Clause 5, users have the right to:',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Right to be Informed: You have the right to know whether personal data about you is being or has been processed.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Right to Object: You have the right to object to the processing of your data, such as processing of your data to direct marketing or profiling.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Right to Access: You have the right to access your personal data in a reasonable manner.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Right to Rectification: You have a right to challenge the incorrectness or inaccuracy of your personal data and ask it to be corrected.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Right to Erasure or Blocking (Right to be Forgotten): You have a right to suspend, withdraw or command the blocking, removal, or destruction of your personal data under the conditions set by law.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Right to Data Portability: You have the right to receive a copy of your personal data in electronic form or structured format.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Right to Claim Damages: You may claim damages on any damages that are caused by untrue, incomplete, outdated, false, illegally acquired or unauthorised use of your personal data.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Requests shall be addressed to the Data Protection Officer. \nShelfControl shall respond within 30 days of receipt, subject to identity verification.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '7. Consent and Withdrawal',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Consent is obtained electronically when users register or enable optional features. Users may withdraw consent at any time through the app’s Privacy Settings or by emailing the DPO. Upon withdrawal, optional data will be deleted and related functions disabled. Core processing necessary for account operation continues under contractual basis.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '8. Policy Updates and Notification',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'This Policy is reviewed monthly or upon significant system changes. All updates will be announced via registered email at least 15 days before effectivity. Version history is maintained in the project repository and documentation.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '9. Compliance Monitoring',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'The ShelfControl Development Team shall conduct periodic internal privacy audits to verify adherence to this policy and to NPC guidelines. Any incident of breach will be reported to the NPC and affected users within 72 hours of confirmation, in line with NPC Circular 16-03.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '10. Contact & Inquiries',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Data Protection Officer (DPO): Luis Daniel Enriquez\nEmail: shelfcontrol9@gmail.com\nInstitution: Polytechnic University of the Philippines – Sta. Mesa\nNPC Complaint Channel: https://privacy.gov.ph/filing-a-complaint/',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '11. Ethical and Research Use Declaration',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'ShelfControl commits to use aggregated and anonymized data only for legitimate research purposes approved under institutional ethical review. No personally identifiable information shall be used in publications or analyses without explicit consent.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 15),
                        Text(
                          '12. Acknowledgement',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'By installing or using ShelfControl, the user acknowledges that they have read, understood, and agreed to this Privacy Policy and that their data will be processed in accordance with the Data Privacy Act of 2012 and applicable international standards.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Approved by the ShelfControl Development Team (Version 1.0, October 2025)',
                          style: TextStyle(fontSize: 14, color: Colors.black),
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
