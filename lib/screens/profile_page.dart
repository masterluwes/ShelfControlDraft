import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shelf_control/screens/welcome_page.dart';

// --- UI Color Constants ---
const Color primaryGreen = Color(0xFF2E7D32);
const Color pageBackground = Color(0xFFFDFDFC);
const Color deleteRed = Color(0xFFBF5959);
const Color mediumGrey = Color(0xFF666666);
const Color strokeGrey = Color(0xFFB8B8B8);
const Color inputText = Color(0xFF222222);
const Color pureWhite = Color(0xFFFFFFFF);
const Color lightGrey = Color(0xFFBDBDBD); // For disabled elements

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // --- Keys and Controllers ---
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController(text: "••••••••");
  final TextEditingController _changePasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _deleteConfirmController = TextEditingController();

  // --- Firebase Instances ---
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- State Variables ---
  bool _hasChanges = false;
  bool _isSaveButtonEnabled = false;
  File? _profileImage;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();

  // States for password visibility
  bool _isPasswordVisible = false;
  bool _isChangePasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // For password validation UI
  final FocusNode _passwordFocusNode = FocusNode();
  bool _isPasswordFocused = false;
  bool _has8Characters = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialCharacter = false;

  // Store initial values to detect changes
  String _initialName = '';
  String _initialUsername = '';
  File? _initialProfileImage;


  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Add listeners to controllers to update form state
    _nameController.addListener(_updateFormState);
    _usernameController.addListener(_updateFormState);
    _changePasswordController.addListener(_updateFormState);
    _confirmPasswordController.addListener(_updateFormState);

    // Listener for password validation UI
    _changePasswordController.addListener(_onPasswordChanged);
    _passwordFocusNode.addListener(() {
      setState(() {
        _isPasswordFocused = _passwordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    // Dispose controllers to free up resources
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _changePasswordController.dispose();
    _confirmPasswordController.dispose();
    _deleteConfirmController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }
  
  /// Reverts all fields to their initial saved state.
  void _revertChanges() {
    setState(() {
      _nameController.text = _initialName;
      _usernameController.text = _initialUsername;
      _changePasswordController.clear();
      _confirmPasswordController.clear();
      _profileImage = null; // Revert any newly picked image
    });
    // This call ensures the button state and hasChanges flag are reset correctly
    _updateFormState();
  }

  /// Checks for form changes and validity to update the save button state.
  void _updateFormState() {
    // 1. Check for any changes from the initial state
    final bool hasTextChanged = _nameController.text != _initialName ||
                                _usernameController.text != _initialUsername ||
                                _changePasswordController.text.isNotEmpty ||
                                _confirmPasswordController.text.isNotEmpty;
    final bool hasImageChanged = _profileImage != _initialProfileImage;
    final bool hasChanges = hasTextChanged || hasImageChanged;

    // 2. Check if the main required fields are filled
    final bool areRequiredFieldsFilled = _nameController.text.isNotEmpty &&
                                         _usernameController.text.isNotEmpty;

    // 3. Update the state to enable the save button
    if (mounted) {
      setState(() {
        _hasChanges = hasChanges;
        _isSaveButtonEnabled = hasChanges && areRequiredFieldsFilled;
      });
    }
  }

  /// Validates the password against the defined criteria for the UI.
  void _onPasswordChanged() {
    final password = _changePasswordController.text;
    if (mounted) {
      setState(() {
        _has8Characters = password.length >= 8;
        _hasUppercase = password.contains(RegExp(r'[A-Z]'));
        _hasLowercase = password.contains(RegExp(r'[a-z]'));
        _hasNumber = password.contains(RegExp(r'[0-9]'));
        _hasSpecialCharacter = password.contains(RegExp(r'[!@#\$%^&*]'));
      });
    }
  }

  /// Loads user data from Firestore and populates the text fields.
  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists && mounted) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _initialName = userData['name'] ?? '';
            _initialUsername = userData['username'] ?? '';
            _nameController.text = _initialName;
            _usernameController.text = _initialUsername;
            _emailController.text = user.email ?? '';
            _profileImageUrl = userData['profileImageUrl'];
          });
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to load user data: $e")),
          );
        }
      }
    }
  }

  /// Opens the image gallery to pick a new profile picture.
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      _updateFormState(); // Update button state after picking image
    }
  }

  /// Saves all modified data to Firebase.
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    User? user = _auth.currentUser;
    if (user == null) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No user logged in.")),
      );
      return;
    }

    try {
      Map<String, dynamic> updates = {};

      if (_nameController.text != _initialName) {
        updates['name'] = _nameController.text;
      }
      if (_usernameController.text != _initialUsername) {
        updates['username'] = _usernameController.text;
      }
      
      if (_changePasswordController.text.isNotEmpty) {
        final bool isPasswordValid = _has8Characters &&
                                     _hasUppercase &&
                                     _hasLowercase &&
                                     _hasNumber &&
                                     _hasSpecialCharacter;
        if (!isPasswordValid) {
          throw 'Password does not meet the security requirements.';
        }
        if (_changePasswordController.text != _confirmPasswordController.text) {
          throw 'Passwords do not match.';
        }
        await user.updatePassword(_changePasswordController.text);
      }

      if (_profileImage != null) {
        String fileName = user.uid;
        Reference storageRef = _storage.ref().child('profile_images/$fileName');
        UploadTask uploadTask = storageRef.putFile(_profileImage!);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        updates['profileImageUrl'] = downloadUrl;
        _profileImageUrl = downloadUrl;
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).update(updates);
      }
      
      Navigator.pop(context);
      _showSuccessDialog("Success!", "Profile saved!");

      if(mounted) {
        setState(() {
          _initialName = _nameController.text;
          _initialUsername = _usernameController.text;
          _initialProfileImage = _profileImage;
          _changePasswordController.clear();
          _confirmPasswordController.clear();
          _updateFormState();
        });
      }

    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }
  
  /// Deletes the user's account and all associated data.
  Future<void> _deleteAccount() async {
     showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    User? user = _auth.currentUser;
    if (user == null) {
      Navigator.pop(context);
      return;
    }

    try {
      await _firestore.collection('users').doc(user.uid).delete();
      
      try {
        await _storage.ref().child('profile_images/${user.uid}').delete();
      } on FirebaseException catch (e) {
        if (e.code != 'object-not-found') {
          rethrow;
        }
      }

      await user.delete();

      Navigator.pop(context);
      Navigator.pop(context);

      _showStatusDialog(
        icon: Icons.check_circle,
        iconColor: primaryGreen,
        title: "Account Deleted!",
        buttonText: "Continue",
        onContinue: () {
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const WelcomePage()),
              (Route<dynamic> route) => false,
            );
          }
        }
      );

    } on FirebaseAuthException catch (e) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Deletion failed: ${e.message}. Please re-login and try again.")),
        );
    } catch (e) {
       Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An unexpected error occurred: $e")),
        );
    }
  }

  void _showDiscardChangesDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: pageBackground,
          title: const Center(
            child: Text(
              "Discard Changes?",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          content: const Text(
            "You have unsaved changes.\nAre you sure you want to discard them?",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black87),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text("Keep Editing", style: TextStyle(color: pureWhite)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(); 
                    _showStatusDialog(
                      icon: Icons.highlight_off,
                      iconColor: deleteRed,
                      title: "Changes Discarded!",
                      titleColor: deleteRed,
                      buttonText: "Continue",
                      buttonColor: mediumGrey,
                      onContinue: () {
                        _revertChanges();
                        
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                           if (mounted) {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                           }
                        });
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deleteRed,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text("Discard", style: TextStyle(color: pureWhite)),
                ),
              ],
            ),
          ],
          actionsPadding: const EdgeInsets.only(bottom: 24.0, top: 10.0),
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    _deleteConfirmController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: pageBackground,
              title: const Text("Delete Account?", style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("This action is permanent and cannot be undone."),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _deleteConfirmController,
                    decoration: _inputDecoration('To confirm, type "DELETE"'),
                    style: const TextStyle(color: inputText),
                    onChanged: (value) {
                      setDialogState(() {});
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    decoration: BoxDecoration(
                      color: mediumGrey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text("Cancel", style: TextStyle(color: pureWhite)),
                  ),
                ),
                TextButton(
                  onPressed: _deleteConfirmController.text == "DELETE" ? _deleteAccount : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    decoration: BoxDecoration(
                      color: _deleteConfirmController.text == "DELETE" ? deleteRed : lightGrey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text("Delete Permanently", style: TextStyle(color: pureWhite)),
                  ),
                ),
              ],
            );
          }
        );
      },
    );
  }
  
  void _showSuccessDialog(String title, String message) {
    _showStatusDialog(
      icon: Icons.check_circle,
      iconColor: primaryGreen,
      title: title,
      message: message,
      buttonText: "Continue",
      onContinue: () => Navigator.of(context).pop(),
    );
  }

  void _showStatusDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    Color? titleColor,
    String? message,
    required String buttonText,
    Color? buttonColor,
    required VoidCallback onContinue,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: pageBackground,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Icon(icon, color: iconColor, size: 60),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: titleColor ?? Colors.black87,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black87)),
              ],
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor ?? primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 48),
                ),
                child: Text(buttonText, style: const TextStyle(color: pureWhite, fontSize: 16)),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.only(bottom: 24.0, top: 16),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _showDiscardChangesDialog();
      },
      child: Scaffold(
        backgroundColor: pageBackground,
        appBar: AppBar(
          title: const Text("Edit Profile"),
          backgroundColor: primaryGreen,
          foregroundColor: pureWhite,
          elevation: 0,
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 63,
                              backgroundColor: primaryGreen,
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: _profileImage != null
                                    ? FileImage(_profileImage!)
                                    : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                        ? NetworkImage(_profileImageUrl!)
                                        : null) as ImageProvider?,
                                child: _profileImage == null && (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                                    ? const Icon(Icons.person, size: 70, color: mediumGrey)
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, color: pureWhite, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _nameController.text.isNotEmpty ? _nameController.text : "User Name", 
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _usernameController.text.isNotEmpty ? "@${_usernameController.text}" : "@username",
                        style: const TextStyle(fontSize: 16, color: mediumGrey),
                      ),
                      const SizedBox(height: 10),
                      const Divider(color: mediumGrey),
                      const SizedBox(height: 20),
                      _buildTextField("Full Name", _nameController),
                      _buildTextField("Username", _usernameController),
                      _buildTextField("Email", _emailController, readOnly: true),
                      _buildPasswordTextField(
                        "Password",
                        _passwordController,
                        _isPasswordVisible,
                        () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        readOnly: true,
                      ),
                      _buildPasswordTextField(
                        "Change Password",
                        _changePasswordController,
                        _isChangePasswordVisible,
                        () => setState(() => _isChangePasswordVisible = !_isChangePasswordVisible),
                        focusNode: _passwordFocusNode,
                      ),
                      _buildPasswordValidation(),
                      _buildPasswordTextField(
                        "Confirm Password",
                        _confirmPasswordController,
                        _isConfirmPasswordVisible,
                        () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                        validator: (value) {
                            if (_changePasswordController.text.isNotEmpty &&
                                value != _changePasswordController.text) {
                              return 'Passwords do not match.';
                            }
                            return null;
                          },
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: _showDeleteAccountDialog,
                        child: const Text(
                          "Delete Account",
                          style: TextStyle(color: mediumGrey, fontWeight: FontWeight.normal),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaveButtonEnabled ? _saveProfile : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    disabledBackgroundColor: lightGrey,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const SafeArea(
                    top: false,
                    child: Text("Save Profile", style: TextStyle(fontSize: 18, color: pureWhite)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordValidation() {
    return Visibility(
      visible: _isPasswordFocused && _changePasswordController.text.isNotEmpty,
      child: Padding(
        padding: const EdgeInsets.only(top: 12.0, left: 4, right: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildValidationRow("At least 8 characters", _has8Characters),
            const SizedBox(height: 4),
            _buildValidationRow("One uppercase letter", _hasUppercase),
            const SizedBox(height: 4),
            _buildValidationRow("One lowercase letter", _hasLowercase),
            const SizedBox(height: 4),
            _buildValidationRow("One number", _hasNumber),
            const SizedBox(height: 4),
            _buildValidationRow("One special character (!@#\$%^&*)", _hasSpecialCharacter),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationRow(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.error_outline,
          color: isValid ? primaryGreen : mediumGrey,
          size: 20,
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(color: isValid ? primaryGreen : mediumGrey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        style: const TextStyle(color: inputText),
        decoration: _inputDecoration(label, readOnly: readOnly),
        validator: (value) {
          if (!readOnly && (value == null || value.isEmpty)) {
            return '$label cannot be empty';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordTextField(
    String label,
    TextEditingController controller,
    bool isVisible,
    VoidCallback onToggleVisibility, {
    bool readOnly = false,
    FocusNode? focusNode,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: !isVisible,
        readOnly: readOnly,
        focusNode: focusNode,
        style: const TextStyle(color: inputText),
        decoration: _inputDecoration(label, readOnly: readOnly).copyWith(
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              color: mediumGrey,
            ),
            onPressed: onToggleVisibility,
          ),
        ),
        validator: validator,
      ),
    );
  }
  
  InputDecoration _inputDecoration(String label, {bool readOnly = false}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: mediumGrey), 
      filled: true,
      fillColor: readOnly ? Colors.grey[200] : pageBackground, 
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: strokeGrey), 
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryGreen, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: deleteRed.withOpacity(0.7), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: deleteRed, width: 2),
      ),
    );
  }
}
