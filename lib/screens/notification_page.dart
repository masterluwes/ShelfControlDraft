import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:shelf_control/services/firestore_service.dart'; // Import FirestoreService
import 'package:shelf_control/models/app_notification_model.dart'; // Import AppNotificationModel

class NotificationPage extends StatefulWidget {
  final Function(int unreadCount, bool isSnoozed)? onStatusChanged; // Changed to int unreadCount

  const NotificationPage({super.key, this.onStatusChanged});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  late FirestoreService _firestoreService;
  late User? _currentUser;
  int _unreadCount = 0; // Track unread count for dashboard callback

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
      _unreadCount, // Pass the actual unread count
      isSnoozed,
    );
  }

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _currentUser = FirebaseAuth.instance.currentUser;
    _loadSnoozeState();

    // Listen to unread notifications count
    _firestoreService.getUnreadNotificationsCountStream(_currentUser!.uid).listen((count) {
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
        _notifyDashboard();
      }
    });
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
    _notifyDashboard(); // Notify dashboard after loading snooze state
  }

  Future<void> _saveSnoozeState() async {
    final prefs = await SharedPreferences.getInstance();
    if (snoozeUntil != null) {
      await prefs.setString('snoozeUntil', snoozeUntil!.toIso8601String());
    } else {
      await prefs.remove('snoozeUntil');
    }
    await prefs.setBool('snoozeIndefinite', snoozeIndefinite);

    // No backend update for snooze on Spark plan, as it's local only
    _notifyDashboard();
  }

  void _deleteNotification(String notificationId) async {
    if (_currentUser == null) return;
    await _firestoreService.markNotificationAsRead(_currentUser!.uid, notificationId); // Mark as read instead of deleting
    // The UI will update automatically via the StreamBuilder
  }

  void _markAsRead(String notificationId) async {
    if (_currentUser == null) return;
    await _firestoreService.markNotificationAsRead(_currentUser!.uid, notificationId);
    // The UI will update automatically via the StreamBuilder
  }

  void _markAllAsRead(List<AppNotificationModel> notifications) async {
    if (_currentUser == null) return;
    for (var notif in notifications) {
      if (!notif.isRead) {
        await _firestoreService.markNotificationAsRead(_currentUser!.uid, notif.id!);
      }
    }
    // The UI will update automatically via the StreamBuilder
  }

  void _handleNotificationTap(AppNotificationModel notif) {
    if (_currentUser == null) return;
    _firestoreService.markNotificationAsRead(_currentUser!.uid, notif.id!);

    // Handle navigation based on notification type or payload
    // You might want to use the 'payload' field for more specific navigation
    switch (notif.type) {
      case "expired":
      case "at_risk":
        // Example: Navigate to pantry item detail if payload contains itemId
        if (notif.payload != null && notif.payload!.startsWith('itemId:')) {
          final itemId = notif.payload!.split(':')[1];
          Navigator.pushNamed(
            context,
            "/pantry", // Assuming you have a route for pantry item details
            arguments: {"itemId": itemId},
          );
        } else {
          Navigator.pushNamed(context, "/pantryinventory"); // Navigate to general pantry
        }
        break;
      case "recommendation":
        Navigator.pushNamed(context, "/shoppinglist");
        break;
      case "tip":
        Navigator.pushNamed(context, "/tips");
        break;
      case "update":
        // Navigator.pushNamed(context, "/updates"); // Assuming you have an updates page
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

    return StreamBuilder<List<AppNotificationModel>>(
      stream: _currentUser != null
          ? _firestoreService.getAppNotificationsStream(_currentUser!.uid)
          : Stream.value([]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final notifications = snapshot.data ?? [];

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
                    Expanded( // Use Expanded to prevent overflow
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end, // Align buttons to the end
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.done_all,
                              color: Color(0xFF2E7D32),
                            ),
                            onPressed: () => _markAllAsRead(notifications),
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
                              // For Spark plan, we mark all as read instead of clearing
                              _markAllAsRead(notifications);
                            },
                          ),
                        ],
                      ),
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
                        return Dismissible(
                          key: Key(notif.id!),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) => _deleteNotification(notif.id!),
                          child: Card(
                            color: notif.isRead
                                ? Colors.grey.shade200
                                : Colors.green.shade100,
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: ListTile(
                              onTap: () => _handleNotificationTap(notif),
                              leading: Icon(
                                _getNotificationIcon(notif.type), // Helper to get icon
                                color: const Color(0xFF2E7D32),
                                size: 36,
                              ),
                              title: Text(
                                notif.title,
                                style: TextStyle(
                                  fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                notif.body,
                                style: const TextStyle(color: Colors.black54),
                              ),
                              trailing: notif.isRead
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
      },
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'expired':
        return Icons.warning;
      case 'at_risk':
        return Icons.hourglass_empty;
      case 'update':
        return Icons.system_update_alt;
      case 'recommendation':
        return Icons.lightbulb_outline;
      case 'tip':
        return Icons.info_outline;
      default:
        return Icons.notifications;
    }
  }
}
