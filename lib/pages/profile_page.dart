import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController(
    text: "user@email.com",
  );
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
  final ImagePicker _picker = ImagePicker();

  late String _initialName;
  late String _initialUsername;
  File? _initialProfileImage;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initialName = nameController.text;
    _initialUsername = usernameController.text;
    _initialProfileImage = _profileImage;

    nameController.addListener(_checkForChanges);
    usernameController.addListener(_checkForChanges);
    changePasswordController.addListener(_checkForChanges);
    confirmPasswordController.addListener(_checkForChanges);
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
      });
      _checkForChanges();
    }
  }

  void _saveChanges() {
    if (!_hasChanges) return;
    if (changePasswordController.text.isNotEmpty ||
        confirmPasswordController.text.isNotEmpty) {
      if (changePasswordController.text.length < 8 ||
          confirmPasswordController.text.length < 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Passwords must be at least 8 characters."),
          ),
        );
        return;
      }
      if (changePasswordController.text != confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Passwords do not match.")),
        );
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated successfully.")),
    );
    _initialName = nameController.text;
    _initialUsername = usernameController.text;
    _initialProfileImage = _profileImage;
    _checkForChanges();
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
                              : null,
                          child: _profileImage == null
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
                              "Delete Account",
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
