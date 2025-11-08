import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:shelf_control/services/firestore_service.dart'; // Import FirestoreService
import 'package:shelf_control/models/app_notification_model.dart'; // Import AppNotificationModel
import 'package:dropdown_button2/dropdown_button2.dart'; // Import for custom dropdown
import 'dart:convert'; // Import for jsonDecode

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

  // Filter and Sort state
  String _selectedFilter = 'All';
  String _selectedSort = 'Newest';

  final List<String> _filterOptions = ['All', 'Unread', 'Expired', 'At Risk', 'Recommendations', 'Tips'];
  final List<String> _sortOptions = ['Newest', 'Oldest', 'Type'];

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

  // Helper for building dropdowns
  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String tooltip,
  }) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        value: value,
        customButton: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE9E1C7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF20451F),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const Icon(
                Icons.arrow_drop_down,
                color: Color(0xFF20451F),
              ),
            ],
          ),
        ),
        items: items
            .map((item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 14),
                  ),
                ))
            .toList(),
        onChanged: onChanged,
        dropdownStyleData: DropdownStyleData(
          width: 160,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.white,
          ),
          offset: const Offset(0, 0),
        ),
        menuItemStyleData: const MenuItemStyleData(
          height: 40,
          padding: EdgeInsets.only(left: 14, right: 14),
        ),
      ),
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
        List<AppNotificationModel> notifications = snapshot.data ?? [];

        // Apply filtering
        notifications = notifications.where((notif) {
          switch (_selectedFilter) {
            case 'Unread':
              return !notif.isRead;
            case 'Expired':
              return notif.type == 'expired';
            case 'At Risk':
              return notif.type == 'at_risk';
            case 'Recommendations':
              return notif.type == 'recommendation';
            case 'Tips':
              return notif.type == 'tip';
            case 'All':
            default:
              return true;
          }
        }).toList();

        // Apply sorting
        notifications.sort((a, b) {
          switch (_selectedSort) {
            case 'Oldest':
              return a.createdAt.compareTo(b.createdAt);
            case 'Type':
              return a.type.compareTo(b.type);
            case 'Newest':
            default:
              return b.createdAt.compareTo(a.createdAt);
          }
        });

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
                  Expanded( // Use Expanded to prevent overflow
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end, // Align buttons to the end
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.filter_list, // Filter/Sort icon
                            color: Color(0xFF2E7D32),
                          ),
                          onPressed: _showFilterSortBottomSheet,
                          tooltip: "Filter and Sort",
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.done_all,
                            color: Color(0xFF2E7D32),
                          ),
                          onPressed: notifications.isNotEmpty ? () => _markAllAsRead(notifications) : null,
                          tooltip: "Mark all as read",
                        ),
                        IconButton(
                          icon: const Icon(Icons.snooze, color: Color(0xFF2E7D32)),
                          onPressed: _showSnoozeDialog,
                          tooltip: "Snooze notifications",
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
                              subtitle: FutureBuilder<String>(
                                future: _getNotificationSubtitle(notif),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Text('Loading...', style: TextStyle(color: Colors.black54));
                                  } else if (snapshot.hasError) {
                                    return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                                  } else {
                                    return Text(
                                      snapshot.data ?? notif.body, // Use the formatted subtitle or fallback to original body
                                      style: const TextStyle(color: Colors.black54),
                                    );
                                  }
                                },
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
      case 'pantry_summary': // Added for pantry_summary type
        return Icons.fastfood; // Or another appropriate icon
      default:
        return Icons.notifications;
    }
  }

  Future<String> _getNotificationSubtitle(AppNotificationModel notif) async {
    print('[_getNotificationSubtitle] Notification Type: ${notif.type}');
    print('[_getNotificationSubtitle] Notification Payload: ${notif.payload}');

    if (notif.type == 'pantry_summary' && notif.payload != null) {
      try {
        final Map<String, dynamic> payload = jsonDecode(notif.payload!);
        print('[_getNotificationSubtitle] Parsed Payload: $payload');
        final List<String> expired = List<String>.from(payload['expiredItemNames'] ?? []);
        final List<String> atRisk = List<String>.from(payload['atRiskItemNames'] ?? []);

        String subtitleText = '';
        // Fetch household name
        final household = await _firestoreService.getHousehold(notif.householdId);
        final householdName = household?.name ?? 'Your Pantry';

        List<String> parts = [];
        if (expired.isNotEmpty) {
          parts.add('You have ${expired.length} expired item(s): ${expired.join(', ')}');
        }
        if (atRisk.isNotEmpty) {
          parts.add('You have ${atRisk.length} item(s) at risk of expiring soon: ${atRisk.join(', ')}');
        }

        if (parts.isNotEmpty) {
          subtitleText = '$householdName:\n${parts.join('\n')}';
        } else {
          // If payload parsing didn't yield specific items, but notif.body has details, use notif.body
          if (notif.body.isNotEmpty && notif.body != notif.title) {
            subtitleText = '$householdName: ${notif.body}';
          } else {
            subtitleText = '$householdName: No specific alerts.';
          }
        }
        print('[_getNotificationSubtitle] Generated Subtitle: $subtitleText');
        return subtitleText;
      } catch (e) {
        print('[_getNotificationSubtitle] Error parsing pantry_summary payload: $e');
        return notif.body; // Fallback to original body if JSON parsing fails
      }
    }
    print('[_getNotificationSubtitle] Returning original body: ${notif.body}');
    return notif.body;
  }

  void _showFilterSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Notifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    spacing: 8.0,
                    children: _filterOptions.map((filter) {
                      return ChoiceChip(
                        label: Text(filter),
                        selected: _selectedFilter == filter,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {
                              _selectedFilter = filter;
                            });
                            setState(() {
                              _selectedFilter = filter;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Sort By',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    spacing: 8.0,
                    children: _sortOptions.map((sort) {
                      return ChoiceChip(
                        label: Text(sort),
                        selected: _selectedSort == sort,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {
                              _selectedSort = sort;
                            });
                            setState(() {
                              _selectedSort = sort;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10), // Reduced spacing
                ],
              ),
            );
          },
        );
      },
    );
  }
}
