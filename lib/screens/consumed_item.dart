class ConsumedItem {
  final String name;
  final int quantity;
  final String category;
  final double price;

  ConsumedItem({
    required this.name,
    required this.quantity,
    required this.category,
    required this.price,
  });

  factory ConsumedItem.fromJson(Map<String, dynamic> json) {
    return ConsumedItem(
      name: json['name'],
      quantity: json['quantity'],
      category: json['category'],
      price: json['price'],
    );
  }

  Map<String, dynamic> toJson() => {
    "name": name,
    "quantity": quantity,
    "category": category,
    "price": price,
  };
}
