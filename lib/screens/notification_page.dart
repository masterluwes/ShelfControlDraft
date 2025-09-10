import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> notifications = [
    {
      "icon": Icons.local_drink,
      "title": "Your milk expires in two days!",
      "subtitle": "Use it before it gets wasted.",
      "highlight": "milk",
      "selected": false,
    },
    {
      "icon": Icons.set_meal,
      "title": "Your canned tuna expired yesterday :(",
      "subtitle": "Consider checking similar items now.",
      "highlight": "canned tuna",
      "selected": false,
    },
    {
      "icon": Icons.local_grocery_store,
      "title": "You are running low on soy sauce.",
      "subtitle": "Want to add it to your grocery list?",
      "highlight": "soy sauce",
      "selected": false,
    },
  ];

  bool selectionMode = false;

  DateTime? snoozeUntil;
  bool snoozeIndefinite = false;
  bool get isSnoozed {
    if (snoozeIndefinite) return true;
    if (snoozeUntil != null) {
      return snoozeUntil!.isAfter(DateTime.now());
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _loadSnoozeState();
  }

  Future<void> _loadSnoozeState() async {
    final prefs = await SharedPreferences.getInstance();
    final untilString = prefs.getString('snoozeUntil');
    final indefinite = prefs.getBool('snoozeIndefinite') ?? false;

    DateTime? until;
    if (untilString != null) {
      until = DateTime.tryParse(untilString);
      if (until != null && until.isBefore(DateTime.now())) {
        until = null;
      }
    }

    setState(() {
      snoozeUntil = until;
      snoozeIndefinite = indefinite;
    });
  }

  Future<void> _saveSnoozeState() async {
    final prefs = await SharedPreferences.getInstance();
    if (snoozeUntil != null) {
      await prefs.setString('snoozeUntil', snoozeUntil!.toIso8601String());
    } else {
      await prefs.remove('snoozeUntil');
    }
    await prefs.setBool('snoozeIndefinite', snoozeIndefinite);
  }

  void toggleSelection(int index) {
    setState(() {
      notifications[index]["selected"] = !notifications[index]["selected"];
      selectionMode = notifications.any((notif) => notif["selected"] == true);
    });
  }

  void deleteSelected() {
    setState(() {
      notifications.removeWhere((notif) => notif["selected"] == true);
      selectionMode = false;
    });
  }

  void clearAll() {
    setState(() {
      notifications.clear();
      selectionMode = false;
    });
  }

  void _showSnoozeDialog() {
    if (isSnoozed) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("End Snooze?"),
          content: const Text("Do you want to turn notifications back on?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  snoozeUntil = null;
                  snoozeIndefinite = false;
                });
                _saveSnoozeState();
                Navigator.pop(context);
              },
              child: const Text("Yes"),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Snooze Notifications"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _snoozeOption(
                "1 Day",
                DateTime.now().add(const Duration(days: 1)),
              ),
              _snoozeOption(
                "3 Days",
                DateTime.now().add(const Duration(days: 3)),
              ),
              _snoozeOption(
                "1 Week",
                DateTime.now().add(const Duration(days: 7)),
              ),
              _snoozeOption("Until I turn back on", null, indefinite: true),
            ],
          ),
        ),
      );
    }
  }

  Widget _snoozeOption(
    String label,
    DateTime? until, {
    bool indefinite = false,
  }) {
    return ListTile(
      title: Text(label),
      onTap: () {
        setState(() {
          snoozeUntil = until;
          snoozeIndefinite = indefinite;
        });
        _saveSnoozeState();
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String? snoozeText;
    if (snoozeIndefinite) {
      snoozeText = "Snoozed until turned back on";
    } else if (isSnoozed && snoozeUntil != null) {
      snoozeText =
          "Snoozed until ${DateFormat.yMMMd().add_jm().format(snoozeUntil!)}";
    }

    return Column(
      children: [
        // Header
        Container(
          color: const Color(0xFFFFFBE6),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Notifications",
                style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (notifications.isNotEmpty)
                Row(
                  children: [
                    if (selectionMode)
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Color(0xFF2E7D32),
                        ),
                        onPressed: deleteSelected,
                      ),
                    IconButton(
                      icon: const Icon(Icons.snooze, color: Color(0xFF2E7D32)),
                      onPressed: _showSnoozeDialog,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.clear_all,
                        color: Color(0xFF2E7D32),
                      ),
                      onPressed: clearAll,
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (isSnoozed)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.orange.shade100,
            child: Text(
              snoozeText ?? "",
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        Expanded(
          child: notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.notifications_off,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 10),
                      Text(
                        "No notifications yet",
                        style: TextStyle(fontSize: 18, color: Colors.black54),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    return GestureDetector(
                      onLongPress: () => toggleSelection(index),
                      onTap: selectionMode
                          ? () => toggleSelection(index)
                          : null,
                      child: Card(
                        color: notif["selected"]
                            ? Colors.green.shade100
                            : Colors.grey.shade200,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: Icon(
                            notif["icon"],
                            color: const Color(0xFF2E7D32),
                            size: 36,
                          ),
                          title: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                              ),
                              children: [
                                TextSpan(
                                  text: notif["title"].toString().replaceAll(
                                    notif["highlight"],
                                    "",
                                  ),
                                ),
                                TextSpan(
                                  text: notif["highlight"],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          subtitle: Text(
                            notif["subtitle"],
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
