import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _NotificationSettingsPageState createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool expiredItems = true;
  bool atRiskItems = true;
  bool appUpdates = true;
  bool itemRecommendations = true;
  bool tipsSuggestions = true;

  int daysForAtRisk = 0;
  TimeOfDay notificationTime = const TimeOfDay(hour: 7, minute: 0);

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
                        setState(
                          () => daysForAtRisk = tempValue,
                        ); // Update main
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
      initialTime: notificationTime,
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
        notificationTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBE6),
      body: SafeArea(
        child: Column(
          children: [
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
                    SwitchListTile(
                      title: const Text('"Expired" Items'),
                      value: expiredItems,
                      activeThumbColor: const Color(0xFF2E7D32),
                      activeTrackColor: const Color(0xFF81C784),
                      onChanged: (val) => setState(() => expiredItems = val),
                    ),
                    SwitchListTile(
                      title: const Text('"At risk" Items'),
                      value: atRiskItems,
                      activeThumbColor: const Color(0xFF2E7D32),
                      activeTrackColor: const Color(0xFF81C784),
                      onChanged: (val) => setState(() => atRiskItems = val),
                    ),
                    SwitchListTile(
                      title: const Text("App Updates"),
                      value: appUpdates,
                      activeThumbColor: const Color(0xFF2E7D32),
                      activeTrackColor: const Color(0xFF81C784),
                      onChanged: (val) => setState(() => appUpdates = val),
                    ),
                    SwitchListTile(
                      title: const Text("Item recommendations"),
                      value: itemRecommendations,
                      activeThumbColor: const Color(0xFF2E7D32),
                      activeTrackColor: const Color(0xFF81C784),
                      onChanged: (val) =>
                          setState(() => itemRecommendations = val),
                    ),
                    SwitchListTile(
                      title: const Text("Tips and Suggestions"),
                      value: tipsSuggestions,
                      activeThumbColor: const Color(0xFF2E7D32),
                      activeTrackColor: const Color(0xFF81C784),
                      onChanged: (val) => setState(() => tipsSuggestions = val),
                    ),
                    const Divider(height: 30, thickness: 1.5),

                    GestureDetector(
                      onTap: _pickDays,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          "Number of Days for “At Risk” Items\n$daysForAtRisk day(s)",
                          style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),

                    const Divider(height: 30, thickness: 1.5),

                    GestureDetector(
                      onTap: _pickTime,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          "Notification Time\nNotification time set to: ${notificationTime.format(context)}",
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
