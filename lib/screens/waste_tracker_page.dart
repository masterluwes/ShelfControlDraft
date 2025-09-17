import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

// for the week dropdown
class WeekPeriod {
  final int weekNumber;
  final DateTime startDate;
  final DateTime endDate;

  WeekPeriod({
    required this.weekNumber,
    required this.startDate,
    required this.endDate,
  });

  String get label => "Week $weekNumber (${_formatDate(startDate)})";
  String get fullLabel =>
      "Week $weekNumber (${_formatDate(startDate)} - ${_formatDate(endDate)})";

  static String _formatDate(DateTime date) {
    return "${_monthShort(date.month)} ${date.day}, ${date.year}";
  }

  static String _monthShort(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return months[month - 1];
  }

  factory WeekPeriod.fromJson(Map<String, dynamic> json) {
    return WeekPeriod(
      weekNumber: json['week'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
    );
  }

  Map<String, dynamic> toJson() => {
    "week": weekNumber,
    "startDate": startDate.toIso8601String(),
    "endDate": endDate.toIso8601String(),
  };
}

class WasteTrackerPage extends StatefulWidget {
  const WasteTrackerPage({super.key});

  @override
  State<WasteTrackerPage> createState() => _WasteTrackerPageState();
}

class _WasteTrackerPageState extends State<WasteTrackerPage> {
  List<WeekPeriod> weeks = [];
  WeekPeriod? selectedWeek;

  // Placeholder values for now (waste week comparison )
  double thisWeekWaste = 1.95;
  double lastWeekWaste = 13.62;

  String mostWastedCategory = "Grain";
  List<Map<String, String>> wastedItems = [
    {"name": "Oats", "status": "Expired"},
    {"name": "Sliced Bread", "status": "Expired"},
    {"name": "Milk", "status": "Spoiled"},
    {"name": "Canned Good", "status": "Expired"},
  ];
  bool showWastedItems = false;
  double avgDailyWaste = 2.17;

  @override
  void initState() {
    super.initState();

    // Mock data for nowwwww for week dropdown
    weeks = [
      WeekPeriod(
        weekNumber: 1,
        startDate: DateTime(2025, 8, 27),
        endDate: DateTime(2025, 9, 3),
      ),
      WeekPeriod(
        weekNumber: 2,
        startDate: DateTime(2025, 9, 4),
        endDate: DateTime(2025, 9, 10),
      ),
      WeekPeriod(
        weekNumber: 3,
        startDate: DateTime(2025, 9, 11),
        endDate: DateTime(2025, 9, 17),
      ),
    ];
    selectedWeek = weeks.first;
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 70, right: 16),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 260,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "This page summarizes your food waste for the week, "
                  "highlighting top waste items and trends to help you improve.",
                  style: TextStyle(fontSize: 14, color: Colors.black),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSaveReportDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 140, right: 16),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 260,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(color: const Color(0xFF2E7D32), width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Save waste statistics",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // This week
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text("This week"),
                      onTap: () {
                        Navigator.pop(context);
                        // Backend call
                      },
                    ),

                    // This month
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text("This month"),
                      onTap: () {
                        Navigator.pop(context);
                        //  Backend call
                      },
                    ),

                    // Custom range
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Custom"),
                      onTap: () {
                        Navigator.pop(context);
                        _showCustomWeekPopup(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCustomWeekPopup(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 180, right: 16),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 280,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(color: const Color(0xFF2E7D32), width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Choose weeks:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    DropdownButton<WeekPeriod>(
                      value: weeks.first,
                      items: weeks.map((w) {
                        return DropdownMenuItem(value: w, child: Text(w.label));
                      }).toList(),
                      onChanged: (_) {},
                    ),

                    DropdownButton<WeekPeriod>(
                      value: weeks.last,
                      items: weeks.map((w) {
                        return DropdownMenuItem(value: w, child: Text(w.label));
                      }).toList(),
                      onChanged: (_) {},
                    ),

                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Backend call
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("Save"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _saveReport(String type, dynamic data) {
    //  for backend connection, here dito yung pag issave sya dat massave as pdf
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBE6),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  GestureDetector(
                    onTap: () => _showInfoDialog(context),
                    child: const Icon(Icons.info, color: Color(0xFF2E7D32)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  const Center(
                    child: Text(
                      "Waste Tracker",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton2<WeekPeriod>(
                              value: selectedWeek,
                              isExpanded: true,
                              dropdownStyleData: DropdownStyleData(
                                maxHeight: 200,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E7D32),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                offset: const Offset(0, -4),
                              ),
                              buttonStyleData: const ButtonStyleData(
                                height: 40,
                                padding: EdgeInsets.only(right: 8),
                              ),
                              iconStyleData: const IconStyleData(
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.white,
                                ),
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              onChanged: (value) =>
                                  setState(() => selectedWeek = value),
                              items: weeks.map((week) {
                                return DropdownMenuItem<WeekPeriod>(
                                  value: week,
                                  child: Text(
                                    week.label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () => _showSaveReportDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[600],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: EdgeInsets.zero,
                              textStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text("Save Report"),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "This Week's Daily Waste",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Waste Comparison Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black26),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // This week
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("This week's total waste:"),
                              Text(
                                "${thisWeekWaste.toStringAsFixed(2)} lbs",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Last week
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Last week's total waste:"),
                              Text(
                                "${lastWeekWaste.toStringAsFixed(2)} lbs",
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Insight box, the ai generated text thingy will be here for the total waste vs last week waste
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF2E7D32),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              "Amazing! You’ve reduced your waste by 85.68%. "
                              "Let’s aim for even better next week.",
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    // Most Wasted Category Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black26),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Most wasted category
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Most wasted category this week:"),
                              Text(
                                mostWastedCategory,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Insight text, ai generated text thingy for the most wasted category
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF2E7D32),
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              "Grain waste was high this week. Check out the Tops & Suggestions "
                              "section to learn how to make the most of your grains and cut down on waste.",
                              style: TextStyle(fontSize: 14),
                            ),
                          ),

                          const SizedBox(height: 12),
                          // Wasted items
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                showWastedItems = !showWastedItems;
                              });
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Wasted Items: ${wastedItems.length} Items",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Icon(
                                  showWastedItems
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                          ),
                          if (showWastedItems) ...[
                            const SizedBox(height: 8),
                            Column(
                              children: wastedItems.map((item) {
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(item["name"] ?? ""),
                                    Text(
                                      item["status"] ?? "",
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ],

                          const SizedBox(height: 12),
                          // Average Daily Waste
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Average Daily Waste:"),
                              Text(
                                "${avgDailyWaste.toStringAsFixed(2)} lbs",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Insight ai generated text thingy for average daily waste
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF2E7D32),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              "Your average daily waste this week is ${avgDailyWaste.toStringAsFixed(2)} lbs. "
                              "Check out the graph below to see your daily breakdowns and track your progress!",
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
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
