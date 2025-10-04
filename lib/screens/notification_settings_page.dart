import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:shelf_control/services/firestore_service.dart'; // Import FirestoreService
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  NotificationSettingsPageState createState() =>
      NotificationSettingsPageState();
}

class NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool expiredItems = true;
  bool atRiskItems = true;
  bool appUpdates = true;
  bool itemRecommendations = true;
  bool tipsSuggestions = true;

  int daysForAtRisk = 0;
  TimeOfDay expiryAndRiskNotificationTime = const TimeOfDay(hour: 7, minute: 0);

  late FirestoreService _firestoreService;
  late User? _currentUser;

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _currentUser = FirebaseAuth.instance.currentUser;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (_currentUser == null) return;

    final settings = await _firestoreService.getNotificationSettings(_currentUser!.uid);
    if (settings != null) {
      setState(() {
        expiredItems = settings['expiredItems'] ?? true;
        atRiskItems = settings['atRiskItems'] ?? true;
        appUpdates = settings['appUpdates'] ?? true;
        itemRecommendations = settings['itemRecommendations'] ?? true;
        tipsSuggestions = settings['tipsSuggestions'] ?? true;
        daysForAtRisk = settings['daysForAtRisk'] ?? 0;

        final timeString = settings['expiryAndRiskNotificationTime'];
        if (timeString != null) {
          final parts = timeString.split(':');
          expiryAndRiskNotificationTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      });
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    if (_currentUser == null) return;

    final currentSettings = await _firestoreService.getNotificationSettings(_currentUser!.uid) ?? {};
    currentSettings[key] = value;
    await _firestoreService.saveNotificationSettings(_currentUser!.uid, currentSettings);
    debugPrint("Saving setting: $key -> $value");
  }

  void _pickDays() {
    showDialog(
      context: context,
      builder: (ctx) {
        int tempValue = daysForAtRisk;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(0xFFFFFBE6),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Number of Days for 'At Risk' Items",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFF2E7D32),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    NumberPicker(
                      minValue: 0,
                      maxValue: 30,
                      value: tempValue,
                      itemHeight: 50,
                      textStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 18,
                      ),
                      selectedTextStyle: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      onChanged: (value) =>
                          setModalState(() => tempValue = value),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        setState(() => daysForAtRisk = tempValue);
                        _updateSetting("daysForAtRisk", tempValue);
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        "Close",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: expiryAndRiskNotificationTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: const Color(0xFFFFFBE6),
              hourMinuteColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? const Color(0xFF2E7D32)
                    : Colors.grey.shade200,
              ),
              hourMinuteTextColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? Colors.white
                    : Colors.black,
              ),
              dialHandColor: const Color(0xFF2E7D32),
              dialBackgroundColor: Colors.white,
              entryModeIconColor: const Color(0xFF2E7D32),
              dayPeriodColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? const Color(0xFF2E7D32)
                    : Colors.grey.shade200,
              ),
              dayPeriodTextColor: WidgetStateColor.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2E7D32),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        expiryAndRiskNotificationTime = picked;
      });
      final formatted =
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      _updateSetting("expiryAndRiskNotificationTime", formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBE6),
      body: SafeArea(
        child: Column(
          children: [
            // Back button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back, color: Color(0xFF2E7D32)),
                        SizedBox(width: 4),
                        Text(
                          'Back',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        "Notification Settings",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      "Show Notifications for",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                        fontSize: 18,
                      ),
                    ),

                    // Toggles
                    SwitchListTile(
                      title: const Text('"Expired" Items'),
                      value: expiredItems,
                      activeColor: const Color(0xFF2E7D32),
                      activeTrackColor: const Color(0xFF81C784),
                      onChanged: (val) {
                        setState(() => expiredItems = val);
                        _updateSetting("expiredItems", val);
                      },
                    ),
                    SwitchListTile(
                      title: const Text('"At risk" Items'),
                      value: atRiskItems,
                      activeColor: const Color(0xFF2E7D32),
                      activeTrackColor: const Color(0xFF81C784),
                      onChanged: (val) {
                        setState(() => atRiskItems = val);
                        _updateSetting("atRiskItems", val);
                      },
                    ),
                    SwitchListTile(
                      title: const Text("App Updates"),
                      value: appUpdates,
                      activeColor: const Color(0xFF2E7D32),
                      activeTrackColor: const Color(0xFF81C784),
                      onChanged: (val) {
                        setState(() => appUpdates = val);
                        _updateSetting("appUpdates", val);
                      },
                    ),
                    SwitchListTile(
                      title: const Text("Item Recommendations"),
                      value: itemRecommendations,
                      activeColor: const Color(0xFF2E7D32),
                      activeTrackColor: const Color(0xFF81C784),
                      onChanged: (val) {
                        setState(() => itemRecommendations = val);
                        _updateSetting("itemRecommendations", val);
                      },
                    ),
                    SwitchListTile(
                      title: const Text("Tips and Suggestions"),
                      value: tipsSuggestions,
                      activeColor: const Color(0xFF2E7D32),
                      activeTrackColor: const Color(0xFF81C784),
                      onChanged: (val) {
                        setState(() => tipsSuggestions = val);
                        _updateSetting("tipsSuggestions", val);
                      },
                    ),

                    const Divider(height: 30, thickness: 1.5),

                    // Days picker
                    GestureDetector(
                      onTap: _pickDays,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          "Number of Days for 'At Risk' Items\n$daysForAtRisk day(s)",
                          style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),

                    const Divider(height: 30, thickness: 1.5),

                    // Time picker
                    GestureDetector(
                      onTap: _pickTime,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          "Notification Time (for Expired & At Risk Items)\nSet to: ${expiryAndRiskNotificationTime.format(context)}",
                          style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),

                    const Divider(height: 30, thickness: 1.5),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
