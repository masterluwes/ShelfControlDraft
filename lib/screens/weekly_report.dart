import 'wasted_item.dart';
import 'consumed_item.dart';

class WeeklyReport {
  final int weekNumber;
  final DateTime startDate;
  final DateTime endDate;
  final List<WastedItem> wastedItems;
  final List<ConsumedItem> consumedItems;
  final int pantryTotal;

  WeeklyReport({
    required this.weekNumber,
    required this.startDate,
    required this.endDate,
    required this.wastedItems,
    required this.consumedItems,
    required this.pantryTotal,
  });

  factory WeeklyReport.fromJson(Map<String, dynamic> json) {
    return WeeklyReport(
      weekNumber: json['weekNumber'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      wastedItems: (json['wastedItems'] as List)
          .map((e) => WastedItem.fromJson(e))
          .toList(),
      consumedItems: (json['consumedItems'] as List)
          .map((e) => ConsumedItem.fromJson(e))
          .toList(),
      pantryTotal: json['pantryTotal'],
    );
  }

  Map<String, dynamic> toJson() => {
    "weekNumber": weekNumber,
    "startDate": startDate.toIso8601String(),
    "endDate": endDate.toIso8601String(),
    "wastedItems": wastedItems.map((e) => e.toJson()).toList(),
    "consumedItems": consumedItems.map((e) => e.toJson()).toList(),
    "pantryTotal": pantryTotal,
  };

  // Mock dataaaaaa
  factory WeeklyReport.mockThisWeek() {
    return WeeklyReport(
      weekNumber: 2,
      startDate: DateTime.now().subtract(const Duration(days: 6)),
      endDate: DateTime.now(),
      wastedItems: [
        WastedItem(
          name: "Sardines",
          quantity: 3,
          status: "Expired",
          category: "Canned Goods",
          price: 27,
        ),
        WastedItem(
          name: "Tomato",
          quantity: 2,
          status: "Spoiled",
          category: "Vegetable",
          price: 10,
        ),
      ],
      consumedItems: [
        ConsumedItem(name: "Bread", quantity: 3, category: "Grain", price: 54),
        ConsumedItem(
          name: "Chicken",
          quantity: 2,
          category: "Meat",
          price: 100,
        ),
      ],
      pantryTotal: 10,
    );
  }

  factory WeeklyReport.mockLastWeek() {
    return WeeklyReport(
      weekNumber: 1,
      startDate: DateTime.now().subtract(const Duration(days: 13)),
      endDate: DateTime.now().subtract(const Duration(days: 7)),
      wastedItems: [
        WastedItem(
          name: "Apple",
          quantity: 1,
          status: "Spoiled",
          category: "Fruit",
          price: 43,
        ),
      ],
      consumedItems: [
        ConsumedItem(name: "Milk", quantity: 2, category: "Dairy", price: 60),
      ],
      pantryTotal: 8,
    );
  }
}
