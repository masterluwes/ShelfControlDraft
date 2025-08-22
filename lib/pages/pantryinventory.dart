import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
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
  String category;
  final String imageUrl;
  int qty;
  String expiresText;
  ItemStatus status;
  ItemStatus? prevStatus; // Remember last non-consumed state

  PantryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.qty,
    required this.expiresText,
    required this.status,
    this.prevStatus,
  });
}

class _PantryInventoryBodyState extends State<Pantryinventory> {
  // Palette
  final Color headerGreen = const Color(0xFF2E7D32);
  final Color softCream = const Color(0xFFFFFBE6);
  final Color rowColor = Color.fromARGB(255, 255, 254, 250);
  final Color sep = const Color.fromARGB(255, 230, 230, 230); // divider

  static const double metaSize = 13; // Category / Qty / Expires labels & values
  static const double pillSize = 13; // Status chip text

  TextStyle get nameStyle => const TextStyle(
    fontFamily: 'Roboto',
    fontSize: 18,
    fontWeight: FontWeight.w900,
    color: Color(0xFF20451F),
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

  //Spacing knobs
  static const double kTitleTopNudge = 4; // push the title line down a bit
  static const double kTitleMetaGap = 6; // Title ↔ Category/Qty
  static const double kCatQtyGap = 12; // Category ↔ "Qty:"
  static const double kQtyValueGap = 4; // "Qty:" ↔ value

  // Positioning knobs
  static const double kTileHPad = 12; // whole item: left/right padding
  static const double kTileVPad = 10; // whole item: top/bottom padding
  static const double kCheckboxTextGap = 12; // gap after checkbox
  static const double kLeftRightGap = 12; // gap between left and right blocks
  static const double kCheckboxNudgeTop = 4; // vertical nudge for the checkbox

  // Row alignment for the whole item row
  CrossAxisAlignment rowCrossAxis = CrossAxisAlignment.start;
  MainAxisAlignment rowMainAxis = MainAxisAlignment.start;

  // Left text block alignment
  CrossAxisAlignment leftColAlign = CrossAxisAlignment.start;

  // Right status block alignment
  CrossAxisAlignment rightColCross = CrossAxisAlignment.end;
  MainAxisAlignment rightColMain = MainAxisAlignment.start;

  // Text alignment inside the left block
  TextAlign nameTextAlign = TextAlign.left;
  TextAlign categoryTextAlign = TextAlign.left;

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

  // Status dropdown (PopupMenu) styling knobs
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
    color: Color(0xFFBDBDBD), // line color
    thickness: 1, // line thickness
    space: 0, // vertical padding around the line
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

  // Sample items
  final List<PantryItem> _items = [
    PantryItem(
      id: 'oj1',
      name: 'Orange Juice (1L)',
      category: 'Beverages',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/0/0b/Orange_juice_1.jpg',
      qty: 1,
      expiresText: 'in 3 days',
      status: ItemStatus.atRisk,
    ),
    PantryItem(
      id: 'ketch397',
      name: 'Ketchup (397g)',
      category: 'Condiments',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/9/9b/Tomato_ketchup.jpg',
      qty: 1,
      expiresText: '06/30/25',
      status: ItemStatus.active,
    ),
    PantryItem(
      id: 'onion50',
      name: 'Onion Powder (50g)',
      category: 'Herbs/Spices',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/2/2a/Onion_Powder.jpg',
      qty: 1,
      expiresText: '07/03/25',
      status: ItemStatus.active,
    ),
    PantryItem(
      id: 'soy300',
      name: 'Soy Sauce (300ml)',
      category: 'Condiments',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/1/13/Soy_sauce.jpg',
      qty: 1,
      expiresText: '07/15/25',
      status: ItemStatus.available,
    ),
    PantryItem(
      id: 'sardines',
      name: 'Canned Sardines',
      category: 'Canned Goods',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/2/27/Conserva_de_sardinas.jpg',
      qty: 3,
      expiresText: '09/19/25',
      status: ItemStatus.available,
    ),
    PantryItem(
      id: 'coke500',
      name: 'Coca Cola (500ml)',
      category: 'Beverages',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/4/4f/Coca-Cola_bottle.jpg',
      qty: 2,
      expiresText: '12/19/26',
      status: ItemStatus.active,
    ),
    PantryItem(
      id: 'pasta1',
      name: 'Spaghetti Pasta (1kg)',
      category: 'Grains',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/f/fd/Spaghetti_500g.jpg',
      qty: 2,
      expiresText: '01/20/26',
      status: ItemStatus.available,
    ),
    PantryItem(
      id: 'milk1L',
      name: 'Fresh Milk (1L)',
      category: 'Dairy',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/a/a4/Milk_glass.jpg',
      qty: 1,
      expiresText: '03/01/25',
      status: ItemStatus.atRisk,
    ),
    PantryItem(
      id: 'egg12',
      name: 'Eggs (Dozen)',
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
      category: 'Snacks',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/6/69/Potato-Chips.jpg',
      qty: 5,
      expiresText: '05/15/25',
      status: ItemStatus.active,
    ),
    PantryItem(
      id: 'coffee200',
      name: 'Coffee (200g)',
      category: 'Beverages',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/4/45/A_small_cup_of_coffee.JPG',
      qty: 1,
      expiresText: '11/01/26',
      status: ItemStatus.available,
    ),
    PantryItem(
      id: 'icecream',
      name: 'Vanilla Ice Cream (1L)',
      category: 'Frozen',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/b/bb/Ice_Cream_dessert_02.jpg',
      qty: 1,
      expiresText: '12/12/25',
      status: ItemStatus.active,
    ),
    PantryItem(
      id: 'butter200',
      name: 'Butter (200g)',
      category: 'Dairy',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/7/7c/Butter.jpg',
      qty: 1,
      expiresText: '04/01/25',
      status: ItemStatus.available,
    ),
  ];

  // Actions
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

  void _deleteFromViewIndex(int viewIndex) {
    final view = _filteredAndSorted();
    if (viewIndex < 0 || viewIndex >= view.length) return;
    final removed = view[viewIndex];
    final originalIndex = _items.indexWhere((e) => e.id == removed.id);
    if (originalIndex == -1) return;

    final backup = _items.removeAt(originalIndex);
    setState(() {});
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${backup.name}"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => setState(() => _items.insert(originalIndex, backup)),
        ),
      ),
    );
  }

  //  Filtering & Sorting
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
        if (!it.name.toLowerCase().contains(q) &&
            !it.category.toLowerCase().contains(q)) {
          return false;
        }
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
        list.sort(
          (a, b) => a.expiresText.compareTo(b.expiresText),
        ); // demo-friendly
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

  //  UI
  // Status → label + color
  MapEntry<String, Color> _statusMeta(ItemStatus status) {
    switch (status) {
      case ItemStatus.active:
        return MapEntry('Active', const Color(0xFFF2DE7E));
      case ItemStatus.atRisk:
        return MapEntry('At risk', const Color(0xFFF1A648));
      case ItemStatus.available:
        return MapEntry('Available', const Color(0xFF58A66A));
      case ItemStatus.consumed:
        return MapEntry('Consumed', Colors.grey);
    }
  }

  // Per-item dynamic colors
  Color _nameColorFor(PantryItem it) {
    switch (it.status) {
      case ItemStatus.atRisk:
        return const Color(0xFFD32F2F); // red-ish for at risk
      case ItemStatus.consumed:
        return Colors.grey.shade600; // dim when consumed
      default:
        return const Color(0xFF000000); // default title color
    }
  }

  Color _categoryColorFor(PantryItem it) {
    return it.status == ItemStatus.available
        ? const Color(0xFF1B5E20) // deeper green when available
        : const Color(0xFF6F6F6F); // default
  }

  Color _expiresValueColorFor(PantryItem it) {
    return it.status == ItemStatus.atRisk
        ? const Color(0xFFF57C00) // orange when at risk
        : Colors.black87; // default strong text
  }

  Color _rowBgFor(PantryItem it) {
    switch (it.status) {
      case ItemStatus.atRisk:
        return rowColor; // keep row base; change to a tint if desired
      case ItemStatus.consumed:
        return rowColor;
      default:
        return rowColor;
    }
  }

  // Status chip with custom menu adjustments
  Widget _statusChipButton(PantryItem item) {
    final meta = _statusMeta(item.status);

    return Theme(
      // This Theme only affects the popup menu
      data: Theme.of(context).copyWith(dividerTheme: kStatusMenuDividerTheme),
      child: PopupMenuButton<ItemStatus>(
        tooltip: 'Change status',
        offset: kStatusMenuOffset,
        elevation: kStatusMenuElevation,
        color: const Color(0xFFFDFDFC), // menu background
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

        // Add lines between items using PopupMenuDivider
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: ItemStatus.active,
            child: Text('Active', style: kStatusMenuTextStyle),
          ),
          const PopupMenuDivider(height: 0), // line

          const PopupMenuItem(
            value: ItemStatus.available,
            child: Text('Available', style: kStatusMenuTextStyle),
          ),
          const PopupMenuDivider(height: 0), // line

          const PopupMenuItem(
            value: ItemStatus.atRisk,
            child: Text('At risk', style: kStatusMenuTextStyle),
          ),
          const PopupMenuDivider(height: 0), // line

          const PopupMenuItem(
            value: ItemStatus.consumed,
            child: Text('Consumed', style: kStatusMenuTextStyle),
          ),
        ],

        // Closed state chip
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

  // One row, using positioning + spacing knobs
  Widget _rowBaseContent(PantryItem item) {
    final bool isConsumed = item.status == ItemStatus.consumed;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: kTileHPad, vertical: kTileVPad),
      child: Row(
        crossAxisAlignment: rowCrossAxis,
        mainAxisAlignment: rowMainAxis,
        children: [
          // Checkbox (consume / revert)
          Padding(
            padding: EdgeInsets.only(top: kCheckboxNudgeTop),
            child: Checkbox(
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
            ),
          ),

          SizedBox(width: kCheckboxTextGap),

          // Left block: name, category + qty
          Expanded(
            child: Column(
              crossAxisAlignment: leftColAlign,
              children: [
                // Name (nudged down a bit)
                Padding(
                  padding: EdgeInsets.only(top: kTitleTopNudge),
                  child: Text(
                    item.name,
                    style: nameStyle.copyWith(color: _nameColorFor(item)),
                    textAlign: nameTextAlign,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // space between title and category/qty
                SizedBox(height: kTitleMetaGap),

                // Category + Qty
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.category,
                        style: metaLabelStyle.copyWith(
                          color: _categoryColorFor(item),
                        ),
                        textAlign: categoryTextAlign,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // space between category and "Qty:"
                    SizedBox(width: kCatQtyGap),

                    Text('Qty: ', style: metaLabelStyle),

                    // space between "Qty:" and numeric value
                    SizedBox(width: kQtyValueGap),

                    Text('${item.qty}', style: metaValueStyle),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(width: kLeftRightGap),

          // Right block: status chip and "Expires in ..."
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

  Widget _rowTile(PantryItem item, int visualIndex) {
    final bool isConsumed = item.status == ItemStatus.consumed;

    return Material(
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
    );
  }

  Widget _dismissibleRow(List<PantryItem> view, int idx) {
    final item = view[idx];
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.horizontal,
      background: Container(
        color: Colors.red.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      secondaryBackground: Container(
        color: Colors.green.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.edit, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // RIGHT → delete with Undo
          _deleteFromViewIndex(idx);
          return true;
        } else {
          // LEFT → go to edit (only way to open editor)
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => Material(child: EditPantryItem(item: item)),
            ),
          );
          return false;
        }
      },
      child: _rowTile(view[idx], idx),
    );
  }

  @override
  Widget build(BuildContext context) {
    final view = _filteredAndSorted();

    return Scaffold(
      backgroundColor: softCream,
      // No AppBar here (keeps only your main/top app bar elsewhere)
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(15, 12, 12, 6),
            child: Text(
              'Pantry Inventory',
              style: TextStyle(
                color: Color(0xFF347928),
                fontFamily: 'Inter',
                fontSize: 34,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _controlsRow(),
          Divider(height: 1, thickness: 1, color: sep),
          Expanded(
            child: ListView.separated(
              itemCount: view.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, thickness: 1, color: sep),
              itemBuilder: (_, i) => _dismissibleRow(view, i),
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
              hintText: 'Search items or categories...',
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
                Text('$label: ', style: pillLabelStyle), // label style
                Text(value, style: pillValueStyle), // value style
                const SizedBox(width: 6),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: kPillTextColor, // icon color
                ),
              ],
            ),
          ),

          // The opened menu (option list)
          items: items
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(e, style: menuItemTextStyle), // option style
                ),
              )
              .toList(),
          onChanged: onChanged,

          dropdownStyleData: DropdownStyleData(
            maxHeight: 260,
            decoration: BoxDecoration(
              color: kMenuBg, // menu background
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
