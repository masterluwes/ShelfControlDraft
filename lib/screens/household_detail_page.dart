import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shelf_control/models/household_model.dart'; // Import Household model
import 'package:shelf_control/services/firestore_service.dart'; // Import FirestoreService

class HouseholdDetailPage extends StatefulWidget {
  final Household household;
  final VoidCallback onLeaveGroup;
  final VoidCallback? onDeleteGroup;

  const HouseholdDetailPage({
    super.key,
    required this.household,
    required this.onLeaveGroup,
    this.onDeleteGroup,
  });

  @override
  State<HouseholdDetailPage> createState() => _HouseholdDetailPageState();
}

class _HouseholdDetailPageState extends State<HouseholdDetailPage> {
  final FirestoreService _firestoreService = FirestoreService();
  static const _green = Color(0xFF2E7D32);

  late String _householdName;

  @override
  void initState() {
    super.initState();
    _householdName = widget.household.name;
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
    Navigator.pop(context); // No data to return directly from here anymore
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
                  Clipboard.setData(ClipboardData(text: widget.household.joinCode));
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
                  if (widget.household.ownerId == _firestoreService.userId) // Only owner can delete
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
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.black12,
                child: Icon(Icons.group, color: Colors.black, size: 40), // Default group icon
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
                  if (widget.household.ownerId == _firestoreService.userId) // Only owner can edit name
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
                    "Pantry Code: ${widget.household.joinCode}",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: widget.household.joinCode));
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
                  itemCount: widget.household.members.length,
                  itemBuilder: (context, index) {
                    final member = widget.household.members[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.black12,
                        child: Icon(Icons.person, color: Colors.black),
                      ),
                      title: Text(member), // This will show user IDs, ideally we'd fetch user display names
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
