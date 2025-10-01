import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController(
    text: "********",
  );
  final TextEditingController changePasswordController =
      TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool obscurePassword = true;
  bool obscureChangePassword = true;
  bool obscureConfirmPassword = true;

  File? _profileImage;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();

  File? _initialProfileImage;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    nameController.addListener(_checkForChanges);
    usernameController.addListener(_checkForChanges);
    changePasswordController.addListener(_checkForChanges);
    confirmPasswordController.addListener(_checkForChanges);
  }

  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        nameController.text = userData['name'] ?? '';
        usernameController.text = userData['username'] ?? '';
        emailController.text = user.email ?? '';
        _profileImageUrl = userData['profileImageUrl'];
        if (_profileImageUrl != null) {
          setState(() {}); // Trigger rebuild to show image
        }
      } else {
        // If user document doesn't exist, create it with basic info
        await _firestore.collection('users').doc(user.uid).set({
          'email': user.email,
          'name': '',
          'username': '',
          'profileImageUrl': null,
        });
        emailController.text = user.email ?? '';
      }
    }
  }

  void _checkForChanges() {
    setState(() {
      _hasChanges =
          nameController.text.isNotEmpty ||
          usernameController.text.isNotEmpty ||
          changePasswordController.text.isNotEmpty ||
          confirmPasswordController.text.isNotEmpty ||
          _profileImage?.path != _initialProfileImage?.path;
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
        _hasChanges = true;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges) return;

    User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No user logged in."),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(top: 20, left: 20, right: 20),
        ),
      );
      return;
    }

    try {
      // Update user profile in Firestore
      Map<String, dynamic> updates = {};
      if (nameController.text.isNotEmpty) {
        updates['name'] = nameController.text;
      }
      if (usernameController.text.isNotEmpty) {
        updates['username'] = usernameController.text;
      }

      // Handle password change
      if (changePasswordController.text.isNotEmpty ||
          confirmPasswordController.text.isNotEmpty) {
        if (changePasswordController.text.length < 8 ||
            confirmPasswordController.text.length < 8) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(top: 20, left: 20, right: 20),
              content: Text("Passwords must be at least 8 characters."),
            ),
          );
          return;
        }
        if (changePasswordController.text != confirmPasswordController.text) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Passwords do not match."),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.only(top: 20, left: 20, right: 20),
            ),
          );
          return;
        }
        await user.updatePassword(changePasswordController.text);
      }

      // Handle profile image upload
      if (_profileImage != null && _profileImage?.path != _initialProfileImage?.path) {
        String fileName = user.uid;
        Reference storageRef = _storage.ref().child('profile_images/$fileName');
        UploadTask uploadTask = storageRef.putFile(_profileImage!);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        updates['profileImageUrl'] = downloadUrl;
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).update(updates);
      }

      if (!mounted) return; // Guard against BuildContext across async gaps
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully."),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(top: 20, left: 20, right: 20),
        ),
      );
      _initialProfileImage = _profileImage;
      _hasChanges = false;
      changePasswordController.clear();
      confirmPasswordController.clear();
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating profile: ${e.message}"),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An unexpected error occurred: $e"),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
        ),
      );
    }
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFEF9E7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            "Delete your account?",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          content: const Text(
            "This action cannot be undone.",
            style: TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Color(0xFF2E7D32)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.only(top: 20, left: 20, right: 20),
                    content: Text("Account deleted successfully."),
                  ),
                );
              },
              child: const Text(
                "Yes, Delete",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBE6),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(
                top: 20,
                left: 16,
                right: 16,
                bottom: 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
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
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      "Profile",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : (_profileImageUrl != null
                                  ? NetworkImage(_profileImageUrl!)
                                  : null) as ImageProvider<Object>?,
                          child: _profileImage == null && _profileImageUrl == null
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.black54,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Tap to change picture",
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 20),
                      _buildEditableField("Name", nameController),
                      _buildEditableField("Username", usernameController),
                      _buildReadOnlyField("Email", emailController),
                      _buildReadOnlyPasswordField(
                        "Password",
                        passwordController,
                        obscurePassword,
                        () =>
                            setState(() => obscurePassword = !obscurePassword),
                      ),
                      _buildEditablePasswordField(
                        "Change Password",
                        changePasswordController,
                        obscureChangePassword,
                        () => setState(
                          () => obscureChangePassword = !obscureChangePassword,
                        ),
                      ),
                      _buildEditablePasswordField(
                        "Confirm Password",
                        confirmPasswordController,
                        obscureConfirmPassword,
                        () => setState(
                          () =>
                              obscureConfirmPassword = !obscureConfirmPassword,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: _hasChanges ? _saveChanges : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _hasChanges
                                  ? const Color(0xFF2E7D32)
                                  : Colors.grey,
                            ),
                            child: const Text(
                              "Save Changes",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _confirmDeleteAccount,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text(
                              "Yes, Delete",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: _inputDecoration(label),
      ),
    );
  }

  Widget _buildEditablePasswordField(
    String label,
    TextEditingController controller,
    bool obscure,
    VoidCallback toggle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        decoration: _inputDecoration(label).copyWith(
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
            onPressed: toggle,
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        decoration: _inputDecoration(label, readOnly: true),
      ),
    );
  }

  Widget _buildReadOnlyPasswordField(
    String label,
    TextEditingController controller,
    bool obscure,
    VoidCallback toggle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        obscureText: obscure,
        decoration: _inputDecoration(label, readOnly: true).copyWith(
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
            onPressed: toggle,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {bool readOnly = false}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: readOnly ? Colors.grey[300] : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
    );
  }
}
