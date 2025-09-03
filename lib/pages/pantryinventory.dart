import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:guests_main/pages/editpantryitem.dart';

class Pantryinventory extends StatefulWidget {
  const Pantryinventory({super.key});

  @override
  State<Pantryinventory> createState() => _PantryInventoryBodyState();
}

enum ItemStatus { active, atRisk, available, consumed }

class PantryItem {
  final String id;
  String name;
  String brand;
  String size; // e.g., "1L", "397g", "500ml"
  String category;
  final String imageUrl;
  int qty;
  String expiresText;
  ItemStatus status;
  ItemStatus? prevStatus; // Remember last non-consumed state

  PantryItem({
    required this.id,
    required this.name,
    required this.brand,
    required this.size,
    required this.category,
    required this.imageUrl,
    required this.qty,
    required this.expiresText,
    required this.status,
    this.prevStatus,
  });

  String get subline {
    final b = brand.trim();
    final s = size.trim();
    if (b.isNotEmpty && s.isNotEmpty) return '$b · $s';
    if (b.isNotEmpty) return b;
    if (s.isNotEmpty) return s;
    return '';
  }
}

class _PantryInventoryBodyState extends State<Pantryinventory> {
  // Palette
  final Color headerGreen = const Color(0xFF2E7D32);
  final Color softCream = const Color(0xFFFFFBE6);
  final Color rowColor = const Color.fromARGB(255, 255, 254, 250);
  final Color sep = const Color.fromARGB(255, 230, 230, 230); // divider

  // Keys to anchor floating SnackBars so the UI never shifts
  final GlobalKey _titleKey = GlobalKey();
  final GlobalKey _controlsKey = GlobalKey();

  // Typography
  static const double metaSize = 13;
  static const double pillSize = 13;

  TextStyle get nameStyle => const TextStyle(
    fontFamily: 'Roboto',
    fontSize: 18,
    fontWeight: FontWeight.w900,
    color: Color(0xFF20451F),
  );

  TextStyle get subStyle => const TextStyle(
    fontFamily: 'Roboto',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Color(0xFF6F6F6F),
  );

  TextStyle get metaLabelStyle =>
      const TextStyle(fontSize: metaSize, color: Color(0xFF6F6F6F));

  TextStyle get metaValueStyle =>
      const TextStyle(fontSize: metaSize, fontWeight: FontWeight.w700);

  TextStyle get chipTextStyle => const TextStyle(
    fontSize: pillSize,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  // Spacing knobs
  static const double kTitleTopNudge = 4; // push title down a bit
  static const double kTitleMetaGap = 6; // Title ↔ subline (brand · size)
  static const double kSubMetaGap = 6; // subline ↔ Category/Qty row
  static const double kCatQtyGap = 12; // Category ↔ "Qty:"
  static const double kQtyValueGap = 4; // "Qty:" ↔ value

  // Positioning knobs
  static const double kTileHPad = 12; // whole item: left/right padding
  static const double kTileVPad = 10; // whole item: top/bottom padding
  static const double kCheckboxTextGap = 12; // gap after checkbox
  static const double kCheckboxNudgeTop = 0; // was 4 — align w/ icon center
  static const double kLeftRightGap = 12; // gap between left & right blocks

  // Row alignment (center to align checkbox + chip like Shoppinglist)
  final CrossAxisAlignment rowCrossAxis = CrossAxisAlignment.center;
  final MainAxisAlignment rowMainAxis = MainAxisAlignment.start;

  // Left block alignment
  final CrossAxisAlignment leftColAlign = CrossAxisAlignment.start;
  final TextAlign nameTextAlign = TextAlign.left;

  // Right block alignment
  final CrossAxisAlignment rightColCross = CrossAxisAlignment.end;
  final MainAxisAlignment rightColMain = MainAxisAlignment.start;

  // Dropdown pill styling
  static const Color kPillBg = Color(0xFF2E7D32);
  static const Color kPillTextColor = Color(0xFFFDFDFC);
  static const Color kMenuBg = Color(0xFF2E7D32);

  TextStyle get pillLabelStyle => const TextStyle(
    fontFamily: 'Roboto',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: kPillTextColor,
  );
  TextStyle get pillValueStyle => const TextStyle(
    fontFamily: 'Roboto',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: kPillTextColor,
  );
  TextStyle get menuItemTextStyle => const TextStyle(
    fontFamily: 'Roboto',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Color(0xFFFDFDFC),
  );

  // Status dropdown (PopupMenu) styling
  static const Offset kStatusMenuOffset = Offset(0, 8); // push menu below chip
  static const double kStatusMenuElevation = 8;
  static const ShapeBorder kStatusMenuShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );
  static const BoxConstraints kStatusMenuMinSize = BoxConstraints(
    minWidth: 100,
  );
  static const TextStyle kStatusMenuTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Color(0XFF347928),
  );
  static const DividerThemeData kStatusMenuDividerTheme = DividerThemeData(
    color: Color(0xFFBDBDBD),
    thickness: 1,
    space: 0,
  );

  // Search / Filters
  bool isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  final List<String> _sortOptions = const [
    'Category',
    'Name',
    'Quantity',
    'Expiry',
  ];
  final List<String> _filterOptions = const [
    'All Items',
    'Active',
    'At risk',
    'Available',
    'Consumed',
  ];
  String sortBy = 'Category';
  String filterBy = 'All Items';

  // Sample items (shoppinglist-style info + status/expiry on right)
  final List<PantryItem> _items = [
    PantryItem(
      id: 'oj1',
      name: 'Orange Juice',
      brand: 'Fruit Soda Orange',
      size: '1L',
      category: 'Beverages',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/0/0b/Orange_juice_1.jpg',
      qty: 1,
      expiresText: 'in 3 days',
      status: ItemStatus.atRisk,
    ),
    PantryItem(
      id: 'ketch397',
      name: 'Ketchup',
      brand: 'Heinz',
      size: '397g',
      category: 'Condiments',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/9/9b/Tomato_ketchup.jpg',
      qty: 1,
      expiresText: '06/30/25',
      status: ItemStatus.active,
    ),
    PantryItem(
      id: 'onion50',
      name: 'Onion Powder',
      brand: 'McCormick',
      size: '50g',
      category: 'Herbs/Spices',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/2/2a/Onion_Powder.jpg',
      qty: 1,
      expiresText: '07/03/25',
      status: ItemStatus.active,
    ),
    PantryItem(
      id: 'soy300',
      name: 'Soy Sauce',
      brand: 'Silver Swan',
      size: '300ml',
      category: 'Condiments',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/1/13/Soy_sauce.jpg',
      qty: 2,
      expiresText: '07/15/25',
      status: ItemStatus.available,
    ),
    PantryItem(
      id: 'sardines',
      name: 'Canned Sardines',
      brand: '555',
      size: '155g',
      category: 'Canned Goods',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/2/27/Conserva_de_sardinas.jpg',
      qty: 3,
      expiresText: '09/19/25',
      status: ItemStatus.available,
    ),
    PantryItem(
      id: 'coke500',
      name: 'Coca-Cola',
      brand: 'Coke',
      size: '500ml',
      category: 'Beverages',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/4/4f/Coca-Cola_bottle.jpg',
      qty: 2,
      expiresText: '12/19/26',
      status: ItemStatus.active,
    ),
    PantryItem(
      id: 'pasta1',
      name: 'Spaghetti Pasta',
      brand: 'Del Monte',
      size: '1kg',
      category: 'Grains',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/f/fd/Spaghetti_500g.jpg',
      qty: 2,
      expiresText: '01/20/26',
      status: ItemStatus.available,
    ),
    PantryItem(
      id: 'milk1L',
      name: 'Fresh Milk',
      brand: 'Cowhead',
      size: '1L',
      category: 'Dairy',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/a/a4/Milk_glass.jpg',
      qty: 1,
      expiresText: '03/01/25',
      status: ItemStatus.atRisk,
    ),
    PantryItem(
      id: 'egg12',
      name: 'Eggs',
      brand: 'Farm Fresh',
      size: '1 dozen',
      category: 'Dairy',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/2/2f/12eggs.jpg',
      qty: 1,
      expiresText: '02/10/25',
      status: ItemStatus.active,
    ),
    PantryItem(
      id: 'bread1',
      name: 'Loaf Bread',
      brand: 'Gardenia',
      size: '600g',
      category: 'Bakery',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/6/61/Sliced_bread.jpg',
      qty: 1,
      expiresText: 'in 2 days',
      status: ItemStatus.atRisk,
    ),
    PantryItem(
      id: 'chips1',
      name: 'Potato Chips',
      brand: 'Piattos',
      size: 'Large',
      category: 'Snacks',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/6/69/Potato-Chips.jpg',
      qty: 5,
      expiresText: '05/15/25',
      status: ItemStatus.active,
    ),
    PantryItem(
      id: 'coffee200',
      name: 'Coffee',
      brand: 'Nescafé',
      size: '200g',
      category: 'Beverages',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/4/45/A_small_cup_of_coffee.JPG',
      qty: 1,
      expiresText: '11/01/26',
      status: ItemStatus.available,
    ),
    PantryItem(
      id: 'icecream',
      name: 'Vanilla Ice Cream',
      brand: 'Selecta',
      size: '1L',
      category: 'Frozen',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/b/bb/Ice_Cream_dessert_02.jpg',
      qty: 1,
      expiresText: '12/12/25',
      status: ItemStatus.active,
    ),
    PantryItem(
      id: 'butter200',
      name: 'Butter',
      brand: 'Anchor',
      size: '200g',
      category: 'Dairy',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/7/7c/Butter.jpg',
      qty: 1,
      expiresText: '04/01/25',
      status: ItemStatus.available,
    ),
  ];

  // ---- Helpers for editing round-trip ----
  DateTime? _tryParseExpiryFromText(String t) {
    // Supports MM/DD/YY or MM/DD/YYYY only. Returns null for phrases like "in 3 days".
    final mmddyy = RegExp(r'^(\d{1,2})\/(\d{1,2})\/(\d{2}|\d{4})$');
    final m = mmddyy.firstMatch(t.trim());
    if (m == null) return null;
    final mm = int.parse(m.group(1)!);
    final dd = int.parse(m.group(2)!);
    final yraw = m.group(3)!;
    final yyyy = yraw.length == 2 ? (2000 + int.parse(yraw)) : int.parse(yraw);
    return DateTime(yyyy, mm, dd);
  }

  String _mmddyy(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    final yy = (d.year % 100).toString().padLeft(2, '0');
    return '$mm/$dd/$yy';
  }

  Future<void> _openEditor(PantryItem item) async {
    final initialExpiry = _tryParseExpiryFromText(item.expiresText);

    final res = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => Material(
          child: EditPantryItem(
            item: item,
            initialName: item.name,
            initialCategory: item.category,
            initialQuantity: item.qty,
            initialExpiry: initialExpiry,
            initialNotes: '',
            categories: const [
              'Beverages',
              'Canned Goods',
              'Dairy',
              'Snacks',
              'Produce',
              'Meat',
              'Bakery',
              'Household',
              'Other',
            ],
          ),
        ),
      ),
    );

    if (res == null) return;

    setState(() {
      item.name = (res['name'] as String).trim();

      final newCat = res['category'] as String?;
      if (newCat != null && newCat.trim().isNotEmpty) {
        item.category = newCat.trim();
      }
      item.qty = res['quantity'] as int;

      final iso = res['expiry'] as String?;
      if (iso != null) {
        final dt = DateTime.tryParse(iso);
        if (dt != null) item.expiresText = _mmddyy(dt);
      }

      // If you extend EditPantryItem to return brand/size:
      if (res.containsKey('brand')) {
        item.brand = (res['brand'] as String).trim();
      }
      if (res.containsKey('size')) {
        item.size = (res['size'] as String).trim();
      }
    });
  }

  // ---- Search / filter actions ----
  void _toggleSearch() {
    setState(() {
      isSearching = !isSearching;
      if (!isSearching) {
        _query = '';
        _searchCtrl.clear();
      }
    });
  }

  void _onQueryChanged(String v) => setState(() => _query = v.trim());

  // ---------- Floating (top) SnackBar helpers ----------
  double _topSnackMargin() {
    final topSafe = MediaQuery.of(context).padding.top;
    final titleH = _titleKey.currentContext?.size?.height ?? 0;
    final controlsH = _controlsKey.currentContext?.size?.height ?? 0;
    return topSafe + titleH + controlsH + 8; // little breathing room
  }

  void _showTopSnackWithAction({
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.up,
        margin: EdgeInsets.fromLTRB(16, _topSnackMargin(), 16, 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: (actionLabel != null && onAction != null)
            ? SnackBarAction(label: actionLabel, onPressed: onAction)
            : null,
      ),
    );
  }

  // ---- Delete with UNDO (top-anchored, no layout shift) ----
  void _deleteFromViewIndex(int viewIndex) {
    final view = _filteredAndSorted();
    if (viewIndex < 0 || viewIndex >= view.length) return;
    final removed = view[viewIndex];
    final originalIndex = _items.indexWhere((e) => e.id == removed.id);
    if (originalIndex == -1) return;

    final backup = _items.removeAt(originalIndex);
    setState(() {});

    _showTopSnackWithAction(
      message: 'Deleted "${backup.name}"',
      actionLabel: 'Undo',
      onAction: () => setState(() => _items.insert(originalIndex, backup)),
    );
  }

  // ---- Filtering & Sorting ----
  List<PantryItem> _filteredAndSorted() {
    List<PantryItem> list = _items.where((it) {
      switch (filterBy) {
        case 'Active':
          if (it.status != ItemStatus.active) return false;
          break;
        case 'At risk':
          if (it.status != ItemStatus.atRisk) return false;
          break;
        case 'Available':
          if (it.status != ItemStatus.available) return false;
          break;
        case 'Consumed':
          if (it.status != ItemStatus.consumed) return false;
          break;
        default:
          break;
      }
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        final hay = '${it.name} ${it.brand} ${it.size} ${it.category}'
            .toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();

    switch (sortBy) {
      case 'Name':
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case 'Quantity':
        list.sort((a, b) => b.qty.compareTo(a.qty));
        break;
      case 'Expiry':
        list.sort((a, b) => a.expiresText.compareTo(b.expiresText));
        break;
      case 'Category':
      default:
        list.sort(
          (a, b) =>
              a.category.toLowerCase().compareTo(b.category.toLowerCase()),
        );
    }
    return list;
  }

  // ---- UI helpers ----
  MapEntry<String, Color> _statusMeta(ItemStatus status) {
    switch (status) {
      case ItemStatus.active:
        return const MapEntry('Active', Color(0xFFF2DE7E));
      case ItemStatus.atRisk:
        return const MapEntry('At risk', Color(0xFFF1A648));
      case ItemStatus.available:
        return const MapEntry('Available', Color(0xFF58A66A));
      case ItemStatus.consumed:
        return const MapEntry('Consumed', Colors.grey);
    }
  }

  Color _nameColorFor(PantryItem it) {
    switch (it.status) {
      case ItemStatus.atRisk:
        return const Color(0xFFD32F2F);
      case ItemStatus.consumed:
        return Colors.grey.shade600;
      default:
        return const Color(0xFF000000);
    }
  }

  Color _categoryColorFor(PantryItem it) {
    return it.status == ItemStatus.available
        ? const Color(0xFF1B5E20)
        : const Color(0xFF6F6F6F);
  }

  Color _expiresValueColorFor(PantryItem it) {
    return it.status == ItemStatus.atRisk
        ? const Color(0xFFF57C00)
        : Colors.black87;
  }

  Color _rowBgFor(PantryItem it) => rowColor;

  Widget _statusChipButton(PantryItem item) {
    final meta = _statusMeta(item.status);

    return Theme(
      data: Theme.of(context).copyWith(dividerTheme: kStatusMenuDividerTheme),
      child: PopupMenuButton<ItemStatus>(
        tooltip: 'Change status',
        offset: kStatusMenuOffset,
        elevation: kStatusMenuElevation,
        color: const Color(0xFFFDFDFC),
        shape: kStatusMenuShape,
        constraints: kStatusMenuMinSize,
        position: PopupMenuPosition.under,
        onSelected: (choice) {
          setState(() {
            if (choice == ItemStatus.consumed) {
              if (item.status != ItemStatus.consumed) {
                item.prevStatus = item.status;
              }
              item.status = ItemStatus.consumed;
            } else {
              item.status = choice;
            }
          });
        },
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: ItemStatus.active,
            child: Text('Active', style: kStatusMenuTextStyle),
          ),
          PopupMenuDivider(height: 0),
          PopupMenuItem(
            value: ItemStatus.available,
            child: Text('Available', style: kStatusMenuTextStyle),
          ),
          PopupMenuDivider(height: 0),
          PopupMenuItem(
            value: ItemStatus.atRisk,
            child: Text('At risk', style: kStatusMenuTextStyle),
          ),
          PopupMenuDivider(height: 0),
          PopupMenuItem(
            value: ItemStatus.consumed,
            child: Text('Consumed', style: kStatusMenuTextStyle),
          ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: meta.value,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(meta.key, style: chipTextStyle),
        ),
      ),
    );
  }

  // Base row (content) — now WITHOUT the icon chip
  Widget _rowBaseContent(PantryItem item) {
    final bool isConsumed = item.status == ItemStatus.consumed;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kTileHPad,
        vertical: kTileVPad,
      ),
      child: Row(
        crossAxisAlignment: rowCrossAxis,
        mainAxisAlignment: rowMainAxis,
        children: [
          // Checkbox (consume / revert)
          Checkbox(
            value: isConsumed,
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  if (item.status != ItemStatus.consumed) {
                    item.prevStatus = item.status;
                  }
                  item.status = ItemStatus.consumed;
                } else {
                  item.status = item.prevStatus ?? ItemStatus.active;
                }
              });
            },
            activeColor: headerGreen,
            checkColor: Colors.white,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),

          // Keep spacing where the icon used to be
          const SizedBox(width: 10),

          // Left block (matches shoppinglist.dart)
          Expanded(
            child: Column(
              crossAxisAlignment: leftColAlign,
              children: [
                // Name
                Padding(
                  padding: const EdgeInsets.only(top: kTitleTopNudge),
                  child: Text(
                    item.name,
                    style: nameStyle.copyWith(color: _nameColorFor(item)),
                    textAlign: nameTextAlign,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Subline: brand · size
                if (item.subline.isNotEmpty) ...[
                  const SizedBox(height: kTitleMetaGap),
                  Text(
                    item.subline,
                    style: subStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: kSubMetaGap),

                // Category + Qty
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.category,
                        style: metaLabelStyle.copyWith(
                          color: _categoryColorFor(item),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: kCatQtyGap),
                    Text('Qty: ', style: metaLabelStyle),
                    const SizedBox(width: kQtyValueGap),
                    Text('${item.qty}', style: metaValueStyle),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: kLeftRightGap),

          // Right block: status chip + "Expires in ..."
          Column(
            crossAxisAlignment: rightColCross,
            mainAxisAlignment: rightColMain,
            children: [
              _statusChipButton(item),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Expires in: ', style: metaLabelStyle),
                  Text(
                    item.expiresText,
                    style: metaValueStyle.copyWith(
                      color: _expiresValueColorFor(item),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Row with overlay for consumed & slidable actions (Edit/Delete)
  Widget _slidableRow(List<PantryItem> view, int idx) {
    final item = view[idx];
    final bool isConsumed = item.status == ItemStatus.consumed;

    return Slidable(
      key: ValueKey(item.id),
      closeOnScroll: true,
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.40, // space for Edit + Delete
        children: [
          SlidableAction(
            onPressed: (_) => _openEditor(item),
            icon: Icons.edit,
            label: 'Edit',
            backgroundColor: headerGreen,
            foregroundColor: Colors.white,
            borderRadius: BorderRadius.circular(0),
          ),
          SlidableAction(
            onPressed: (_) => _deleteFromViewIndex(idx),
            icon: Icons.delete_outline,
            label: 'Delete',
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            borderRadius: BorderRadius.circular(0),
          ),
        ],
      ),
      child: Material(
        color: _rowBgFor(item),
        child: Stack(
          children: [
            _rowBaseContent(item),
            if (isConsumed)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: true,
                  child: Container(color: Colors.white.withOpacity(0.45)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final view = _filteredAndSorted();

    return Scaffold(
      backgroundColor: softCream,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title area (keyed for measuring)
          Padding(
            key: _titleKey,
            padding: const EdgeInsets.fromLTRB(15, 12, 12, 6),
            child: const Text(
              'Pantry Inventory',
              style: TextStyle(
                color: Color(0xFF347928),
                fontFamily: 'Inter',
                fontSize: 34,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          // Controls/search area (keyed)
          KeyedSubtree(key: _controlsKey, child: _controlsRow()),
          Divider(height: 1, thickness: 1, color: sep),
          Expanded(
            child: ListView.separated(
              itemCount: view.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, thickness: 1, color: sep),
              itemBuilder: (_, i) => _slidableRow(view, i),
            ),
          ),
        ],
      ),
    );
  }

  // Pills row + search replacement
  Widget _controlsRow() {
    if (isSearching) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: SizedBox(
          height: 44,
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onQueryChanged,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search name, brand, size, or category...',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _searchCtrl.clear();
                  _onQueryChanged('');
                  _toggleSearch();
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: sep),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: sep),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: headerGreen),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 2, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _dropdownPill(
                    label: 'Sort by',
                    value: sortBy,
                    items: _sortOptions,
                    onChanged: (v) => setState(() => sortBy = v ?? sortBy),
                  ),
                  _dropdownPill(
                    label: 'Filter',
                    value: filterBy,
                    items: _filterOptions,
                    onChanged: (v) => setState(() => filterBy = v ?? filterBy),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Search',
            onPressed: _toggleSearch,
            icon: Icon(Icons.search, color: headerGreen),
          ),
        ],
      ),
    );
  }

  Widget _dropdownPill({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: kPillBg, // pill background color
        borderRadius: BorderRadius.circular(24),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          value: value,

          // The visible pill (label: value ▾)
          customButton: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$label: ', style: pillLabelStyle),
                Text(value, style: pillValueStyle),
                const SizedBox(width: 6),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: kPillTextColor,
                ),
              ],
            ),
          ),

          // The opened menu (option list)
          items: items
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(e, style: menuItemTextStyle),
                ),
              )
              .toList(),
          onChanged: onChanged,

          dropdownStyleData: DropdownStyleData(
            maxHeight: 260,
            decoration: BoxDecoration(
              color: kMenuBg,
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 6,
          ),
          menuItemStyleData: const MenuItemStyleData(
            height: 40,
            padding: EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ),
    );
  }
}
