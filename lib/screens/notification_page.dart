import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPage extends StatefulWidget {
  final Function(bool hasUnread, bool isSnoozed)? onStatusChanged;

  const NotificationPage({super.key, this.onStatusChanged});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> notifications = [];

  DateTime? snoozeUntil;
  bool snoozeIndefinite = false;

  bool get isSnoozed {
    if (snoozeIndefinite) return true;
    if (snoozeUntil != null) {
      return snoozeUntil!.isAfter(DateTime.now());
    }
    return false;
  }

  void _notifyDashboard() {
    widget.onStatusChanged?.call(
      notifications.any((n) => n["isRead"] == false),
      isSnoozed,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadSnoozeState().then((_) {
      _fetchNotificationsFromBackend();
    });
  }

  Future<List<Map<String, dynamic>>> fetchNotificationsFromBackend() async {
    // backend
    return [
      {
        "id": "1",
        "type": "expiry",
        "targetId": "item123",
        "icon": Icons.local_drink,
        "title": "Your milk expires in 2 days!",
        "subtitle": "Use it before it gets wasted.",
        "highlight": "milk",
        "isRead": false,
      },
      {
        "id": "2",
        "type": "atrisk",
        "targetId": "item456",
        "icon": Icons.set_meal,
        "title": "Your canned tuna expired yesterday :(",
        "subtitle": "Consider checking similar items now.",
        "highlight": "canned tuna",
        "isRead": false,
      },
    ];
  }

  Future<void> updateSnoozeOnBackend({
    DateTime? until,
    bool indefinite = false,
  }) async {}

  Future<void> deleteNotificationOnBackend(String notificationId) async {}

  Future<void> markAsReadOnBackend(String notificationId) async {}

  Future<void> markAllAsReadOnBackend() async {}

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

    await updateSnoozeOnBackend(
      until: snoozeUntil,
      indefinite: snoozeIndefinite,
    );

    _notifyDashboard();
  }

  Future<void> _fetchNotificationsFromBackend() async {
    final fetched = await fetchNotificationsFromBackend();
    setState(() {
      notifications = fetched;
    });
    _notifyDashboard();
  }

  void _deleteNotification(int index) {
    final notifId = notifications[index]["id"];
    setState(() {
      notifications.removeAt(index);
    });
    deleteNotificationOnBackend(notifId);
    _notifyDashboard();
  }

  void _markAsRead(int index) {
    final notifId = notifications[index]["id"];
    setState(() {
      notifications[index]["isRead"] = true;
    });
    markAsReadOnBackend(notifId);
    _notifyDashboard();
  }

  void _markAllAsRead() {
    setState(() {
      for (var notif in notifications) {
        notif["isRead"] = true;
      }
    });
    markAllAsReadOnBackend();
    _notifyDashboard();
  }

  void _handleNotificationTap(Map<String, dynamic> notif, int index) {
    _markAsRead(index);

    switch (notif["type"]) {
      case "expiry":
      case "atrisk":
        Navigator.pushNamed(
          context,
          "/pantry",
          arguments: {"itemId": notif["targetId"]},
        );
        break;
      case "recommendation":
        Navigator.pushNamed(context, "/shoppingList");
        break;
      case "tip":
        Navigator.pushNamed(context, "/tips");
        break;
      case "update":
        Navigator.pushNamed(context, "/updates");
        break;
    }
  }

  void _showSnoozeDialog() {
    if (isSnoozed) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF2E7D32), width: 3),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "End Snooze?",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 10),
                const Text("Do you want to turn notifications back on?"),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          snoozeUntil = null;
                          snoozeIndefinite = false;
                        });
                        _saveSnoozeState();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Yes",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF2E7D32), width: 3),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Snooze Notifications",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 10),
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
                    IconButton(
                      icon: const Icon(
                        Icons.done_all,
                        color: Color(0xFF2E7D32),
                      ),
                      onPressed: _markAllAsRead,
                      tooltip: "Mark all as read",
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
                      onPressed: () {
                        setState(() => notifications.clear());
                        _notifyDashboard();
                      },
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
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                    return Dismissible(
                      key: Key(notif["id"]),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => _deleteNotification(index),
                      child: Card(
                        color: notif["isRead"]
                            ? Colors.grey.shade200
                            : Colors.green.shade100,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          onTap: () => _handleNotificationTap(notif, index),
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
                          trailing: notif["isRead"]
                              ? null
                              : const Icon(
                                  Icons.circle,
                                  color: Colors.red,
                                  size: 10,
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
