class WastedItem {
  final String name;
  final String status;
  final int quantity;
  final String category;

  WastedItem({
    required this.name,
    required this.status,
    required this.quantity,
    required this.category,
  });

  factory WastedItem.fromJson(Map<String, dynamic> json) {
    return WastedItem(
      name: json['name'],
      status: json['status'],
      quantity: json['quantity'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() => {
    "name": name,
    "status": status,
    "quantity": quantity,
    "category": category,
  };
}
