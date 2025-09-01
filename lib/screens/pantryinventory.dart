import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
// Update to your actual path:

class Pantryinventory extends StatefulWidget {
  final List<PantryItem> items;
  final Function(PantryItem) onEdit;
  final Function(PantryItem) onDelete;

  const Pantryinventory({
    super.key,
    required this.items,
    required this.onEdit,
    required this.onDelete,
  });

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
  bool selected;

  PantryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.qty,
    required this.expiresText,
    required this.status,
    this.selected = false,
  });
}

class _PantryInventoryBodyState extends State<Pantryinventory> {
  // Palette to match your UI
  final Color headerGreen = const Color(0xFF2E7D32);
  final Color softCream = const Color(0xFFFFFBE6);
  final Color rowAlt = const Color(0xFFF7EFD3);
  final Color sep = const Color(0xFFE9E1C7);

  // Search state (search replaces the pills row)
  bool isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  // Filters & Sorting
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

  List<PantryItem> _items = [];

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items); // Initialize with items passed from parent
  }

  bool get _inSelectMode => _items.any((e) => e.selected);

  // ---------- Actions ----------
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
    // Map the visible index to the original list so Undo restores correctly
    final view = _filteredAndSorted();
    if (viewIndex < 0 || viewIndex >= view.length) return;
    final removed = view[viewIndex];
    widget.onDelete(removed); // Call the onDelete callback
    setState(() {
      _items.removeWhere((element) => element.id == removed.id);
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${removed.name}"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Undo functionality would require more complex state management
            // if we want to truly re-add it to the parent's list.
            // For now, we'll just re-fetch the list from the parent if needed.
          },
        ),
      ),
    );
  }

  // ---------- Filtering & Sorting ----------
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
        final hit =
            it.name.toLowerCase().contains(q) ||
            it.category.toLowerCase().contains(q);
        if (!hit) return false;
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
        int rank(String s) => s.startsWith('in ') ? 0 : 1; // simple heuristic
        list.sort((a, b) {
          final r = rank(a.expiresText).compareTo(rank(b.expiresText));
          if (r != 0) return r;
          return a.expiresText.compareTo(b.expiresText);
        });
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

  // ---------- UI ----------

  Widget _statusChip(ItemStatus status) {
    String text;
    Color bg;
    switch (status) {
      case ItemStatus.active:
        text = 'Active';
        bg = const Color(0xFFF2DE7E);
        break;
      case ItemStatus.atRisk:
        text = 'At risk';
        bg = const Color(0xFFF1A648);
        break;
      case ItemStatus.available:
        text = 'Available';
        bg = const Color(0xFF58A66A);
        break;
      case ItemStatus.consumed:
        text = 'Consumed';
        bg = Colors.grey.shade500;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
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
      decoration: BoxDecoration(
        color: const Color(0xFFE9E1C7),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      margin: const EdgeInsets.only(right: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          value: value,
          customButton: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$label: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF20451F),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF20451F),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: Color(0xFF20451F),
                ),
              ],
            ),
          ),
          items: items
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(
                    e,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          dropdownStyleData: DropdownStyleData(
            padding: EdgeInsets.zero,
            maxHeight: 240,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          menuItemStyleData: const MenuItemStyleData(
            height: 40,
            padding: EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ),
    );
  }

  // Title like the screenshot (inside the cream area)
  Widget _bigTitle() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Text(
        'Pantry Inventory',
        style: TextStyle(
          color: Color(0xFF20451F),
          fontSize: 28,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // Controls aligned like the picture; pills never overflow because we give them
  // a horizontal scroll container; the search icon stays at the right edge.
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
                borderSide: const BorderSide(color: Color(0xFF2E7D32)),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 8, 10),
      child: Row(
        children: [
          // Pills area that can scroll horizontally to avoid overflow
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
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => sortBy = v);
                    },
                  ),
                  _dropdownPill(
                    label: 'Filter',
                    value: filterBy,
                    items: _filterOptions,
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => filterBy = v);
                    },
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Search',
            onPressed: _toggleSearch,
            icon: const Icon(Icons.search, color: Color(0xFF20451F)),
          ),
        ],
      ),
    );
  }

  Widget _rowTile(PantryItem item, int visualIndex) {
    return Material(
      color: visualIndex.isEven ? Colors.white : rowAlt,
      child: InkWell(
        onLongPress: () => setState(() => item.selected = !item.selected),
        onTap: () {
          if (_inSelectMode) setState(() => item.selected = !item.selected);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Checkbox(
                value: item.selected,
                onChanged: (v) => setState(() => item.selected = v ?? false),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imageUrl,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _ , _ ) => const Icon(Icons.image),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF20451F),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6F6F6F),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            item.category,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6F6F6F),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Qty: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6F6F6F),
                          ),
                        ),
                        Text(
                          '${item.qty}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Expires in: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6F6F6F),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            item.expiresText,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _statusChip(item.status),
            ],
          ),
        ),
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
          return true; // remove from the visible list
        } else {
          // LEFT → go to edit (do NOT dismiss)
          widget.onEdit(item);
          return false;
        }
      },
      child: _rowTile(item, idx),
    );
  }

  @override
  Widget build(BuildContext context) {
    final view = _filteredAndSorted();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _bigTitle(),
        _controlsRow(), // pills or search field
        const Divider(height: 1, thickness: 1, color: Color(0xFFE9E1C7)),
        Expanded(
          child: ListView.separated(
            itemCount: view.length,
            separatorBuilder: (_, _ ) =>
                Divider(height: 1, thickness: 1, color: sep),
            itemBuilder: (_, i) => _dismissibleRow(view, i),
          ),
        ),
      ],
    );
  }
}
