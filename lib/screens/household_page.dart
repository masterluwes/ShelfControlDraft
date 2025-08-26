import 'package:flutter/material.dart';
import 'household_detail_page.dart';
import 'create_group_page.dart';

class HouseholdPage extends StatefulWidget {
  const HouseholdPage({super.key});

  @override
  State<HouseholdPage> createState() => _HouseholdPageState();
}

class _HouseholdPageState extends State<HouseholdPage> {
  final List<Map<String, dynamic>> households = [];

  bool get hasGroup => households.isNotEmpty;

  void _leaveGroupByCode(String code) {
    setState(() {
      households.removeWhere((g) => g['code'] == code);
    });
  }

  Future<void> _openCreate() async {
    final result = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(builder: (_) => const CreateGroupPage()),
    );

    if (result != null) {
      setState(() {
        result['default'] = households.isEmpty;
        households.add(result);
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HouseholdDetailPage(
            name: result['name'] as String,
            code: result['code'] as String,
            members: (result['members'] as List).cast<String>(),
            isAdmin: result['isAdmin'] as bool? ?? true,
            onLeaveGroup: () => _leaveGroupByCode(result['code'] as String),
            showWelcome: true,
            welcomeTitle: 'Success!',
            welcomeMessage: 'You created the group.',
          ),
        ),
      );
    }
  }

  void _showJoinDialog() {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                      onChanged: (_) => setState(() {}),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: "Enter Code",
                        hintStyle: const TextStyle(color: Colors.black),
                        filled: true,
                        fillColor: Colors.grey[400],
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
                          onPressed: codeController.text.trim().isEmpty
                              ? null
                              : () {
                                  final code = codeController.text.trim();
                                  Navigator.pop(context);

                                  final joined = {
                                    "name": "Household 1",
                                    "code": code,
                                    "members": [
                                      "Luis",
                                      "Relle",
                                      "Jennie",
                                      "Angel",
                                    ],
                                    "isAdmin": false,
                                    "default": households.isEmpty,
                                  };

                                  setState(() => households.add(joined));

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => HouseholdDetailPage(
                                        name: joined['name'] as String,
                                        code: joined['code'] as String,
                                        members: (joined['members'] as List)
                                            .cast<String>(),
                                        isAdmin: joined['isAdmin'] as bool,
                                        onLeaveGroup: () => _leaveGroupByCode(
                                          joined['code'] as String,
                                        ),
                                        showWelcome: true,
                                        welcomeTitle: 'Welcome!',
                                        welcomeMessage:
                                            'You have joined the group!',
                                      ),
                                    ),
                                  );
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

  @override
  Widget build(BuildContext context) {
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
                _showJoinDialog();
              } else if (value == "create") {
                _openCreate();
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
      body: hasGroup
          ? ListView.separated(
              itemCount: households.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final h = households[index];
                return ListTile(
                  leading: const Icon(
                    Icons.group,
                    size: 40,
                    color: Colors.black,
                  ),
                  title: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: h["name"] as String,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        if (h["default"] == true)
                          const TextSpan(
                            text: " (default)",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                  subtitle: Text((h["members"] as List<String>).join(", ")),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HouseholdDetailPage(
                          name: h['name'] as String,
                          code: h['code'] as String,
                          members: (h['members'] as List).cast<String>(),
                          isAdmin: h['isAdmin'] as bool? ?? false,
                          onLeaveGroup: () =>
                              _leaveGroupByCode(h['code'] as String),
                          showWelcome: false,
                        ),
                      ),
                    );
                  },
                );
              },
            )
          : const Center(
              child: Text(
                "You are not in any household groups right now.\nCreate or Join now!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }
}
