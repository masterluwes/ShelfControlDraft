import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:fl_chart/fl_chart.dart';
import 'weekly_report.dart';

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
}

class WasteTrackerPage extends StatefulWidget {
  final WeeklyReport thisWeekReport;
  final WeeklyReport lastWeekReport;

  WasteTrackerPage({
    super.key,
    WeeklyReport? thisWeekReport,
    WeeklyReport? lastWeekReport,
  }) : thisWeekReport = thisWeekReport ?? WeeklyReport.mockThisWeek(),
       lastWeekReport = lastWeekReport ?? WeeklyReport.mockLastWeek();

  @override
  State<WasteTrackerPage> createState() => _WasteTrackerPageState();
}

class _WasteTrackerPageState extends State<WasteTrackerPage> {
  List<WeekPeriod> weeks = [];
  WeekPeriod? selectedWeek;

  bool showWastedItems = false;
  bool showConsumedItems = false;

  String mostWastedCategory = "Grain"; // placeholder for nowwww, change it po

  String _selectedGraph = 'waste';

  // mock for the graph
  final List<int> weeklyWaste = [1, 5, 0, 0, 0];
  final List<int> weeklyConsumptionPercent = [40, 75, 0, 0, 0];

  String getWasteInsight(int thisWeekWaste, int lastWeekWaste) {
    if (lastWeekWaste == 0 && thisWeekWaste == 0) {
      return "No waste recorded for both weeks. Let's keep improving!";
    } else if (lastWeekWaste == 0) {
      return "No waste recorded last week, but you had some this week. Keep an eye on reducing it!";
    }

    int diff = thisWeekWaste - lastWeekWaste;
    int maxVal = thisWeekWaste > lastWeekWaste ? thisWeekWaste : lastWeekWaste;

    double percentChange = (diff.abs() / maxVal) * 100;

    if (diff < 0) {
      return "Amazing! You’ve reduced your wasted items by ${percentChange.toStringAsFixed(1)}%. Keep it up!";
    } else if (diff > 0) {
      return "Oops! Your wasted items increased by ${percentChange.toStringAsFixed(1)}%. Check your storage and planning to reduce waste.";
    } else {
      return "You generated the same amount of waste as last week. Try new strategies to cut it down!";
    }
  }

  String getConsumptionInsight(double thisWeekRate, double lastWeekRate) {
    if (lastWeekRate == 0) {
      return "No consumption recorded last week. Tracking starts now!";
    }

    double diff = thisWeekRate - lastWeekRate;
    if (diff > 0) {
      return "Great job! Your food consumption rate improved by ${diff.toStringAsFixed(1)}% compared to last week.";
    } else if (diff < 0) {
      return "Hmm, your consumption rate dropped by ${diff.abs().toStringAsFixed(1)}%. Try planning meals to use more of your pantry items.";
    } else {
      return "Your consumption rate is the same as last week. Keep monitoring!";
    }
  }

  @override
  void initState() {
    super.initState();
    // Mock dropdown weeksss
    weeks = [
      WeekPeriod(
        weekNumber: 1,
        startDate: widget.lastWeekReport.startDate,
        endDate: widget.lastWeekReport.endDate,
      ),
      WeekPeriod(
        weekNumber: 2,
        startDate: widget.thisWeekReport.startDate,
        endDate: widget.thisWeekReport.endDate,
      ),
    ];
    selectedWeek = weeks.last;
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
    // Calculate totals
    int thisWeekWaste = widget.thisWeekReport.wastedItems.fold(
      0,
      (sum, item) => sum + item.quantity,
    );
    int lastWeekWaste = widget.lastWeekReport.wastedItems.fold(
      0,
      (sum, item) => sum + item.quantity,
    );

    int thisWeekConsumed = widget.thisWeekReport.consumedItems.fold(
      0,
      (sum, item) => sum + item.quantity,
    );
    int lastWeekConsumed = widget.lastWeekReport.consumedItems.fold(
      0,
      (sum, item) => sum + item.quantity,
    );

    double thisWeekRate = widget.thisWeekReport.pantryTotal == 0
        ? 0
        : (thisWeekConsumed / widget.thisWeekReport.pantryTotal) * 100;
    double lastWeekRate = widget.lastWeekReport.pantryTotal == 0
        ? 0
        : (lastWeekConsumed / widget.lastWeekReport.pantryTotal) * 100;

    double totalWastedMoneyThisWeek = widget.thisWeekReport.wastedItems.fold(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );

    Map<String, int> categoryWaste = {};
    for (var item in widget.thisWeekReport.wastedItems) {
      categoryWaste[item.category] =
          (categoryWaste[item.category] ?? 0) + item.quantity;
    }

    String mostWastedCategory = categoryWaste.isEmpty
        ? "None"
        : categoryWaste.entries.reduce((a, b) => a.value > b.value ? a : b).key;

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
                                    style: const TextStyle(color: Colors.white),
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
                  vertical: 4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Radio<String>(
                            value: "waste",
                            groupValue: _selectedGraph,
                            onChanged: (v) =>
                                setState(() => _selectedGraph = v!),
                          ),
                          const Text("Waste"),
                          Radio<String>(
                            value: "consumption",
                            groupValue: _selectedGraph,
                            onChanged: (v) =>
                                setState(() => _selectedGraph = v!),
                          ),
                          const Text("Consumption"),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 250,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: BarChart(
                          BarChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                            ),
                            alignment: BarChartAlignment.spaceAround,
                            maxY: _selectedGraph == "waste"
                                ? (weeklyWaste.reduce((a, b) => a > b ? a : b) +
                                          2)
                                      .toDouble()
                                : 100,
                            titlesData: FlTitlesData(
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  },
                                  interval: _selectedGraph == "waste" ? 1 : 20,
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final weeks = [
                                      "W1",
                                      "W2",
                                      "W3",
                                      "W4",
                                      "W5",
                                    ];
                                    if (value.toInt() >= 0 &&
                                        value.toInt() < weeks.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4.0,
                                        ),
                                        child: Text(weeks[value.toInt()]),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(
                                color: Colors.black,
                                width: 0.5,
                              ),
                            ),
                            barGroups: List.generate(5, (index) {
                              final data = _selectedGraph == "waste"
                                  ? weeklyWaste
                                  : weeklyConsumptionPercent;
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: data[index].toDouble(),
                                    color: _selectedGraph == "waste"
                                        ? Colors.red
                                        : Colors.green,
                                    width: 18,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Waste comparison
                    Text(
                      "This Week's Waste",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black26),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("This week's total waste:"),
                              Text("$thisWeekWaste"),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Last week's total waste:"),
                              Text("$lastWeekWaste"),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Total wasted money this week:"),
                              Text(
                                "₱${totalWastedMoneyThisWeek.toStringAsFixed(2)}",
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              getWasteInsight(thisWeekWaste, lastWeekWaste),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Most wasted category this week:"),
                              Text(mostWastedCategory),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "$mostWastedCategory waste was high this week. Check out the Tops & Suggestions section to learn how to cut down.",
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Wasted Items Expandable
                    GestureDetector(
                      onTap: () => setState(() {
                        showWastedItems = !showWastedItems;
                      }),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Wasted items this week: $thisWeekWaste",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Icon(
                            showWastedItems
                                ? Icons.expand_less
                                : Icons.expand_more,
                          ),
                        ],
                      ),
                    ),
                    if (showWastedItems)
                      Column(
                        children: widget.thisWeekReport.wastedItems.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "(${item.quantity}) ${item.name}  ₱${item.price.toStringAsFixed(2)} each",
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  item.status,
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 24),
                    // Consumption
                    Text(
                      "This Week's Food Usage",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black26),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("This week's consumption:"),
                              Text("${thisWeekRate.toStringAsFixed(1)}%"),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Last week's consumption:"),
                              Text("${lastWeekRate.toStringAsFixed(1)}%"),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              getConsumptionInsight(thisWeekRate, lastWeekRate),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => setState(() {
                        showConsumedItems = !showConsumedItems;
                      }),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Total Consumed Items: $thisWeekConsumed",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Icon(
                            showConsumedItems
                                ? Icons.expand_less
                                : Icons.expand_more,
                          ),
                        ],
                      ),
                    ),
                    if (showConsumedItems)
                      Column(
                        children: widget.thisWeekReport.consumedItems.map((
                          item,
                        ) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "(${item.quantity}) ${item.name}  ₱${item.price.toStringAsFixed(2)} each",
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  item.category,
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
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
