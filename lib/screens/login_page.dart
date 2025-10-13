import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelf_control/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shelf_control/screens/welcome_page.dart';
import 'package:shelf_control/services/firestore_service.dart'; // Import FirestoreService
import 'package:provider/provider.dart'; // Import Provider

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late AuthService _authService; // Declare as late

  String? _emailError;
  String? _passwordError;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Initialize AuthService here, after context is available
    _authService = AuthService(Provider.of<FirestoreService>(context, listen: false));
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  void _validateAndLogin() async {
    setState(() {
      _emailError = _emailController.text.isEmpty
          ? 'Email is required'
          : (!isValidEmail(_emailController.text)
                ? 'Invalid email format'
                : null);

      _passwordError = _passwordController.text.isEmpty
          ? 'Password is required'
          : (_passwordController.text.length < 8
                ? 'Password must be at least 8 characters'
                : null);
    });

    if (_emailError == null && _passwordError == null) {
      try {
        UserCredential userCredential = await _authService.signInWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
        );

        // Update user details in Firestore upon successful login
        if (userCredential.user != null) {
          await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set(
            {
              'email': userCredential.user!.email,
              'lastLoginAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true), // Use merge: true to update existing fields without overwriting others
          );
        }

        if (!mounted) return;
        // Navigate to the dashboard screen upon successful login
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/dashboard');
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        if (e.code == 'user-not-found' || e.code == 'wrong-password') {
          errorMessage = 'Please check your email and password. The combination you entered is incorrect.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'The email address is not valid.';
        } else if (e.code == 'user-disabled') {
          errorMessage = 'This user has been disabled.';
        } else if (e.code == 'too-many-requests') {
          errorMessage = 'Too many requests. Try again later.';
        } else if (e.code == 'network-request-failed') {
          errorMessage = 'Network error. Please check your connection.';
        } else {
          errorMessage = e.message ?? 'An unexpected error occurred.';
        }

        if (e.code == 'user-not-found' && FirebaseAuth.instance.currentUser != null && !FirebaseAuth.instance.currentUser!.emailVerified) {
          // This case is unlikely to be hit with standard Firebase logic, but as a fallback
          errorMessage = 'Please verify your email before logging in.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              action: SnackBarAction(
                label: 'Resend',
                onPressed: () async {
                  await _authService.sendVerificationEmail();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Verification email sent!')),
                  );
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
          ),
        );
      }
    }
  }

  void _showForgotPasswordPopup() {
    final TextEditingController resetEmailController = TextEditingController();
    String? resetEmailError;
    bool emailSent = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: const Color(0xFFFFFBE6),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Ensure column takes minimum space
                  children: [
                    const Text(
                      'Enter the email you used to sign up. We’ll send you a link to reset your password.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF6D845F)),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 25),
                    TextField(
                      controller: resetEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: const OutlineInputBorder(),
                        errorText: resetEmailError,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (emailSent)
                      const Text(
                        'Password reset link sent! Please check your email.',
                        style: TextStyle(color: Colors.green, fontSize: 13),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            setState(() {
                              if (resetEmailController.text.isEmpty) {
                                resetEmailError = 'Email is required';
                                emailSent = false;
                              } else if (!isValidEmail(
                                resetEmailController.text,
                              )) {
                                resetEmailError = 'Invalid email format';
                                emailSent = false;
                              } else {
                                resetEmailError = null;
                                emailSent = true;
                              }
                            });

                            if (resetEmailError == null) {
                              try {
                                await _authService.sendPasswordResetEmail(
                                  resetEmailController.text,
                                );
                                setState(() {
                                  emailSent = true;
                                });
                              } on FirebaseAuthException catch (e) {
                                setState(() {
                                  resetEmailError = e.message;
                                  emailSent = false;
                                });
                              } catch (e) {
                                setState(() {
                                  resetEmailError = 'An unexpected error occurred: $e';
                                  emailSent = false;
                                });
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Send',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2E7D32)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: Color(0xFF2E7D32)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBE6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const WelcomePage()),
                    );
                  }
                },
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back, color: Color(0xFF2E7D32)),
                    SizedBox(width: 4),
                    Text(
                      'Back',
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              const Center(
                child: Text(
                  "Login",
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
                  "Welcome back! Let’s check what’s fresh in your pantry today.",
                  style: TextStyle(fontSize: 15, color: Color(0xFF6D845F)),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),

              const Text("Email Address"),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  errorText: _emailError,
                ),
              ),

              const SizedBox(height: 16),
              const Text("Password"),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  errorText: _passwordError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 8),
              TextButton(
                onPressed: _showForgotPasswordPopup,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  "Forgot Password",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _validateAndLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Login",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(child: Divider(color: Color(0xFF2E7D32))),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      "OR",
                      style: TextStyle(color: Color(0xFF2E7D32)),
                    ),
                  ),
                  Expanded(child: Divider(color: Color(0xFF2E7D32))),
                ],
              ),

              const SizedBox(height: 15),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/guest');
                  },
                  child: const Text(
                    "Continue as a guest",
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
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
