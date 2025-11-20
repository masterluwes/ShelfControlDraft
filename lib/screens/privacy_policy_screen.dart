import 'package:flutter/material.dart';
import 'package:shelf_control/screens/terms_and_conditions_screen.dart';
import 'package:shelf_control/screens/privacy_overview_screen.dart';
import 'package:shelf_control/services/legal_service.dart'; // Import LegalService
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart'; // Import flutter_markdown_plus

class PrivacyPolicyScreen extends StatefulWidget {
  final bool fromGuestFlow;
  const PrivacyPolicyScreen({super.key, this.fromGuestFlow = false});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  final LegalService _legalService = LegalService();
  String _policyContent = 'Loading privacy policy...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPolicy();
  }

  Future<void> _fetchPolicy() async {
    try {
      String content = await _legalService.getLegalDocument('privacy_policy');
      setState(() {
        _policyContent = content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _policyContent = 'Failed to load privacy policy: $e';
        _isLoading = false;
      });
    }
  }

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
                  if (widget.fromGuestFlow) {
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
              // const Text(
              //   'Last Updated: October 2025 \nEffective Date: October 12, 2025', // This will be part of the markdown
              //   style: TextStyle(fontSize: 16, color: Colors.grey),
              // ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(15.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : MarkdownBody(
                            data: _policyContent,
                            styleSheet: MarkdownStyleSheet(
                              h1: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
                              h2: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                              h3: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                              h4: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                              p: const TextStyle(fontSize: 16, color: Colors.black),
                              strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                              listBullet: const TextStyle(fontSize: 16, color: Colors.black),
                              tableBody: const TextStyle(fontSize: 14, color: Colors.black),
                              tableHead: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
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
                  if (widget.fromGuestFlow) {
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
