class WastedItem {
  final String name;
  final String status;
  final int quantity;
  final String category;
  final double price;

  WastedItem({
    required this.name,
    required this.status,
    required this.quantity,
    required this.category,
    required this.price,
  });

  factory WastedItem.fromJson(Map<String, dynamic> json) {
    return WastedItem(
      name: json['name'],
      status: json['status'],
      quantity: json['quantity'],
      category: json['category'],
      price: json['price'],
    );
  }

  Map<String, dynamic> toJson() => {
    "name": name,
    "status": status,
    "quantity": quantity,
    "category": category,
    "price": price,
  };

  double get totalCost => price * quantity;
}
