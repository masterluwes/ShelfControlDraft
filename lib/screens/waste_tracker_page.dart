import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:shelf_control/services/firestore_service.dart';
import 'package:shelf_control/models/pantry_item_model.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../services/report_service.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shelf_control/models/shopping_history_item_model.dart';

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
  const WasteTrackerPage({
    super.key,
  });

  @override
  State<WasteTrackerPage> createState() => _WasteTrackerPageState();
}

// Define a class to hold all computed waste data
class _WasteData {
  final List<ShoppingHistoryItemModel> allHistoryItems;
  final WeekPeriod selectedWeek;
  final List<int> weeklyWasteSeries;
  final List<int> weeklyConsumedSeries;
  final List<ShoppingHistoryItemModel> wastedThisWeek;
  final List<ShoppingHistoryItemModel> consumedThisWeek;
  final int thisWeekWaste;
  final int thisWeekConsumed;
  final int lastWeekWaste;
  final int lastWeekConsumed;
  final double thisWeekRate;
  final double lastWeekRate;
  final double wasteCost;
  final int thisWeekWastePct;
  final int lastWeekWastePct;
  final String mostWastedCategory;

  _WasteData({
    required this.allHistoryItems,
    required this.selectedWeek,
    required this.weeklyWasteSeries,
    required this.weeklyConsumedSeries,
    required this.wastedThisWeek,
    required this.consumedThisWeek,
    required this.thisWeekWaste,
    required this.thisWeekConsumed,
    required this.lastWeekWaste,
    required this.lastWeekConsumed,
    required this.thisWeekRate,
    required this.lastWeekRate,
    required this.wasteCost,
    required this.thisWeekWastePct,
    required this.lastWeekWastePct,
    required this.mostWastedCategory,
  });

  factory _WasteData.fromHistoryItems(List<ShoppingHistoryItemModel> allHistoryItems, WeekPeriod selectedWeek) {
    final rangeStart = selectedWeek.startDate;
    final rangeEnd = selectedWeek.endDate.add(const Duration(hours: 23, minutes: 59, seconds: 59));

    bool inRange(DateTime? d) => d != null && !d.isBefore(rangeStart) && !d.isAfter(rangeEnd);

    final wastedThisWeek = allHistoryItems.where((i) => (i.actionType == 'Wasted' || i.actionType == 'Expired Waste') && inRange(i.purchaseDate)).toList();
    final consumedThisWeek = allHistoryItems.where((i) => i.actionType == 'Consumed' && inRange(i.purchaseDate)).toList();

    final thisWeekWaste = wastedThisWeek.fold<int>(0, (s, i) => s + (i.quantity));
    final thisWeekConsumed = consumedThisWeek.fold<int>(0, (s, i) => s + (i.quantity));

    final lastStart = rangeStart.subtract(const Duration(days: 7));
    final lastEnd = rangeEnd.subtract(const Duration(days: 7));

    bool inLastRange(DateTime? d) => d != null && !d.isBefore(lastStart) && !d.isAfter(lastEnd);

    final wastedLastWeek = allHistoryItems.where((i) => (i.actionType == 'Wasted' || i.actionType == 'Expired Waste') && inLastRange(i.purchaseDate)).toList();
    final consumedLastWeek = allHistoryItems.where((i) => i.actionType == 'Consumed' && inLastRange(i.purchaseDate)).toList();

    final lastWeekWaste = wastedLastWeek.fold<int>(0, (s, i) => s + (i.quantity));
    final lastWeekConsumed = consumedLastWeek.fold<int>(0, (s, i) => s + (i.quantity));

    final thisOutflow = thisWeekWaste + thisWeekConsumed;
    final lastOutflow = lastWeekWaste + lastWeekConsumed;

    final double thisWeekRate = thisOutflow == 0 ? 0 : (thisWeekConsumed / thisOutflow * 100);
    final double lastWeekRate = lastOutflow == 0 ? 0 : (lastWeekConsumed / lastOutflow * 100);

    final double wasteCost = wastedThisWeek.fold<double>(0, (sum, i) => sum + ((i.priceAtAction ?? 0) * (i.quantity)));

    final thisWeekWastePct = thisOutflow == 0 ? 0 : ((thisWeekWaste / thisOutflow) * 100).round();
    final lastWeekWastePct = lastOutflow == 0 ? 0 : ((lastWeekWaste / lastOutflow) * 100).round();

    final Map<String, int> wastedByCategory = {};
    for (final i in wastedThisWeek) {
      final cat = i.category ?? 'Uncategorized';
      wastedByCategory[cat] = (wastedByCategory[cat] ?? 0) + (i.quantity);
    }
    final mostWastedCategory = wastedByCategory.entries.isEmpty
        ? '—'
        : wastedByCategory.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    final List<int> weeklyWasteSeries = [];
    final List<int> weeklyConsumedSeries = [];
    final now = DateTime.now();

    for (int back = 7; back >= 0; back--) {
      final end = DateTime(now.year, now.month, now.day).subtract(Duration(days: 7 * back));
      final start = end.subtract(const Duration(days: 6));

      int w = 0, c = 0;
      for (final i in allHistoryItems) {
        final date = i.purchaseDate;
        if ((i.actionType == 'Wasted' || i.actionType == 'Expired Waste') && date != null && !date.isBefore(start) && !date.isAfter(end)) {
          w += (i.quantity);
        }
        if (i.actionType == 'Consumed' && date != null && !date.isBefore(start) && !date.isAfter(end)) {
          c += (i.quantity);
        }
      }
      weeklyWasteSeries.add(w);
      weeklyConsumedSeries.add(c);
    }

    return _WasteData(
      allHistoryItems: allHistoryItems,
      selectedWeek: selectedWeek,
      weeklyWasteSeries: weeklyWasteSeries,
      weeklyConsumedSeries: weeklyConsumedSeries,
      wastedThisWeek: wastedThisWeek,
      consumedThisWeek: consumedThisWeek,
      thisWeekWaste: thisWeekWaste,
      thisWeekConsumed: thisWeekConsumed,
      lastWeekWaste: lastWeekWaste,
      lastWeekConsumed: lastWeekConsumed,
      thisWeekRate: thisWeekRate,
      lastWeekRate: lastWeekRate,
      wasteCost: wasteCost,
      thisWeekWastePct: thisWeekWastePct,
      lastWeekWastePct: lastWeekWastePct,
      mostWastedCategory: mostWastedCategory,
    );
  }
}

class _WasteTrackerPageState extends State<WasteTrackerPage> {
  List<WeekPeriod> weeks = [];
  WeekPeriod? selectedWeek;

  bool showWastedItems = false;
  bool showConsumedItems = false;

  String _selectedGraph = 'waste';

  final _trendKey = GlobalKey();
  List<ShoppingHistoryItemModel> _latestHistoryItems = [];

  Future<Uint8List?> _capturePng(GlobalKey key,
      {double pixelRatio = 1.5}) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _exportWeeklyPdfForRange(
      DateTime rangeStart, DateTime rangeEnd) async {
    // Ensure the chart is on-screen for capture
    final trendPng = await _capturePng(_trendKey);

    bool inRange(DateTime? d) =>
        d != null && !d.isBefore(rangeStart) && !d.isAfter(rangeEnd);

    final wastedThisRange = _latestHistoryItems
        .where((i) => (i.actionType == 'Wasted' || i.actionType == 'Expired Waste') && inRange(i.purchaseDate))
        .toList();
    final consumedThisRange = _latestHistoryItems
        .where((i) => i.actionType == 'Consumed' && inRange(i.purchaseDate))
        .toList();

    final totalWastedItems =
        wastedThisRange.fold<int>(0, (s, i) => s + (i.quantity));
    final totalItemsOut = totalWastedItems +
        consumedThisRange.fold<int>(0, (s, i) => s + (i.quantity));
    final totalWasteCost = wastedThisRange.fold<double>(
        0, (s, i) => s + ((i.priceAtAction ?? 0) * (i.quantity)));

    // Your model has no weight field—use 0.0 and the PDF will hide that KPI
    final totalWasteKg = 0.0;

    // Category aggregation
    final Map<String, CategoryRow> categoryRows = {};
    for (final cat
        in wastedThisRange.map((i) => i.category ?? 'Uncategorized').toSet()) {
      final list =
          wastedThisRange.where((i) => (i.category ?? 'Uncategorized') == cat);
      final count = list.fold<int>(0, (s, i) => s + (i.quantity));
      final cost = list.fold<double>(
          0, (s, i) => s + ((i.priceAtAction ?? 0) * (i.quantity)));
      categoryRows[cat] =
          CategoryRow(category: cat, itemsWasted: count, totalCost: cost);
    }
    final totalCostSum =
        categoryRows.values.fold<double>(0, (s, r) => s + r.totalCost);
    for (final r in categoryRows.values.toList()) {
      final share =
          (totalCostSum > 0) ? (r.totalCost / totalCostSum) * 100.0 : 0.0;
      categoryRows[r.category] = CategoryRow(
        category: r.category,
        itemsWasted: r.itemsWasted,
        totalCost: r.totalCost,
        sharePercent: share,
      );
    }

    // Detailed item rows
    final List<ItemWasteRow> itemRows = wastedThisRange.map((i) {
      return ItemWasteRow(
        category: i.category ?? 'Uncategorized',
        itemName: i.productName,
        quantity: i.quantity,
        cost: i.priceAtAction,
        expiryDate: null, // ShoppingHistoryItemModel does not have expiryDate
        wastedAt: i.purchaseDate,
      );
    }).toList();

    // Quick insights for the PDF
    final topCat = categoryRows.values.isEmpty
        ? null
        : categoryRows.values
            .reduce((a, b) => a.totalCost >= b.totalCost ? a : b);

    final insights = <String>[
      'You wasted ${_percent(totalWastedItems, totalItemsOut)} of items leaving your pantry in this period — review expiry dates more often.',
      if (topCat != null) 'Most waste occurred in ${topCat.category}.',
    ];

    final suggestions = <String>[
      'Consider smaller restocks for frequently wasted items.',
      'Keep perishable goods (like Dairy) in front (FIFO).',
    ];

    final stats = WasteWeeklyStats(
      householdName: 'Household', // plug actual name if you have it
      weekStart: rangeStart,
      weekEnd: rangeEnd,
      generatedAt: DateTime.now(),
      totalWastedItems: totalWastedItems,
      totalItemsOut: totalItemsOut,
      totalWasteCost: totalWasteCost,
      totalWasteWeightKg: totalWasteKg,
      categoryRows: categoryRows,
      itemWasteRows: itemRows,
      behavioralInsights: insights,
      baseRecommendations: suggestions,
      weeklyTrendPng: trendPng,
      costByCategoryPng: null, // add if you make a second chart later
    );

    await initializeDateFormatting('en_PH');

// Now build and share the PDF
    final pdfBytes = await WasteReportService().buildWeeklyPdf(stats);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename:
          'ShelfControl_Waste_${DateFormat('yyyyMMdd').format(rangeEnd)}.pdf',
    );

    final dir = await getApplicationDocumentsDirectory();
    final filename =
        'ShelfControl_Waste_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(pdfBytes);

    print('📁 Saved PDF locally at: ${file.path}');
  }

  String _percent(int part, int whole) {
    if (whole == 0) return '0%';
    final p = (part / whole) * 100.0;
    return '${p.toStringAsFixed(1)}%';
  }

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

    // Build the last 8 week periods ending today
    final now = DateTime.now();
    weeks = List.generate(8, (i) {
      final end = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 7 * i));
      final start = end.subtract(const Duration(days: 6));
      // If you don't need calendar week numbers, just use i+1
      final weekNumber = i + 1;
      return WeekPeriod(weekNumber: weekNumber, startDate: start, endDate: end);
    }).reversed.toList(); // oldest → newest (reverse if you want newest first)

    selectedWeek = weeks.last; // default to current week
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
                      onTap: () async {
                        Navigator.pop(context);
                        if (selectedWeek == null) return;

                        final start = DateTime(
                          selectedWeek!.startDate.year,
                          selectedWeek!.startDate.month,
                          selectedWeek!.startDate.day,
                        );
                        final end = DateTime(
                          selectedWeek!.endDate.year,
                          selectedWeek!.endDate.month,
                          selectedWeek!.endDate.day,
                          23,
                          59,
                          59,
                        );

                        await _exportWeeklyPdfForRange(start, end);
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
                      onPressed: () async {
                        Navigator.pop(context);
                        // Minimal: export full span from first to last week in the dropdowns
                        final start = DateTime(
                            weeks.first.startDate.year,
                            weeks.first.startDate.month,
                            weeks.first.startDate.day);
                        final end = DateTime(
                            weeks.last.endDate.year,
                            weeks.last.endDate.month,
                            weeks.last.endDate.day,
                            23,
                            59,
                            59);
                        await _exportWeeklyPdfForRange(start, end);
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
    // 1) Get service + selected household
    final firestore = Provider.of<FirestoreService>(context, listen: false);
    final householdId = firestore.selectedHouseholdId;

    // 2) Stream shopping history items for the household
    return StreamBuilder<List<ShoppingHistoryItemModel>>(
      stream: householdId == null
          ? const Stream<List<ShoppingHistoryItemModel>>.empty()
          : firestore.getShoppingHistoryForHousehold(householdId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allHistoryItems = snap.data ?? [];

        _latestHistoryItems = allHistoryItems;

        // Compute all waste data once
        final wasteData = _WasteData.fromHistoryItems(allHistoryItems, selectedWeek!);
        
        // 3) Get current week range from the dropdown selection
        final rangeStart = wasteData.selectedWeek.startDate;
        final rangeEnd = wasteData.selectedWeek.endDate
            .add(const Duration(hours: 23, minutes: 59, seconds: 59));

        // 4) Compute “this week”
        final wastedThisWeek = wasteData.wastedThisWeek;
        final consumedThisWeek = wasteData.consumedThisWeek;

        final thisWeekWaste = wasteData.thisWeekWaste;
        final thisWeekConsumed = wasteData.thisWeekConsumed;

        // 5) Compute “last week” (for comparisons)
        final lastWeekWaste = wasteData.lastWeekWaste;
        final lastWeekConsumed = wasteData.lastWeekConsumed;

        // 6) Percentages (outflow-based)
        final double thisWeekRate = wasteData.thisWeekRate;
        final double lastWeekRate = wasteData.lastWeekRate;

        // Total wasted money this week (guard nulls)
        final double wasteCost = wasteData.wasteCost;

        final thisWeekWastePct = wasteData.thisWeekWastePct;
        final lastWeekWastePct = wasteData.lastWeekWastePct;

        // 7) Category breakdown + most wasted category
        final mostWastedCategory = wasteData.mostWastedCategory;

        // 8) Trend series (last 8 weeks) for your charts
        final List<int> weeklyWasteSeries = wasteData.weeklyWasteSeries;
        final List<int> weeklyConsumedSeries = wasteData.weeklyConsumedSeries;

        return Scaffold(
          backgroundColor: const Color(0xFFFFFBE6),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
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
                                            color: Colors.white),
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
                        RepaintBoundary(
                          key: _trendKey,
                          child: SizedBox(
                            height: 250,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: BarChart(
                                BarChartData(
                                  gridData: const FlGridData(
                                      show: true, drawVerticalLine: false),
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY: _selectedGraph == "waste"
                                      ? (weeklyWasteSeries.isEmpty
                                          ? 5
                                          : (weeklyWasteSeries.reduce(
                                                      (a, b) => a > b ? a : b) +
                                                  2)
                                              .toDouble())
                                      : (weeklyConsumedSeries.isEmpty
                                          ? 5
                                          : (weeklyConsumedSeries.reduce(
                                                      (a, b) => a > b ? a : b) +
                                                  2)
                                              .toDouble()),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                            showTitles: true,
                                            interval: 1, // Align numbers to integers
                                            getTitlesWidget: (value, meta) {
                                              return Text(value.toInt().toString(),
                                                  style: const TextStyle(fontSize: 10));
                                            })),
                                    rightTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          final index = value.toInt();
                                          final total =
                                              _selectedGraph == "waste"
                                                  ? weeklyWasteSeries.length
                                                  : weeklyConsumedSeries.length;
                                          // Show last 8 weeks as W-7 ... W current
                                          if (index >= 0 && index < total) {
                                            return Text("W${8 - index}",
                                                style: const TextStyle(
                                                    fontSize: 10));
                                          }
                                          return const SizedBox.shrink();
                                        },
                                      ),
                                    ),
                                  ),
                                  barGroups: List.generate(
                                    (_selectedGraph == "waste"
                                        ? weeklyWasteSeries.length
                                        : weeklyConsumedSeries.length),
                                    (index) {
                                      final data = _selectedGraph == "waste"
                                          ? weeklyWasteSeries
                                          : weeklyConsumedSeries;
                                      final y =
                                          (index >= 0 && index < data.length)
                                              ? data[index].toDouble()
                                              : 0.0;
                                      return BarChartGroupData(
                                        x: index,
                                        barRods: [
                                          BarChartRodData(
                                            toY: y,
                                            width: 14,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Waste comparison
                        const Text(
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("This week's total waste:"),
                                  Text("$thisWeekWaste"),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Last week's total waste:"),
                                  Text("$lastWeekWaste"),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Total wasted money this week:"),
                                  Text(
                                    "₱${wasteCost.toStringAsFixed(2)}",
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                style: const TextStyle(fontWeight: FontWeight.bold),
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
                            children: wastedThisWeek.map((item) {
                              final qty = item.quantity;
                              final priceEach = item.priceAtAction ?? 0;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "($qty) ${item.productName}  ${priceEach > 0 ? "₱${priceEach.toStringAsFixed(2)} each" : ""}",
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      item.category ?? "Uncategorized",
                                      style: const TextStyle(
                                          color: Colors.black54),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),

                        const SizedBox(height: 24),
                        // Consumption
                        const Text(
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("This week's consumption:"),
                                  Text(
                                      "${thisWeekWastePct.toStringAsFixed(1)}%"),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Last week's consumption:"),
                                  Text(
                                      "${lastWeekWastePct.toStringAsFixed(1)}%"),
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
                                  getConsumptionInsight(
                                      thisWeekRate, lastWeekRate),
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
                                style: const TextStyle(fontWeight: FontWeight.bold),
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
                            children: consumedThisWeek.map((item) {
                              final qty = item.quantity;
                              final priceEach = item.priceAtAction ?? 0;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "($qty) ${item.productName}  ${priceEach > 0 ? "₱${priceEach.toStringAsFixed(2)} each" : ""}",
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      item.category ?? "Uncategorized",
                                      style: const TextStyle(
                                          color: Colors.black54),
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
      },
    );
  }
}
