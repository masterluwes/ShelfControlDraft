import 'package:flutter/foundation.dart';

/// Plain item model both pages can understand.
class CSLItem {
  String id;
  String name;
  String? brand;
  String? sizeText; // e.g., 1L, 150g
  String category;
  int qty;
  bool bookmarked;
  bool inCart;

  CSLItem({
    required this.id,
    required this.name,
    required this.category,
    this.brand,
    this.sizeText,
    this.qty = 1,
    this.bookmarked = false,
    this.inCart = false,
  });

  CSLItem copy() => CSLItem(
    id: id,
    name: name,
    brand: brand,
    sizeText: sizeText,
    category: category,
    qty: qty,
    bookmarked: bookmarked,
    inCart: inCart,
  );
}

/// Global “Current Shopping List” store.
/// Call [useList] to swap the active list app-wide.
class CurrentShoppingList extends ChangeNotifier {
  static final CurrentShoppingList I = CurrentShoppingList._();
  CurrentShoppingList._();

  String title = 'Your List';
  final List<CSLItem> _items = [];
  List<CSLItem> get items => List.unmodifiable(_items);

  void useList({required String title, required List<CSLItem> items}) {
    this.title = title;
    _items
      ..clear()
      ..addAll(items.map((e) => e.copy()));
    notifyListeners();
  }

  // Helpers that Shoppinglist can use:
  void updateItem(int index, CSLItem newValue) {
    if (index < 0 || index >= _items.length) return;
    _items[index] = newValue;
    notifyListeners();
  }

  void insertAt(int index, CSLItem item) {
    _items.insert(index.clamp(0, _items.length), item);
    notifyListeners();
  }

  void removeAt(int index) {
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
