// lib/services/report_service.dart
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;

class WasteWeeklyStats {
  final String householdName;
  final DateTime weekStart; // e.g., 2025-10-06
  final DateTime weekEnd; // e.g., 2025-10-12 (inclusive)
  final DateTime generatedAt; // now()

  final int totalWastedItems; // e.g., 12
  final int totalItemsOut; // wasted + consumed that left pantry
  final double totalWasteCost; // e.g., 256.0
  final double totalWasteWeightKg; // e.g., 4.2
  final Map<String, CategoryRow> categoryRows; // by category key
  final List<ItemWasteRow> itemWasteRows; // detailed items
  final List<String> behavioralInsights; // bullet points
  final List<String> baseRecommendations; // bullet points (precomputed)

  // Optional chart images (PNG bytes)
  final Uint8List? weeklyTrendPng; // consumed vs wasted line/bar
  final Uint8List? costByCategoryPng; // pie or bar by category

  WasteWeeklyStats({
    required this.householdName,
    required this.weekStart,
    required this.weekEnd,
    required this.generatedAt,
    required this.totalWastedItems,
    required this.totalItemsOut,
    required this.totalWasteCost,
    required this.totalWasteWeightKg,
    required this.categoryRows,
    required this.itemWasteRows,
    required this.behavioralInsights,
    required this.baseRecommendations,
    this.weeklyTrendPng,
    this.costByCategoryPng,
  });

  double get wastePercent =>
      totalItemsOut == 0 ? 0 : (totalWastedItems / totalItemsOut) * 100.0;
  double get efficiencyRate => totalItemsOut == 0
      ? 0
      : ((totalItemsOut - totalWastedItems) / totalItemsOut) * 100.0;
}

class CategoryRow {
  final String category; // e.g., Dairy
  final int itemsWasted; // e.g., 3
  final double totalCost; // e.g., 60
  final double? sharePercent; // computed upstream or here
  CategoryRow({
    required this.category,
    required this.itemsWasted,
    required this.totalCost,
    this.sharePercent,
  });
}

class ItemWasteRow {
  final String category;
  final String itemName; // e.g., Milk
  final int quantity; // e.g., 3
  final double? cost; // optional per-item or total
  final DateTime? expiryDate; // optional
  final DateTime? wastedAt; // for analytics
  ItemWasteRow({
    required this.category,
    required this.itemName,
    required this.quantity,
    this.cost,
    this.expiryDate,
    this.wastedAt,
  });
}

class WasteReportService {
  final _date = DateFormat('MMM d, yyyy'); // no locale param
  final _dateTime = DateFormat('MMM d, yyyy h:mm a'); // no locale param
  final _money = NumberFormat.currency(name: 'PHP', symbol: '₱');

  // --- Compact KPI row (4–5 small tiles on one line/wrap) ---
  pw.Widget _kpiRowCompact(WasteWeeklyStats s) {
    final tiles = <pw.Widget>[
      _kpiCardCompact('Wasted', '${s.totalWastedItems}'),
      _kpiCardCompact('Waste %', '${s.wastePercent.toStringAsFixed(1)}%'),
      _kpiCardCompact('Waste Cost', _money.format(s.totalWasteCost)),
      _kpiCardCompact('Efficiency', '${s.efficiencyRate.toStringAsFixed(1)}%'),
    ];

    // Show weight only if non-zero
    if (s.totalWasteWeightKg > 0) {
      tiles.insert(3,
          _kpiCardCompact('Waste Kg', s.totalWasteWeightKg.toStringAsFixed(2)));
    }

    return pw.Wrap(spacing: 6, runSpacing: 6, children: tiles);
  }

// --- Single compact KPI tile ---
  pw.Widget _kpiCardCompact(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
          pw.SizedBox(height: 2),
          pw.Text(value,
              style:
                  pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

// --- Compact bullets (kept short for 1–2 pages max) ---
  pw.Widget _bulletsCompact(List<String> lines, {double fontSize = 10}) {
    if (lines.isEmpty) {
      return pw.Text('No data available for this section.',
          style: pw.TextStyle(fontSize: fontSize));
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: lines.map((t) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 3),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('• ', style: pw.TextStyle(fontSize: fontSize)),
              pw.Expanded(
                  child: pw.Text(t, style: pw.TextStyle(fontSize: fontSize))),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<Uint8List> buildWeeklyPdf(WasteWeeklyStats stats) async {
    // 1) Load fonts from assets
    pw.Font fontRegular;
    pw.Font fontBold;

    try {
      fontRegular = pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSans.ttf'),
      );
      fontBold = pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSans.ttf'),
      );
    } catch (e, st) {
      // This is the most common runtime error — wrong path or pubspec not updated.
      // Log clearly and fall back to the default font so you can still generate a PDF.
      // (Default Helvetica won’t render ₱ / bullets perfectly, but avoids a crash.)
      // You can also rethrow to fail hard if you prefer.
      // ignore: avoid_print
      print('[WasteReportService] Font load failed: $e\n$st');
      // Fallback: use the built-in font so the app does not crash
      fontRegular = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    // 2) Apply fonts to the whole document via theme
    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
      italic: fontRegular,
      boldItalic: fontBold,
    );

    // 3) Create the document with the theme (so we’re NOT using Helvetica)
    final doc = pw.Document(theme: theme);

    // ---------- Cover ----------
    // ===== SINGLE, LINEAR PAGE (header → summary → categories → insights → recommendations) =====
    doc.addPage(
      pw.Page(
        pageTheme: _pageTheme(theme), // keep your existing _pageTheme() signature
        build: (ctx) {
          // --- local helpers (scoped to this build) to keep code minimal ---
          pw.Widget spacer(double h) => pw.SizedBox(height: h);

          // Weekly Summary table rows (weight row only if > 0)
          final summaryRows = <List<String>>[
            [
              'Total Wasted Items',
              '${stats.totalWastedItems}',
              'Items marked as wasted in this period'
            ],
            [
              'Waste Percentage',
              '${stats.wastePercent.toStringAsFixed(1)}%',
              'Relative to all items leaving pantry'
            ],
            [
              'Total Cost of Waste',
              _money.format(stats.totalWasteCost),
              'Estimated financial loss'
            ],
          ];
          if (stats.totalWasteWeightKg > 0) {
            summaryRows.add([
              'Total Generated Waste',
              '${stats.totalWasteWeightKg.toStringAsFixed(2)} kg',
              'Estimated discarded weight'
            ]);
          }
          summaryRows.add([
            'Efficiency Rate',
            '${stats.efficiencyRate.toStringAsFixed(1)}%',
            'Consumed vs wasted ratio'
          ]);

          // Category Breakdown rows (sorted by highest cost). Keep it short to fit one page.
          final catValues = stats.categoryRows.values.toList()
            ..sort((a, b) => b.totalCost.compareTo(a.totalCost));
          final topCats = catValues.take(6).toList(); // trim to 6 rows max

          // Per-category “top item” (by cost then qty), if we have item rows
          String topItemFor(String cat) {
            final items =
                stats.itemWasteRows.where((r) => r.category == cat).toList();
            if (items.isEmpty) return '-';
            items.sort((a, b) => (b.cost ?? 0).compareTo(a.cost ?? 0));
            return items.first.itemName;
          }

          final categoryRows = topCats
              .map((r) => <String>[
                    r.category,
                    topItemFor(r.category),
                    r.itemsWasted.toString(),
                    _money.format(r.totalCost),
                  ])
              .toList();

          // Bullet list builder (no new class helpers)
          pw.Widget bullets(List<String> lines, {double fontSize = 10}) {
            if (lines.isEmpty) {
              return pw.Text('No data available for this section.',
                  style: pw.TextStyle(fontSize: fontSize));
            }
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: lines.map((t) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 3),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('• ', style: pw.TextStyle(fontSize: fontSize)),
                      pw.Expanded(
                          child: pw.Text(t,
                              style: pw.TextStyle(fontSize: fontSize))),
                    ],
                  ),
                );
              }).toList(),
            );
          }

          // Keep insights/recommendations short to ensure single page
          final compactInsights = stats.behavioralInsights.take(3).toList();
          final compactRecs =
              _computeActionableRecommendations(stats).take(4).toList();

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _header(title: 'SHELFCONTROL WASTE TRACKER REPORT'),
              spacer(8),
              pw.Text('Household: ${stats.householdName}',
                  style: const pw.TextStyle(fontSize: 12)),
              pw.Text(
                  'Week: ${_date.format(stats.weekStart)} – ${_date.format(stats.weekEnd)}',
                  style: const pw.TextStyle(fontSize: 12)),
              pw.Text('Generated: ${_dateTime.format(stats.generatedAt)}',
                  style:
                      pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),

              // Weekly Summary
              spacer(12),
              pw.Text('Weekly Summary',
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold)),
              spacer(6),
              pw.Table.fromTextArray(
                headers: const ['Metric', 'Value', 'Description'],
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.blue),
                cellStyle: const pw.TextStyle(fontSize: 10),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.6),
                  1: const pw.FlexColumnWidth(1.0),
                  2: const pw.FlexColumnWidth(2.2),
                },
                data: summaryRows,
              ),

              // Category Breakdown (trimmed)
              spacer(12),
              pw.Text('Category Breakdown',
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold)),
              spacer(6),
              pw.Table.fromTextArray(
                headers: const [
                  'Category',
                  'Specific Item',
                  'Items Wasted',
                  'Total Cost (₱)'
                ],
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.indigo),
                cellStyle: const pw.TextStyle(fontSize: 10),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.5),
                  1: const pw.FlexColumnWidth(2.0),
                  2: const pw.FlexColumnWidth(1.0),
                  3: const pw.FlexColumnWidth(1.2),
                },
                data: categoryRows,
              ),

              // Behavioral Insights
              spacer(12),
              pw.Text('Behavioral Insights',
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold)),
              spacer(4),
              bullets(compactInsights, fontSize: 10),

              // Recommendations
              spacer(8),
              pw.Text('Recommendations (Next Week)',
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold)),
              spacer(4),
              bullets(compactRecs, fontSize: 10),

              // (Optional) If you want a tiny note at the bottom:
              // spacer(8),
              // pw.Text('Tip: Re-check expiry dates every weekend and move “at-risk” items to the front.',
              //   style: pw.TextStyle(fontSize: 9, color: pw.PdfColors.grey700)),
            ],
          );
        },
      ),
    );

// -------- PAGE 2: Condensed tables (only if data exists) --------
    final hasCategories = stats.categoryRows.isNotEmpty;
    final hasItems = stats.itemWasteRows.isNotEmpty;

    if (hasCategories || hasItems) {
      doc.addPage(
        pw.Page(
          pageTheme: _pageTheme(theme),
          build: (ctx) {
            final content = <pw.Widget>[];

            if (hasCategories) {
              final rows = stats.categoryRows.values.toList()
                ..sort((a, b) => b.totalCost.compareTo(a.totalCost));
              content.addAll([
                _header(title: 'Category Breakdown'),
                pw.SizedBox(height: 8),
                pw.Table.fromTextArray(
                  headers: const ['Category', 'Qty', 'Cost', 'Share'],
                  headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration:
                      const pw.BoxDecoration(color: PdfColors.blue),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2.0),
                    1: const pw.FlexColumnWidth(0.9),
                    2: const pw.FlexColumnWidth(1.3),
                    3: const pw.FlexColumnWidth(0.9),
                  },
                  data: rows
                      .map((r) => [
                            r.category,
                            r.itemsWasted.toString(),
                            _money.format(r.totalCost),
                            r.sharePercent == null
                                ? '-'
                                : '${r.sharePercent!.toStringAsFixed(1)}%',
                          ])
                      .toList(),
                ),
              ]);
              content.add(pw.SizedBox(height: 10));
            }

            if (hasItems) {
              final items = stats.itemWasteRows.toList()
                ..sort((a, b) => (b.cost ?? 0).compareTo(a.cost ?? 0));
              final top = items.take(6).toList(); // limit to top 6

              content.addAll([
                pw.Text('Top Items Wasted',
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Table.fromTextArray(
                  headers: const ['Category', 'Item', 'Qty', 'Cost'],
                  headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration:
                      const pw.BoxDecoration(color: PdfColors.indigo),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.3),
                    1: const pw.FlexColumnWidth(2.2),
                    2: const pw.FlexColumnWidth(0.7),
                    3: const pw.FlexColumnWidth(1.2),
                  },
                  data: top
                      .map((r) => [
                            r.category,
                            r.itemName,
                            r.quantity.toString(),
                            r.cost == null ? '-' : _money.format(r.cost),
                          ])
                      .toList(),
                ),
              ]);
            }

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: content,
            );
          },
        ),
      );
    }

    // ---------- Category Table ----------
    doc.addPage(
      pw.Page(
        pageTheme: _pageTheme(theme),
        build: (ctx) {
          final rows = stats.categoryRows.values.toList()
            ..sort((a, b) => b.totalCost.compareTo(a.totalCost));

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _header(title: 'Category Breakdown'),
              pw.SizedBox(height: 12),
              pw.Table.fromTextArray(
                headers: const ['Category', 'Items Wasted', 'Cost', 'Share'],
                data: rows
                    .map((r) => [
                          r.category,
                          r.itemsWasted.toString(),
                          _money.format(r.totalCost),
                          r.sharePercent == null
                              ? '-'
                              : '${r.sharePercent!.toStringAsFixed(1)}%',
                        ])
                    .toList(),
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellAlignment: pw.Alignment.centerLeft,
                columnWidths: {
                  0: const pw.FlexColumnWidth(2.2),
                  1: const pw.FlexColumnWidth(1.2),
                  2: const pw.FlexColumnWidth(1.6),
                  3: const pw.FlexColumnWidth(1.0),
                },
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Top items wasted',
                style:
                    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              _topItemsTable(stats),
            ],
          );
        },
      ),
    );

    // ---------- Insights & Actions ----------
    final actionable = _computeActionableRecommendations(stats);
    doc.addPage(
      pw.Page(
        pageTheme: _pageTheme(theme),
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _header(title: 'Behavioral Insights'),
              pw.SizedBox(height: 8),
              _bullets(stats.behavioralInsights),
              pw.SizedBox(height: 16),
              _header(title: 'Recommendations (Do These Next Week)'),
              pw.SizedBox(height: 8),
              _bullets(actionable),
              pw.SizedBox(height: 16),
              pw.Text(
                'Tip: Re-check expiry dates every weekend and move “at-risk” items to the front. '
                'Use FIFO (First-In, First-Out) for Dairy and Snacks.',
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  // ---------- Helpers ----------

  pw.PageTheme _pageTheme(pw.ThemeData theme) => pw.PageTheme(
        theme: theme,
        margin: const pw.EdgeInsets.all(28),
        textDirection: pw.TextDirection.ltr,
      );

  pw.Widget _header({required String title}) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 6),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
          ),
        ),
        child: pw.Text(
          title,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
      );

  pw.Widget _kpiCard(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue400, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style:
                  const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
          pw.SizedBox(height: 4),
          pw.Text(value,
              style:
                  pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _kpiRow(WasteWeeklyStats s) {
    final tiles = <pw.Widget>[
      _kpiCard('Total Wasted Items', '${s.totalWastedItems}'),
      _kpiCard('Waste % of Outflow', '${s.wastePercent.toStringAsFixed(1)}%'),
      _kpiCard('Total Cost of Waste', _money.format(s.totalWasteCost)),
      _kpiCard('Efficiency Rate', '${s.efficiencyRate.toStringAsFixed(1)}%'),
    ];

    pw.Widget _kpiRowCompact(WasteWeeklyStats s) {
      final tiles = <pw.Widget>[
        // _kpiCardCompact('Wasted', '${s.totalWastedItems}'),
        // _kpiCardCompact('Waste %', '${s.wastePercent.toStringAsFixed(1)}%'),
        // _kpiCardCompact('Waste Cost', _money.format(s.totalWasteCost)),
        // _kpiCardCompact('Efficiency', '${s.efficiencyRate.toStringAsFixed(1)}%'),
      ];
      // if (s.totalWasteWeightKg > 0) {
      //   tiles.insert(3, _kpiCardCompact('Waste Kg', '${s.totalWasteWeightKg.toStringAsFixed(2)}'));
      // }
      return pw.Wrap(spacing: 6, runSpacing: 6, children: tiles);
    }

    pw.Widget _kpiCardCompact(String label, String value) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
            pw.SizedBox(height: 2),
            pw.Text(value,
                style:
                    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );
    }

    pw.Widget _bulletsCompact(List<String> lines, {double fontSize = 10}) {
      if (lines.isEmpty) {
        return pw.Text('No data available for this section.',
            style: pw.TextStyle(fontSize: fontSize));
      }
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: lines.map((t) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('• ', style: pw.TextStyle(fontSize: fontSize)),
                pw.Expanded(
                    child: pw.Text(t, style: pw.TextStyle(fontSize: fontSize))),
              ],
            ),
          );
        }).toList(),
      );
    }

    // Only show weight if we have non-zero data
    if (s.totalWasteWeightKg > 0) {
      tiles.insert(
        3,
        _kpiCard('Total Waste Weight',
            '${s.totalWasteWeightKg.toStringAsFixed(2)} kg'),
      );
    }

    return pw.Wrap(
      spacing: 10,
      runSpacing: 10,
      children: tiles,
    );
  }

  pw.Widget _topItemsTable(WasteWeeklyStats s) {
    final rows = s.itemWasteRows.toList()
      ..sort((a, b) => (b.cost ?? 0).compareTo(a.cost ?? 0));
    final top = rows.take(8).toList();

    return pw.Table.fromTextArray(
      headers: const ['Category', 'Item', 'Qty', 'Cost', 'Expiry'],
      data: top
          .map((r) => [
                r.category,
                r.itemName,
                r.quantity.toString(),
                r.cost == null ? '-' : _money.format(r.cost),
                r.expiryDate == null
                    ? '-'
                    : DateFormat('MMM d', 'en_PH').format(r.expiryDate!),
              ])
          .toList(),
      headerStyle:
          pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo),
      cellStyle: const pw.TextStyle(fontSize: 10),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.3),
        1: const pw.FlexColumnWidth(2.2),
        2: const pw.FlexColumnWidth(0.8),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(1.0),
      },
    );
  }

  pw.Widget _bullets(List<String> lines) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: lines.map((t) {
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('•  ', style: const pw.TextStyle(fontSize: 11)),
              pw.Expanded(
                  child: pw.Text(t, style: const pw.TextStyle(fontSize: 11))),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Builds actionable recommendations out of the raw stats.
  List<String> _computeActionableRecommendations(WasteWeeklyStats s) {
    final List<String> out = [];

    // 1) High waste% → process tweak
    if (s.wastePercent >= 20) {
      out.add('Waste rate is ${s.wastePercent.toStringAsFixed(1)}%. '
          'Do a 10-minute expiry sweep every weekend and move at-risk items to the front.');
    }

    // 2) Category driver
    final topCat = s.categoryRows.values.isEmpty
        ? null
        : s.categoryRows.values
            .reduce((a, b) => a.totalCost >= b.totalCost ? a : b);
    if (topCat != null && topCat.itemsWasted >= 2) {
      out.add(
          'Most waste is in ${topCat.category}. Buy smaller pack sizes next week and adopt FIFO for this category.');
    }

    // 3) SKU repeats
    final Map<String, int> repeats = {};
    for (final r in s.itemWasteRows) {
      repeats[r.itemName] = (repeats[r.itemName] ?? 0) + r.quantity;
    }
    final frequent = repeats.entries.where((e) => e.value >= 3).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (frequent.isNotEmpty) {
      final names = frequent.take(3).map((e) => e.key).join(', ');
      out.add(
          'Repeated waste detected: $names — buy smaller quantities and delay restock until consumed.');
    }

    // 4) Upcoming expiries → cook plan
    final soon = s.itemWasteRows.where((r) => r.expiryDate != null).where((r) {
      final d = r.expiryDate!;
      final now = s.generatedAt;
      final days = d.difference(now).inDays;
      return days >= 0 && days <= 3;
    }).toList();
    if (soon.isNotEmpty) {
      final names = soon.take(5).map((r) => r.itemName).join(', ');
      out.add(
          'Cook soon (expiring ≤3 days): $names. Plan 2 quick meals using these first.');
    }

    // 5) Budget angle
    if (s.totalWasteCost >= 200) {
      out.add(
          'You lost ${_money.format(s.totalWasteCost)} this week due to waste. '
          'Cap snack restocks at 1 pack per week and review on Sundays.');
    }

    // Merge with base suggestions
    out.addAll(s.baseRecommendations);
    return out.toSet().toList(); // de-dupe
  }
}
