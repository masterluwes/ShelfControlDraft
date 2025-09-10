import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

class HouseholdDetailPage extends StatefulWidget {
  final String name;
  final String code;
  final List<String> members;
  final bool isAdmin;
  final VoidCallback onLeaveGroup;
  final VoidCallback? onDeleteGroup;

  final bool showWelcome;
  final String? welcomeTitle;
  final String? welcomeMessage;

  final String? profileImage;
  final ValueChanged<Map<String, dynamic>>? onUpdate;

  const HouseholdDetailPage({
    super.key,
    required this.name,
    required this.code,
    required this.members,
    required this.isAdmin,
    required this.onLeaveGroup,
    this.onDeleteGroup,
    this.showWelcome = false,
    this.welcomeTitle,
    this.welcomeMessage,
    this.profileImage,
    this.onUpdate,
  });

  @override
  State<HouseholdDetailPage> createState() => _HouseholdDetailPageState();
}

class _HouseholdDetailPageState extends State<HouseholdDetailPage> {
  static const _green = Color(0xFF2E7D32);

  late bool _showWelcome;
  late String _householdName;
  late ImageProvider _profileImage;

  @override
  void initState() {
    super.initState();
    _householdName = widget.name;
    _showWelcome = widget.showWelcome;

    if (widget.profileImage != null && widget.profileImage!.isNotEmpty) {
      if (File(widget.profileImage!).existsSync()) {
        _profileImage = FileImage(File(widget.profileImage!));
      } else {
        _profileImage = const AssetImage("assets/default_profile.png");
      }
    } else {
      _profileImage = const AssetImage("assets/default_profile.png");
    }

    if (_showWelcome) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showWelcome = false);
      });
    }
  }

  Future<void> _editProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final newPath = pickedFile.path;
      setState(() {
        _profileImage = FileImage(File(newPath));
      });

      widget.onUpdate?.call({"name": _householdName, "profileImage": newPath});
    }
  }

  void _showLeaveConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _green, width: 3),
          ),
          title: const Text(
            "Leave group?",
            style: TextStyle(fontWeight: FontWeight.bold, color: _green),
            textAlign: TextAlign.center,
          ),
          content: const Text(
            "Are you sure you want to leave the group?",
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showByeDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text("Yes", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text("No", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showByeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _green, width: 3),
          ),
          title: const Text(
            "Bye!",
            style: TextStyle(fontWeight: FontWeight.bold, color: _green),
            textAlign: TextAlign.center,
          ),
          content: const Text(
            "You have left the group :(",
            textAlign: TextAlign.center,
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pop(context);
      widget.onLeaveGroup();
    });
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _green, width: 3),
          ),
          title: const Text(
            "Delete household pantry",
            style: TextStyle(fontWeight: FontWeight.bold, color: _green),
            textAlign: TextAlign.center,
          ),
          content: const Text(
            "Are you sure you want to delete your group?",
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showDeletedDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text("Yes", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text("No", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showDeletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _green, width: 3),
          ),
          title: const Text(
            "Success!",
            style: TextStyle(fontWeight: FontWeight.bold, color: _green),
            textAlign: TextAlign.center,
          ),
          content: const Text(
            "Household Pantry deleted.",
            textAlign: TextAlign.center,
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pop(context);
      widget.onDeleteGroup?.call();
    });
  }

  void _editHouseholdName() {
    final controller = TextEditingController(text: _householdName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _green, width: 3),
          ),
          title: const Text(
            "Edit Household Name",
            style: TextStyle(fontWeight: FontWeight.bold, color: _green),
            textAlign: TextAlign.center,
          ),
          content: TextField(
            controller: controller,
            maxLength: 30,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Household Name",
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _householdName = controller.text.trim();
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _popWithUpdatedData() {
    Navigator.pop(context, {
      "name": _householdName,
      "profileImage": (_profileImage is FileImage)
          ? (_profileImage as FileImage).file.path
          : null,
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _popWithUpdatedData();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFBE6),
        appBar: AppBar(
          backgroundColor: _green,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _popWithUpdatedData,
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == "leave") {
                  _showLeaveConfirmationDialog();
                } else if (value == "delete") {
                  _showDeleteConfirmationDialog();
                } else if (value == "share") {
                  Clipboard.setData(ClipboardData(text: widget.code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Pantry code copied to clipboard!"),
                    ),
                  );
                }
              },
              itemBuilder: (context) {
                return [
                  const PopupMenuItem(
                    value: "leave",
                    child: Text(
                      "Leave Group",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  if (widget.isAdmin)
                    const PopupMenuItem(
                      value: "delete",
                      child: Text(
                        "Delete Group",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  const PopupMenuItem(
                    value: "share",
                    child: Text(
                      "Share Group",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: _profileImage,
                        backgroundColor: Colors.black12,
                      ),
                      if (widget.isAdmin)
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.black),
                          onPressed: _editProfileImage,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _householdName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _green,
                        ),
                      ),
                      if (widget.isAdmin)
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            size: 18,
                            color: Colors.black,
                          ),
                          onPressed: _editHouseholdName,
                        ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Pantry Code: ${widget.code}",
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 18),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: widget.code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Pantry code copied!"),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.members.length,
                      itemBuilder: (context, index) {
                        final member = widget.members[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.black12,
                            child: Icon(Icons.person, color: Colors.black),
                          ),
                          title: Text(member),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            if (_showWelcome)
              Center(
                child: AnimatedOpacity(
                  opacity: _showWelcome ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.7,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: _green, width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.welcomeTitle ?? "Welcome!",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.welcomeMessage ?? "You have joined the group!",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
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
}
