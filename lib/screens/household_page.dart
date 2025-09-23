import 'package:flutter/material.dart';
import 'package:shelf_control/models/household_model.dart';
import 'package:shelf_control/models/user_model.dart'; // Import UserModel
import 'package:shelf_control/services/firestore_service.dart';
import 'package:shelf_control/screens/household_detail_page.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:provider/provider.dart'; // Import provider

class HouseholdPage extends StatefulWidget {
  const HouseholdPage({super.key});

  @override
  State<HouseholdPage> createState() => _HouseholdPageState();
}

class _HouseholdPageState extends State<HouseholdPage> {

  void _showJoinDialog(BuildContext context, FirestoreService firestoreService) {
    final codeController = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(color: const Color(0xFF2E7D32), width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Join Household",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: codeController,
                      onChanged: (value) {
                        dialogSetState(() {
                          errorText = null; // Clear error on change
                        });
                      },
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: "Enter Code",
                        hintStyle: const TextStyle(color: Colors.black),
                        filled: true,
                        fillColor: Colors.grey[400],
                        errorText: errorText,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
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
                        ElevatedButton(
                          onPressed: () async {
                            final code = codeController.text.trim();
                            if (code.isEmpty) {
                              dialogSetState(() {
                                errorText = "Code cannot be empty.";
                              });
                              return;
                            }
                            try {
                              await firestoreService.joinHousehold(code);
                              if (!mounted) return;
                              Navigator.of(context).pop();
                              if (!mounted) return; 
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Successfully joined household!')),
                              );
                              // No need for setState here, Provider will handle rebuilds
                            } catch (e) {
                              dialogSetState(() {
                                errorText = e.toString().replaceFirst('Exception: ', '');
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            "Confirm",
                            style: TextStyle(color: Colors.white),
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

  Future<void> _createHousehold(BuildContext context, FirestoreService firestoreService) async {
    final nameController = TextEditingController();
    String? errorText;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(color: const Color(0xFF2E7D32), width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Create New Household",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      onChanged: (value) {
                        dialogSetState(() {
                          errorText = null; // Clear error on change
                        });
                      },
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: "Household Name",
                        hintStyle: const TextStyle(color: Colors.black),
                        filled: true,
                        fillColor: Colors.grey[400],
                        errorText: errorText,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 20,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
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
                        ElevatedButton(
                          onPressed: () async {
                            final name = nameController.text.trim();
                            if (name.isEmpty) {
                              dialogSetState(() {
                                errorText = "Household name cannot be empty.";
                              });
                              return;
                            }
                            try {
                              await firestoreService.createHousehold(name);
                              if (!mounted) return;
                              Navigator.of(context).pop();
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Household created successfully!')),
                              );
                              // No need for setState here, Provider will handle rebuilds
                            } catch (e) {
                              dialogSetState(() {
                                errorText = e.toString().replaceFirst('Exception: ', '');
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            "Create",
                            style: TextStyle(color: Colors.white),
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
    final firestoreService = Provider.of<FirestoreService>(context); // Get the FirestoreService instance

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBE6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Household Groups",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          PopupMenuButton<String>(
            offset: const Offset(0, 40),
            color: const Color(0xFF2E7D32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            constraints: const BoxConstraints(minWidth: 160),
            icon: const Icon(Icons.group_add, color: Colors.white),
            onSelected: (value) {
              if (value == "join") {
                _showJoinDialog(context, firestoreService);
              } else if (value == "create") {
                _createHousehold(context, firestoreService);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: "join",
                child: Text(
                  "Join Group",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              PopupMenuDivider(height: 1),
              PopupMenuItem(
                value: "create",
                child: Text(
                  "Create Group",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<Household>>(
        stream: firestoreService.getHouseholds(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final households = snapshot.data ?? [];

          if (households.isEmpty) {
            return const Center(
              child: Text(
                "You are not in any household groups right now.\nCreate or Join now!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          // Sort households to put personal household first
          households.sort((a, b) {
            if (a.isPersonal) return -1;
            if (b.isPersonal) return 1;
            return a.name.compareTo(b.name);
          });

          return ListView.separated(
            itemCount: households.length,
            separatorBuilder: (_, i) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final household = households[index];
              final isSelected = firestoreService.selectedHouseholdId == household.id;

              return ListTile(
                leading: Icon(
                  household.isPersonal ? Icons.person : Icons.group,
                  size: 40,
                  color: Colors.black,
                ),
                title: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: household.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      if (household.isPersonal)
                        const TextSpan(
                          text: " (Personal)",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                subtitle: FutureBuilder<List<UserModel>>(
                  future: Future.wait(household.members.map((uid) => firestoreService.getUser(uid).then((user) => user!))),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const Text("Loading members...");
                    }
                    if (userSnapshot.hasError) {
                      return Text('Error loading members: ${userSnapshot.error}');
                    }
                    final memberUsers = userSnapshot.data ?? [];
                    final memberNames = memberUsers.map((user) => user.nickname ?? user.email.split('@').first).toList();
                    return Text(memberNames.join(", "));
                  },
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : IconButton(
                        icon: const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                        onPressed: () {
                          firestoreService.selectedHouseholdId = household.id;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "${household.name} selected as current household",
                              ),
                            ),
                          );
                        },
                      ),
                onTap: () {
                  // Navigate to HouseholdDetailPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HouseholdDetailPage(
                        household: household,
                        onLeaveGroup: () {
                          // When a user leaves a group, we need to ensure the HouseholdPage rebuilds
                          // to reflect the updated list of households.
                          setState(() {}); // Force a rebuild of HouseholdPage
                        },
                        onDeleteGroup: () {
                          // When a group is deleted, we need to ensure the HouseholdPage rebuilds
                          // to reflect the updated list of households.
                          setState(() {}); // Force a rebuild of HouseholdPage
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
