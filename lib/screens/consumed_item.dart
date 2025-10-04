class ConsumedItem {
  final String name;
  final int quantity;
  final String category;

  ConsumedItem({
    required this.name,
    required this.quantity,
    required this.category,
  });

  factory ConsumedItem.fromJson(Map<String, dynamic> json) {
    return ConsumedItem(
      name: json['name'],
      quantity: json['quantity'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() => {
    "name": name,
    "quantity": quantity,
    "category": category,
  };
}
