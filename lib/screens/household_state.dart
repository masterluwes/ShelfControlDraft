import 'package:flutter/foundation.dart';

class HouseholdState extends ChangeNotifier {
  static final HouseholdState _instance = HouseholdState._internal();
  factory HouseholdState() => _instance;
  HouseholdState._internal();

  String selectedPantry = "Personal Pantry";
  final List<Map<String, dynamic>> _households = [];

  List<Map<String, dynamic>> get households => _households;

  void selectPantry(String pantry) {
    selectedPantry = pantry;
    notifyListeners();
  }

  void addHousehold(Map<String, dynamic> household) {
    _households.add(household);
    notifyListeners();
  }

  void removeHouseholdByCode(String code) {
    _households.removeWhere((h) => h['code'] == code);
    if (selectedPantry == code) {
      selectedPantry = "Personal Pantry";
    }
    notifyListeners();
  }

  void clear() {
    _households.clear();
    notifyListeners();
  }

  List<String> get allPantries => [
    "Personal Pantry",
    ..._households.map((h) => h['name'] as String),
  ];
}
