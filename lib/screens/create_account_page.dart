import 'package:flutter/material.dart';
import 'package:shelf_control/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelf_control/services/firestore_service.dart'; // Import FirestoreService
import 'package:shelf_control/models/pantry_item_model.dart'; // Import PantryItemModel
import 'package:shelf_control/models/shopping_list_model.dart'; // Import ShoppingListModel
import 'package:shelf_control/screens/privacy_policy_screen.dart';
import 'package:shelf_control/screens/terms_and_conditions_screen.dart';
import 'package:shelf_control/screens/login_page.dart';
import 'package:provider/provider.dart'; // Import Provider

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreedToPolicy = false;
  bool _agreedToTerms = false;

  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _policyError;
  String? _termsError;
  bool _isLoading = false;

  final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  late AuthService _authService; // Declare as late
  late FirestoreService _firestoreService; // Declare as late

  @override
  void initState() {
    super.initState();
    // Initialize AuthService and FirestoreService here, after context is available
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _authService = AuthService(_firestoreService);
  }

  void _validateAndSubmit() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      if (_emailController.text.isEmpty) {
        _emailError = "Email is required";
      } else if (!_emailRegex.hasMatch(_emailController.text)) {
        _emailError = "Enter a valid email";
      } else {
        _emailError = null;
      }

      if (_passwordController.text.isEmpty) {
        _passwordError = "Password is required";
      } else if (_passwordController.text.length < 10) {
        _passwordError = "Password must be at least 10 characters";
      } else if (!RegExp(r'^(?=.*?[A-Z])').hasMatch(_passwordController.text)) {
        _passwordError = "Password must have at least one uppercase letter";
      } else if (!RegExp(r'^(?=.*?[a-z])').hasMatch(_passwordController.text)) {
        _passwordError = "Password must have at least one lowercase letter";
      } else if (!RegExp(r'^(?=.*?[0-9])').hasMatch(_passwordController.text)) {
        _passwordError = "Password must have at least one number";
      } else if (!RegExp(r'^(?=.*?[!@#\$&*~])').hasMatch(_passwordController.text)) {
        _passwordError = "Password must have at least one special character";
      } else {
        _passwordError = null;
      }

      if (_confirmPasswordController.text.isEmpty) {
        _confirmPasswordError = "Please confirm your password";
      } else if (_passwordController.text != _confirmPasswordController.text) {
        _confirmPasswordError = "Passwords do not match";
      } else {
        _confirmPasswordError = null;
      }

      if (!_agreedToPolicy) {
        _policyError = "You must agree to the Privacy Policy";
      } else {
        _policyError = null;
      }

      if (!_agreedToTerms) {
        _termsError = "You must agree to the Terms and Conditions";
      } else {
        _termsError = null;
      }
    });

    if (_emailError == null &&
        _passwordError == null &&
        _confirmPasswordError == null &&
        _policyError == null &&
        _termsError == null) {
      try {
        UserCredential userCredential =
            await _authService.createUserWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
        );

        if (userCredential.user != null) {
          final String userId = userCredential.user!.uid;
          final String userEmail = userCredential.user!.email!;

          await _firestoreService.createPersonalHousehold(userId, userEmail);

          final List<PantryItemModel> guestPantryItems = await _firestoreService.loadGuestPantryItems();
          for (var item in guestPantryItems) {
            item = item.copyWith(householdId: _firestoreService.selectedHouseholdId);
            await _firestoreService.addPantryItem(item);
          }

          final List<ShoppingListModel> guestShoppingLists = await _firestoreService.loadGuestShoppingLists();
          for (var list in guestShoppingLists) {
            list = list.copyWith(householdId: _firestoreService.selectedHouseholdId);
            await _firestoreService.addShoppingList(list);
          }

          await _firestoreService.clearGuestData();
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        String errorMessage;
        if (e.code == 'weak-password') {
          errorMessage = 'The password provided is too weak.';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'The account already exists for that email.';
        } else {
          errorMessage = 'An error occurred: ${e.message}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
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
                      MaterialPageRoute(builder: (context) => const LoginPage()),
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
                  "Create Account",
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
                  "Start fresh and smart - set up your account in seconds!",
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
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  errorText: _passwordError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Text("Confirm Password"),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  errorText: _confirmPasswordError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  Checkbox(
                    value: _agreedToPolicy,
                    onChanged: (bool? value) async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                      );
                      if (result != null && result is bool) {
                        setState(() {
                          _agreedToPolicy = result;
                        });
                      }
                    },
                  ),
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                      );
                      if (result != null && result is bool) {
                        setState(() {
                          _agreedToPolicy = result;
                        });
                      }
                    },
                    child: const Text(
                      "I agree to the Privacy Policy",
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              if (_policyError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    _policyError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (bool? value) async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TermsAndConditionsScreen()),
                      );
                      if (result != null && result is bool) {
                        setState(() {
                          _agreedToTerms = result;
                        });
                      }
                    },
                  ),
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TermsAndConditionsScreen()),
                      );
                      if (result != null && result is bool) {
                        setState(() {
                          _agreedToTerms = result;
                        });
                      }
                    },
                    child: const Text(
                      "I agree to the Terms and Conditions",
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              if (_termsError != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    _termsError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _validateAndSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
                          "Create Account",
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

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(
                      color: Color(0xFF2E7D32),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Login",
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
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
