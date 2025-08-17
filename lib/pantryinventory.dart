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

  // Search state
  bool isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  final items = <PantryItem>[
    // --- Sample items (you can extend this) ---
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
    PantryItem(
      name: 'Whole Milk (1L)',
      category: 'Dairy',
      qty: 2,
      status: ItemStatus.atRisk,
      expiresText: 'in 2 days',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/a/a4/Glass_milk.jpg',
    ),
    PantryItem(
      name: 'Pasta Penne (500g)',
      category: 'Grains',
      qty: 3,
      status: ItemStatus.available,
      expiresOn: '11/02/26',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/7/73/Penne_pasta.jpg',
    ),
  ];

  // ---------- Helpers: filtering & sorting ----------
  DateTime? _parseExpiry(PantryItem it) {
    if (it.expiresOn != null && it.expiresOn!.trim().isNotEmpty) {
      final parts = it.expiresOn!.split('/');
      if (parts.length == 3) {
        final mm = int.tryParse(parts[0]);
        final dd = int.tryParse(parts[1]);
        final yy = int.tryParse(parts[2]);
        if (mm != null && dd != null && yy != null) {
          final year = yy >= 80 ? (1900 + yy) : (2000 + yy);
          return DateTime(year, mm, dd);
        }
      }
    }
    if (it.expiresText != null && it.expiresText!.trim().isNotEmpty) {
      final reg = RegExp(r'in\s+(\d+)\s+day');
      final m = reg.firstMatch(it.expiresText!.toLowerCase());
      if (m != null) {
        final d = int.tryParse(m.group(1)!);
        if (d != null) return DateTime.now().add(Duration(days: d));
      }
    }
    return null;
  }

  int _cmpString(String a, String b) =>
      a.toLowerCase().compareTo(b.toLowerCase());

  List<PantryItem> _visibleItems() {
    // 1) Status filter
    final filteredByStatus = items.where((it) {
      switch (filterBy) {
        case 'At risk':
          return it.status == ItemStatus.atRisk;
        case 'Active':
          return it.status == ItemStatus.active;
        case 'Available':
          return it.status == ItemStatus.available;
        default:
          return true;
      }
    });

    // 2) Search query (name OR category)
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? filteredByStatus.toList()
        : filteredByStatus
              .where(
                (it) =>
                    it.name.toLowerCase().contains(q) ||
                    it.category.toLowerCase().contains(q),
              )
              .toList();

    // 3) Sort
    switch (sortBy) {
      case 'Name':
        filtered.sort((a, b) => _cmpString(a.name, b.name));
        break;
      case 'Category':
        filtered.sort((a, b) {
          final c = _cmpString(a.category, b.category);
          return c != 0 ? c : _cmpString(a.name, b.name);
        });
        break;
      case 'Quantity':
        filtered.sort((a, b) {
          final c = a.qty.compareTo(b.qty);
          return c != 0 ? c : _cmpString(a.name, b.name);
        });
        break;
      case 'Expiry':
        filtered.sort((a, b) {
          final ea = _parseExpiry(a);
          final eb = _parseExpiry(b);
          if (ea == null && eb == null) return _cmpString(a.name, b.name);
          if (ea == null) return 1;
          if (eb == null) return -1;
          final c = ea.compareTo(eb);
          return c != 0 ? c : _cmpString(a.name, b.name);
        });
        break;
    }
    return filtered;
  }

  void _startSearch() {
    setState(() {
      isSearching = true;
      // Any open popup will close naturally once we rebuild/swipe focus.
      // We also focus the textfield automatically via `autofocus`.
    });
  }

  void _cancelSearch() {
    setState(() {
      isSearching = false;
      _query = '';
      _searchCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = _visibleItems();

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

          // Actions row: Pills <-> Search swap
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // Left side switches between dropdown pills and the search field
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: isSearching
                        ? _SearchField(
                            key: const ValueKey('search-field'),
                            controller: _searchCtrl,
                            color: headerGreen,
                            onChanged: (v) => setState(() => _query = v ?? ''),
                            onClear: () {
                              setState(() {
                                _query = '';
                                _searchCtrl.clear();
                              });
                            },
                          )
                        : Row(
                            key: const ValueKey('pills'),
                            children: [
                              _PillMenu<String>(
                                label: 'Sort by: $sortBy',
                                color: headerGreen,
                                items: const [
                                  'Category',
                                  'Name',
                                  'Expiry',
                                  'Quantity',
                                ],
                                onSelected: (v) => setState(() => sortBy = v),
                              ),
                              const SizedBox(width: 8),
                              _PillMenu<String>(
                                label: 'Filter: $filterBy',
                                color: headerGreen,
                                items: const [
                                  'All Items',
                                  'At risk',
                                  'Active',
                                  'Available',
                                ],
                                onSelected: (v) => setState(() => filterBy = v),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(width: 8),

                // Right side button: Search or Cancel
                isSearching
                    ? TextButton(
                        onPressed: _cancelSearch,
                        child: const Text('Cancel'),
                      )
                    : IconButton(
                        onPressed: _startSearch,
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
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final it = list[index];
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
                              errorBuilder: (_, __, ___) => Container(
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
                                      : (it.expiresOn != null
                                            ? 'Expires in: ${it.expiresOn!}'
                                            : 'No expiry'),
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

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final Color color;
  final ValueChanged<String?> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    super.key,
    required this.controller,
    required this.color,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color, width: 1.2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              onChanged: onChanged,
              decoration: const InputDecoration(
                hintText: 'Search items or categories…',
                border: InputBorder.none,
                isCollapsed: true,
              ),
              textInputAction: TextInputAction.search,
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              tooltip: 'Clear',
              onPressed: onClear,
              icon: const Icon(Icons.close),
              splashRadius: 18,
            ),
        ],
      ),
    );
  }
}
