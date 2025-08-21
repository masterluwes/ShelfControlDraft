import 'package:flutter/material.dart';

class HouseholdDetailPage extends StatefulWidget {
  final String name;
  final String code;
  final List<String> members;
  final bool isAdmin;
  final VoidCallback onLeaveGroup;

  final bool showWelcome;
  final String? welcomeTitle;
  final String? welcomeMessage;

  const HouseholdDetailPage({
    super.key,
    required this.name,
    required this.code,
    required this.members,
    required this.isAdmin,
    required this.onLeaveGroup,
    this.showWelcome = false,
    this.welcomeTitle,
    this.welcomeMessage,
  });

  @override
  State<HouseholdDetailPage> createState() => _HouseholdDetailPageState();
}

class _HouseholdDetailPageState extends State<HouseholdDetailPage> {
  static const _green = Color(0xFF2E7D32);

  late bool _showWelcome;
  late String _householdName;
  ImageProvider _profileImage = const AssetImage("assets/default_profile.png");

  @override
  void initState() {
    super.initState();
    _householdName = widget.name;
    _showWelcome = widget.showWelcome;
    if (_showWelcome) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showWelcome = false);
      });
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

  void _editHouseholdName() {
    final controller = TextEditingController(text: _householdName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Household Name"),
          content: TextField(
            controller: controller,
            maxLength: 30,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Household Name",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _householdName = controller.text.trim();
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: _green),
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _editProfileImage() {
    setState(() {
      _profileImage = const AssetImage("assets/sample_profile.png");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBE6),
      appBar: AppBar(
        backgroundColor: _green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            offset: const Offset(0, 40),
            color: _green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            constraints: const BoxConstraints(minWidth: 160),
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == "leave") _showLeaveConfirmationDialog();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: "leave",
                child: Text(
                  "Leave Group",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Pantry code copied!")),
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
    );
  }
}
