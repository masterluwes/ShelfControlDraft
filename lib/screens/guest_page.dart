import 'package:flutter/material.dart';
import 'package:shelf_control/screens/create_account_page.dart';
import 'package:shelf_control/screens/dashboard_page.dart';
import 'package:shelf_control/screens/privacy_policy_screen.dart'; // Import Privacy Policy screen
import 'package:shelf_control/screens/terms_and_conditions_screen.dart'; // Import Terms and Conditions screen
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:shelf_control/services/guest_auth_service.dart'; // Import GuestAuthService

class GuestPage extends StatefulWidget {
  const GuestPage({super.key});

  @override
  State<GuestPage> createState() => _GuestPageState();
}

class _GuestPageState extends State<GuestPage> {
  bool _agreedToPrivacyPolicy = false;
  bool _agreedToTermsAndConditions = false;
  bool _isLoading = false;

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

              const SizedBox(height: 20),
              // Privacy Policy Checkbox
              Row(
                children: [
                  Checkbox(
                    value: _agreedToPrivacyPolicy,
                    onChanged: (bool? newValue) {
                      setState(() {
                        _agreedToPrivacyPolicy = newValue ?? false;
                      });
                    },
                    activeColor: const Color(0xFF2E7D32),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                        );
                        if (result == true) {
                          setState(() {
                            _agreedToPrivacyPolicy = true;
                          });
                        }
                      },
                      child: const Text.rich(
                        TextSpan(
                          text: 'I agree to the ',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                          children: [
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: Color(0xFF2E7D32),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Terms and Conditions Checkbox
              Row(
                children: [
                  Checkbox(
                    value: _agreedToTermsAndConditions,
                    onChanged: (bool? newValue) {
                      setState(() {
                        _agreedToTermsAndConditions = newValue ?? false;
                      });
                    },
                    activeColor: const Color(0xFF2E7D32),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TermsAndConditionsScreen()),
                        );
                        if (result == true) {
                          setState(() {
                            _agreedToTermsAndConditions = true;
                          });
                        }
                      },
                      child: const Text.rich(
                        TextSpan(
                          text: 'I agree to the ',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                          children: [
                            TextSpan(
                              text: 'Terms and Conditions',
                              style: TextStyle(
                                color: Color(0xFF2E7D32),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: (_agreedToPrivacyPolicy && _agreedToTermsAndConditions && !_isLoading)
                      ? () async {
                          setState(() {
                            _isLoading = true;
                          });
                          try {
                            UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();
                            if (userCredential.user != null) {
                              await GuestAuthService.saveGuestUid(userCredential.user!.uid);
                            }
                            if (mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const DashboardPage(isGuest: true)),
                              );
                            }
                          } catch (e) {
                            // Handle error
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
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
