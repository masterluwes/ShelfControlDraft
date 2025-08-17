import 'package:flutter/material.dart';

class Pantryinventory extends StatefulWidget {
  const Pantryinventory({super.key});

  @override
  State<Pantryinventory> createState() => _PantryInventoryBodyState();
}

class _PantryInventoryBodyState extends State<Pantryinventory> {
  final Color headerGreen = const Color(0xFF2E7D32);
  final Color softCream = const Color(0xFFFFFBE6);

  String sortBy = 'Category';
  String filterBy = 'All Items';

  final items = <PantryItem>[
    PantryItem(
      name: 'Orange Juice (1L)',
      category: 'Beverages',
      qty: 1,
      status: ItemStatus.atRisk,
      expiresText: 'in 3 days',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/0/0b/Orange_juice_1.jpg',
    ),
    PantryItem(
      name: 'Ketchup (397g)',
      category: 'Condiments',
      qty: 1,
      status: ItemStatus.active,
      expiresOn: '06/30/25',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/7/79/Ketchup.jpg',
    ),
    PantryItem(
      name: 'Onion Powder (50g)',
      category: 'Herbs/Spices',
      qty: 1,
      status: ItemStatus.active,
      expiresOn: '07/03/25',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/6/6a/Onion_powder.jpg',
    ),
    PantryItem(
      name: 'Soy Sauce (300ml)',
      category: 'Condiments',
      qty: 1,
      status: ItemStatus.active,
      expiresOn: '07/15/25',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/3/3c/Soy_sauce.jpg',
    ),
    PantryItem(
      name: 'Sardines',
      category: 'Canned Goods',
      qty: 2,
      status: ItemStatus.available,
      expiresOn: '09/19/25',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/b/b6/Canned_Sardines.jpg',
    ),
    PantryItem(
      name: 'Coca Cola (500ml)',
      category: 'Beverages',
      qty: 1,
      status: ItemStatus.available,
      expiresOn: '12/19/26',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/5/5a/Coca_Cola_bottle_%282012%29.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: softCream,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Pantry Inventory',
              style: TextStyle(
                color: headerGreen,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                fontFamily: 'Inter',
                height: 1.0,
              ),
            ),
          ),

          // Actions row: Sort / Filter pills + search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _PillMenu<String>(
                  label: 'Sort by: $sortBy',
                  color: headerGreen,
                  items: const ['Category', 'Name', 'Expiry', 'Quantity'],
                  onSelected: (v) => setState(() => sortBy = v),
                ),
                const SizedBox(width: 8),
                _PillMenu<String>(
                  label: 'Filter: $filterBy',
                  color: headerGreen,
                  items: const ['All Items', 'At risk', 'Active', 'Available'],
                  onSelected: (v) => setState(() => filterBy = v),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.search, color: headerGreen),
                  tooltip: 'Search',
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1),

          // List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final it = items[index];
                return Material(
                  color: Colors.white,
                  child: InkWell(
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Checkbox
                          SizedBox(
                            width: 36,
                            child: Checkbox(
                              value: it.checked,
                              onChanged: (v) =>
                                  setState(() => it.checked = v ?? false),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),

                          // Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              it.imageUrl,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 44,
                                height: 44,
                                color: const Color(0xFFEFEFEF),
                                child: const Icon(Icons.inventory_2_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Middle text block
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Name
                                Text(
                                  it.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF222222),
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                // Category + Qty
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        it.category,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: Color(0xFF777777),
                                          height: 1.0,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Qty: ${it.qty}',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: Color(0xFF777777),
                                        height: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Right status + expiry
                          SizedBox(
                            width: 138,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _StatusBadge(status: it.status),
                                const SizedBox(height: 6),
                                Text(
                                  it.expiresText != null
                                      ? 'Expires ${it.expiresText!}'
                                      : 'Expires in: ${it.expiresOn!}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/* ---------- Models & Small Widgets ---------- */

enum ItemStatus { atRisk, active, available }

class PantryItem {
  PantryItem({
    required this.name,
    required this.category,
    required this.qty,
    required this.status,
    this.expiresOn,
    this.expiresText,
    required this.imageUrl,
    this.checked = false,
  });

  String name;
  String category;
  int qty;
  ItemStatus status;
  String? expiresOn; // e.g., '06/30/25'
  String? expiresText; // e.g., 'in 3 days'
  String imageUrl;
  bool checked;
}

class _StatusBadge extends StatelessWidget {
  final ItemStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final String text;
    late final Color fg;

    switch (status) {
      case ItemStatus.atRisk:
        bg = const Color(0xFFF9C27B); // orange-ish
        fg = const Color(0xFF6A3C00);
        text = 'At risk';
        break;
      case ItemStatus.active:
        bg = const Color(0xFFF3E39A); // yellow-ish
        fg = const Color(0xFF6B5E00);
        text = 'Active';
        break;
      case ItemStatus.available:
        bg = const Color(0xFF67A66B);
        fg = Colors.white;
        text = 'Available';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _PillMenu<T> extends StatelessWidget {
  final String label;
  final Color color;
  final List<String> items;
  final ValueChanged<String> onSelected;

  const _PillMenu({
    required this.label,
    required this.color,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        onSelected: onSelected,
        itemBuilder: (context) {
          return items
              .map((e) => PopupMenuItem<String>(value: e, child: Text(e)))
              .toList();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.keyboard_arrow_down, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
