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
import 'package:shelf_control/models/waste_report_model.dart'; // Import WasteReportModel
import 'package:uuid/uuid.dart'; // For generating unique IDs
import 'package:shelf_control/screens/view_reports_page.dart'; // Import the new page
import 'package:shelf_control/models/household_model.dart'; // Import HouseholdModel
import 'package:cloud_firestore/cloud_firestore.dart'; // Import for Timestamp

// for the week dropdown
class WeekPeriod {
  final int relativeWeekNumber; // Week number relative to user creation
  final DateTime startDate;
  final DateTime endDate;

  WeekPeriod({
    required this.relativeWeekNumber,
    required this.startDate,
    required this.endDate,
  });

  String get label => "Week $relativeWeekNumber (${_formatDate(startDate)})";
  String get fullLabel =>
      "Week $relativeWeekNumber (${_formatDate(startDate)} - ${_formatDate(endDate)})";

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

  factory _WasteData.fromHistoryItems(List<ShoppingHistoryItemModel> allHistoryItems, WeekPeriod selectedWeek, List<WeekPeriod> weeks) {
    final rangeStart = selectedWeek.startDate;
    final rangeEnd = selectedWeek.endDate.add(const Duration(hours: 23, minutes: 59, seconds: 59));

    bool inRange(DateTime d) => !d.isBefore(rangeStart) && !d.isAfter(rangeEnd);

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

    final List<int> weeklyWasteSeries = List.filled(weeks.length, 0);
    final List<int> weeklyConsumedSeries = List.filled(weeks.length, 0);

    // Iterate through the available weeks, from newest to oldest
    for (int i = 0; i < weeks.length; i++) {
      final weekPeriod = weeks[i]; // Use the pre-calculated week periods (now newest to oldest)
      final start = weekPeriod.startDate;
      final end = weekPeriod.endDate.add(const Duration(hours: 23, minutes: 59, seconds: 59));

      int w = 0, c = 0;
      for (final item in allHistoryItems) {
        final date = item.purchaseDate;
        if (date != null && !date.isBefore(start) && !date.isAfter(end)) {
          if (item.actionType == 'Wasted' || item.actionType == 'Expired Waste') {
            w += (item.quantity);
          } else if (item.actionType == 'Consumed') {
            c += (item.quantity);
          }
        }
      }
      weeklyWasteSeries[i] = w;
      weeklyConsumedSeries[i] = c;
    }

    // No need to reverse, as weeks are already ordered newest to oldest
    // weeklyWasteSeries = weeklyWasteSeries.reversed.toList();
    // weeklyConsumedSeries = weeklyConsumedSeries.reversed.toList();

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
  DateTime? _householdCreationDate; // New state variable to store household creation date
  late List<WeekPeriod> weeks = []; // Initialize as empty, will be generated after fetching user data
  WeekPeriod? selectedWeek;
  WeekPeriod? _startWeekForCustomRange;
  WeekPeriod? _endWeekForCustomRange;

  bool showWastedItems = false;
  bool showConsumedItems = false;

  final _trendKey = GlobalKey();
  final _consumptionTrendKey = GlobalKey();
  List<ShoppingHistoryItemModel> _latestHistoryItems = [];
  final Uuid _uuid = const Uuid();

  // Removed duplicate initState. The one above is the correct one.

  Future<void> _fetchUserCreationDateAndGenerateWeeks() async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final householdId = firestoreService.selectedHouseholdId;
    debugPrint('DEBUG: _fetchUserCreationDateAndGenerateWeeks called. householdId: $householdId');

    if (householdId != null) {
      final household = await firestoreService.getHousehold(householdId);
      if (household != null && household.timestamp != null) {
        setState(() {
          _householdCreationDate = household.timestamp;
          weeks = _generateWeeks();
          selectedWeek = weeks.firstOrNull;
          _startWeekForCustomRange = weeks.lastOrNull;
          _endWeekForCustomRange = weeks.firstOrNull;
          debugPrint('DEBUG: Household creation date fetched: $_householdCreationDate, weeks generated: ${weeks.length}');
        });
      } else {
        // Fallback if household creation date is not found, use current date as "Week 1"
        setState(() {
          _householdCreationDate = DateTime.now();
          weeks = _generateWeeks();
          selectedWeek = weeks.firstOrNull;
          _startWeekForCustomRange = weeks.lastOrNull;
          _endWeekForCustomRange = weeks.firstOrNull;
          debugPrint('DEBUG: Household creation date not found, falling back to DateTime.now(). Weeks generated: ${weeks.length}');
        });
      }
    } else {
      // For guest users or if householdId is null, use current date as "Week 1"
      setState(() {
        _householdCreationDate = DateTime.now();
        weeks = _generateWeeks();
        selectedWeek = weeks.firstOrNull;
        _startWeekForCustomRange = weeks.lastOrNull;
        _endWeekForCustomRange = weeks.firstOrNull;
        debugPrint('DEBUG: householdId is null, falling back to DateTime.now(). Weeks generated: ${weeks.length}');
      });
    }
    // Ensure selectedWeek is always set, even if weeks is empty (though it shouldn't be if _householdCreationDate is set)
    if (selectedWeek == null && weeks.isNotEmpty) {
      setState(() {
        selectedWeek = weeks.first;
        _startWeekForCustomRange = weeks.last;
        _endWeekForCustomRange = weeks.first;
        debugPrint('DEBUG: selectedWeek was null, set to weeks.first: ${selectedWeek?.label}');
      });
    } else if (selectedWeek == null && weeks.isEmpty) {
      debugPrint('DEBUG: selectedWeek is null and weeks is empty. This might indicate an issue with _generateWeeks.');
    }
  }

  List<WeekPeriod> _generateWeeks() {
    if (_householdCreationDate == null) {
      return []; // Should not happen if _fetchUserCreationDateAndGenerateWeeks is called
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime currentWeekStart = today.subtract(Duration(days: today.weekday - DateTime.monday));

    // Calculate the start of the week for the household's creation date
    final normalizedHouseholdCreationDate = DateTime(_householdCreationDate!.year, _householdCreationDate!.month, _householdCreationDate!.day);
    DateTime creationWeekStart = normalizedHouseholdCreationDate.subtract(Duration(days: normalizedHouseholdCreationDate.weekday - DateTime.monday));
    debugPrint('DEBUG: _generateWeeks: raw creationWeekStart (normalized from household creation date): $creationWeekStart');

    // Adjust creationWeekStart if it's in the future relative to currentWeekStart
    // This handles cases where the device clock might be set in the past compared to Firestore's createdAt.
    if (creationWeekStart.isAfter(currentWeekStart)) {
      debugPrint('DEBUG: _generateWeeks: Adjusted creationWeekStart to currentWeekStart because it was in the future.');
      creationWeekStart = currentWeekStart;
    }
    debugPrint('DEBUG: _generateWeeks: effective creationWeekStart: $creationWeekStart');

    List<WeekPeriod> allPossibleWeeks = [];
    DateTime tempWeekStart = creationWeekStart;
    int weekCounter = 1;

    debugPrint('DEBUG: _generateWeeks: Entering loop. Initial tempWeekStart: $tempWeekStart, currentWeekStart: $currentWeekStart');
    // Generate all weeks from creation date up to and including the current week
    while (tempWeekStart.isBefore(currentWeekStart) || tempWeekStart.isAtSameMomentAs(currentWeekStart)) {
      final start = tempWeekStart;
      final end = start.add(const Duration(days: 6));
      allPossibleWeeks.add(WeekPeriod(relativeWeekNumber: weekCounter, startDate: start, endDate: end));
      debugPrint('DEBUG: _generateWeeks: Added Week $weekCounter (Start: $start, End: $end). tempWeekStart before increment: $tempWeekStart');
      tempWeekStart = tempWeekStart.add(const Duration(days: 7));
      weekCounter++;
      debugPrint('DEBUG: _generateWeeks: tempWeekStart after increment: $tempWeekStart');
    }

    // The previous loop condition might miss the *exact* current week if creationWeekStart was already currentWeekStart.
    // This check ensures the current week is always included if it's not already.
    // No need for the additional check if (tempWeekStart.isAtSameMomentAs(currentWeekStart) && !allPossibleWeeks.any((w) => w.startDate.isAtSameMomentAs(currentWeekStart)))
    // as the while loop condition should cover it now.
    debugPrint('DEBUG: _generateWeeks: Loop finished. allPossibleWeeks count: ${allPossibleWeeks.length}');

    // Sort weeks from newest to oldest
    allPossibleWeeks.sort((a, b) => b.startDate.compareTo(a.startDate));

    // Take the last 8 weeks (or fewer if the user account is less than 8 weeks old)
    return allPossibleWeeks.take(8).toList();
  }

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
    // Get FirestoreService and user/household IDs
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userId = firestoreService.userId;
    final householdId = firestoreService.selectedHouseholdId;

    if (userId == null || householdId == null) {
      // Handle case where user or household is not selected/logged in
      debugPrint("ERROR: User not logged in or household not selected. Cannot save report.");
      return;
    }

    // Ensure the chart is on-screen for capture
    final trendPng = await _capturePng(_trendKey);
    final consumptionTrendPng = await _capturePng(_consumptionTrendKey);

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
    final totalWasteCost = wastedThisRange.fold<double>(0, (sum, i) => sum + ((i.priceAtAction ?? 0) * (i.quantity)));

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

    final householdDoc = await firestoreService.db.collection("households").doc(householdId).get();
    final householdName = (householdDoc.data()?["name"] as String?) ?? 'Household';

    final stats = WasteWeeklyStats(
      householdName: householdName,
      weekStart: rangeStart,
      weekEnd: rangeEnd,
      generatedAt: DateTime.now(),
      relativeWeekNumber: selectedWeek?.relativeWeekNumber ?? 1, // Pass the relative week number
      totalWastedItems: totalWastedItems,
      totalItemsOut: totalItemsOut,
      totalWasteCost: totalWasteCost,
      totalWasteWeightKg: totalWasteKg,
      categoryRows: categoryRows,
      itemWasteRows: itemRows,
      behavioralInsights: insights,
      baseRecommendations: suggestions,
      weeklyTrendPng: trendPng,
      costByCategoryPng: consumptionTrendPng,
    );

    await initializeDateFormatting('en_PH');

    // Build the PDF
    final pdfBytes = await WasteReportService().buildWeeklyPdf(stats);

    // Calculate most wasted category for the report
    final Map<String, int> wastedByCategory = {};
    for (final i in wastedThisRange) {
      final cat = i.category ?? 'Uncategorized';
      wastedByCategory[cat] = (wastedByCategory[cat] ?? 0) + (i.quantity);
    }
    final mostWastedCategoryForReport = wastedByCategory.entries.isEmpty
        ? '—'
        : wastedByCategory.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    // Save report to Firebase
    final reportId = _uuid.v4();
    final wasteReport = WasteReportModel(
      id: reportId,
      userId: userId,
      householdId: householdId,
      weekStart: rangeStart,
      weekEnd: rangeEnd,
      generatedAt: DateTime.now(),
      totalWastedItems: totalWastedItems,
      totalWasteCost: totalWasteCost,
      mostWastedCategory: mostWastedCategoryForReport,
      pdfStoragePath: '', // Will be updated by saveWasteReport
    );
    await firestoreService.saveWasteReport(wasteReport, pdfBytes);
    debugPrint('📁 Waste report saved to Firebase.');

    // Share PDF (existing functionality)
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename:
          'ShelfControl_Waste_${DateFormat('yyyyMMdd').format(rangeEnd)}.pdf',
    );

    // Save PDF locally (existing functionality)
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
    debugPrint('DEBUG: _WasteTrackerPageState initState called.');
    _fetchUserCreationDateAndGenerateWeeks(); // Call this to fetch user creation date and generate weeks
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
                    StatefulBuilder(
                      builder: (BuildContext context, StateSetter dropDownState) {
                        return DropdownButton<WeekPeriod>(
                          value: _startWeekForCustomRange,
                          items: weeks.map((w) {
                            return DropdownMenuItem(value: w, child: Text(w.label));
                          }).toList(),
                          onChanged: (value) {
                            dropDownState(() {
                              _startWeekForCustomRange = value;
                            });
                          },
                        );
                      },
                    ),
                    StatefulBuilder(
                      builder: (BuildContext context, StateSetter dropDownState) {
                        return DropdownButton<WeekPeriod>(
                          value: _endWeekForCustomRange,
                          items: weeks.map((w) {
                            return DropdownMenuItem(value: w, child: Text(w.label));
                          }).toList(),
                          onChanged: (value) {
                            dropDownState(() {
                              _endWeekForCustomRange = value;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        // Minimal: export full span from first to last week in the dropdowns
                        final start = DateTime(
                            _startWeekForCustomRange!.startDate.year,
                            _startWeekForCustomRange!.startDate.month,
                            _startWeekForCustomRange!.startDate.day);
                        final end = DateTime(
                            _endWeekForCustomRange!.endDate.year,
                            _endWeekForCustomRange!.endDate.month,
                            _endWeekForCustomRange!.endDate.day,
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

        // If selectedWeek is null, data is still loading, show a progress indicator
        if (selectedWeek == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Compute all waste data once
        final wasteData = _WasteData.fromHistoryItems(allHistoryItems, selectedWeek!, weeks);
        
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
        List<int> weeklyWasteSeries = wasteData.weeklyWasteSeries;
        List<int> weeklyConsumedSeries = wasteData.weeklyConsumedSeries;

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
                            fontSize: 20, // Reduced font size to prevent overflow
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
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              height: 40,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ViewReportsPage(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueGrey[600],
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
                                child: const Text("View Reports"),
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
                        const Text(
                          "Weekly Waste Trend",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 12),
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
                                  maxY: (weeklyWasteSeries.isEmpty
                                          ? 5
                                          : (weeklyWasteSeries.reduce(
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
                                          if (index >= 0 && index < weeks.length) {
                                            return Text("W${weeks[index].relativeWeekNumber}",
                                                style: const TextStyle(
                                                    fontSize: 10));
                                          }
                                          return const SizedBox.shrink();
                                        },
                                      ),
                                    ),
                                  ),
                                  barGroups: List.generate(
                                    weeklyWasteSeries.length,
                                    (index) {
                                      final y = (index >= 0 && index < weeklyWasteSeries.length)
                                          ? weeklyWasteSeries[index].toDouble()
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "($qty) ${item.productName}  ${priceEach > 0 ? "₱${priceEach.toStringAsFixed(2)} each" : ""}",
                                            style: const TextStyle(fontSize: 14),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      item.category ?? "Uncategorized",
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.black54),
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
                                      "${thisWeekRate.toStringAsFixed(1)}%"),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Last week's consumption:"),
                                  Text(
                                      "${lastWeekRate.toStringAsFixed(1)}%"),
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "($qty) ${item.productName}  ${priceEach > 0 ? "₱${priceEach.toStringAsFixed(2)} each" : ""}",
                                            style: const TextStyle(fontSize: 14),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      item.category ?? "Uncategorized",
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),

                        const SizedBox(height: 24),
                        const Text(
                          "Weekly Consumption Trend",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 12),
                        RepaintBoundary(
                          key: _consumptionTrendKey,
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
                                  maxY: (weeklyConsumedSeries.isEmpty
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
                                          if (index >= 0 && index < weeks.length) {
                                            return Text("W${weeks[index].relativeWeekNumber}",
                                                style: const TextStyle(
                                                    fontSize: 10));
                                          }
                                          return const SizedBox.shrink();
                                        },
                                      ),
                                    ),
                                  ),
                                  barGroups: List.generate(
                                    weeklyConsumedSeries.length,
                                    (index) {
                                      final y = (index >= 0 && index < weeklyConsumedSeries.length)
                                          ? weeklyConsumedSeries[index].toDouble()
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
