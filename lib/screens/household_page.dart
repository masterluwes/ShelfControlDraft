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
                  mainAxisSize: MainAxisSize.min, // Ensure column takes minimum space
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
                  mainAxisSize: MainAxisSize.min, // Ensure column takes minimum space
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
          "Groups", // Changed from "Household Groups" to "Groups"
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
          final allHouseholds = snapshot.data ?? [];
          final personalHousehold = allHouseholds.firstWhere(
            (h) => h.isPersonal,
            orElse: () => Household(
              id: '',
              name: 'My Pantry', // Changed from 'My Personal Pantry'
              ownerId: '',
              members: [],
              joinCode: '',
              isPersonal: true,
              timestamp: DateTime.now(),
            ),
          );
          final sharedHouseholds = allHouseholds.where((h) => !h.isPersonal).toList();

          if (allHouseholds.isEmpty) {
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

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Personal Pantry Section
                if (personalHousehold.id.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "Personal Pantry", // Changed from "My Personal Pantry" to "Personal Pantry"
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.black,
                    ),
                    title: const Text(
                      "My Pantry", // Changed from "My Personal Pantry" to "My Pantry"
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    subtitle: FutureBuilder<List<UserModel>>(
                      future: Future.wait(personalHousehold.members.map((uid) => firestoreService.getUser(uid).then((user) => user!))),
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
                    trailing: firestoreService.selectedHouseholdId == personalHousehold.id
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : IconButton(
                            icon: const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                            onPressed: () {
                              firestoreService.selectedHouseholdId = personalHousehold.id;
                            },
                          ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HouseholdDetailPage(
                            household: personalHousehold,
                            onLeaveGroup: () {
                              setState(() {});
                            },
                            onDeleteGroup: () {
                              setState(() {});
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                ],

                // Household Groups Section
                if (sharedHouseholds.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "Household Groups", // Retained "Household Groups" for shared section
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  ListView.separated(
                    shrinkWrap: true, // Important for nested ListViews
                    physics: const NeverScrollableScrollPhysics(), // Important for nested ListViews
                    itemCount: sharedHouseholds.length,
                    separatorBuilder: (_, i) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final household = sharedHouseholds[index];
                      final isSelected = firestoreService.selectedHouseholdId == household.id;

                      return ListTile(
                        leading: const Icon(
                          Icons.group,
                          size: 40,
                          color: Colors.black,
                        ),
                        title: Text(
                          household.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
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
                                },
                              ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HouseholdDetailPage(
                                household: household,
                                onLeaveGroup: () {
                                  setState(() {});
                                },
                                onDeleteGroup: () {
                                  setState(() {});
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
