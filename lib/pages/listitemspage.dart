import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

/// ===== Shared store to broadcast the currently selected shopping list =====
/// (shoppinglist.dart listens to this and refreshes automatically)
class MainShoppingListStore extends ChangeNotifier {
  MainShoppingListStore._();
  static final MainShoppingListStore instance = MainShoppingListStore._();

  String? currentListTitle;
  List<_Item> currentItems = const [];

  void setMainList({required String title, required List<_Item> items}) {
    currentListTitle = title;
    // deep copy so edits on this page won’t mutate the active list
    currentItems = items.map((e) => e.copy()).toList(growable: false);
    notifyListeners();
  }

  /// Public way to clear without touching protected notifyListeners externally.
  void clearMain() {
    currentListTitle = null;
    currentItems = const [];
    notifyListeners();
  }

  bool get hasMain => currentListTitle != null && currentItems.isNotEmpty;
}

/// ===== Internal model used by both pages =====
class _Item {
  _Item({
    required this.id,
    required this.name,
    required this.category,
    this.brand,
    this.sizeText,
    this.qty = 1,
    this.inCart = false,
    this.bookmarked = false,
    this.incPulse = false,
    this.decPulse = false,
  });

  final String id;
  String name;
  String category;
  String? brand; // e.g. Gardenia
  String? sizeText; // e.g. 1L, 600g
  int qty;
  bool inCart; // checkbox (purchased) state
  bool bookmarked; // “pin” to top
  bool incPulse;
  bool decPulse;

  _Item copy() => _Item(
    id: id,
    name: name,
    category: category,
    brand: brand,
    sizeText: sizeText,
    qty: qty,
    inCart: inCart,
    bookmarked: bookmarked,
    incPulse: incPulse,
    decPulse: decPulse,
  );
}

/// ===== Page =====
class ListItemsPage extends StatefulWidget {
  const ListItemsPage({super.key, required this.listTitle});
  final String listTitle;

  @override
  State<ListItemsPage> createState() => _ListItemsPageState();
}

class _ListItemsPageState extends State<ListItemsPage> {
  // Palette
  final Color headerGreen = const Color(0xFF2E7D32);
  final Color softCream = const Color(0xFFFFFBE6);
  final Color sep = const Color.fromARGB(255, 230, 230, 230);

  // Categories (same set as Shoppinglist)
  final List<String> _categories = const [
    'Beverages',
    'Baked Goods',
    'Condiments',
    'Canned Goods',
    'Dairy',
    'Produce',
    'Snacks',
    'Other',
  ];

  // Demo content (replace with your data source if needed)
  final List<_Item> _items = [
    _Item(
      id: 'oj',
      name: 'Orange Juice',
      brand: 'Fruit Soda Orange',
      sizeText: '1L',
      category: 'Beverages',
      qty: 2,
    ),
    _Item(
      id: 'bread',
      name: 'Bread',
      brand: 'Gardenia Wheat Bread',
      category: 'Baked Goods',
      qty: 1,
    ),
    _Item(
      id: 'mayo',
      name: 'Mayonnaise',
      brand: 'Ladies Choice Mayonnaise',
      category: 'Condiments',
      qty: 1,
    ),
  ];

  // ===== Helpers =====
  void _resort() {
    // Bookmarked items first, then the rest. Keep original relative order.
    setState(() {
      final bookmarked = _items.where((e) => e.bookmarked).toList();
      final others = _items.where((e) => !e.bookmarked).toList();
      _items
        ..clear()
        ..addAll(bookmarked)
        ..addAll(others);
    });
  }

  Future<void> _pulseButton(_Item item, {required bool isInc}) async {
    if (isInc) {
      item.incPulse = true;
    } else {
      item.decPulse = true;
    }
    if (mounted) setState(() {});
    await Future.delayed(const Duration(milliseconds: 160));
    if (isInc) {
      item.incPulse = false;
    } else {
      item.decPulse = false;
    }
    if (mounted) setState(() {});
  }

  void _inc(int i) {
    setState(() => _items[i].qty++);
    _pulseButton(_items[i], isInc: true);
  }

  void _dec(int i) {
    if (_items[i].qty > 0) {
      setState(() => _items[i].qty--);
      _pulseButton(_items[i], isInc: false);
    }
  }

  // ---------- Add Item Dialog (same form/feel as Shoppinglist) ----------
  Future<void> _showAddItemDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final sizeCtrl = TextEditingController();
    String? selectedCategory;

    InputDecoration deco() => InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withOpacity(.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: headerGreen, width: 1.5),
      ),
    );

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: softCream,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: headerGreen.withOpacity(.75),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: headerGreen.withOpacity(.30),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: StatefulBuilder(
              builder: (context, setLocal) {
                return Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Product Name',
                          style: TextStyle(
                            color: headerGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: nameCtrl,
                          decoration: deco(),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Please enter a product name'
                              : null,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Brand (optional)',
                          style: TextStyle(
                            color: headerGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: brandCtrl,
                          decoration: deco(),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Size / Weight (e.g., 150g, 1L) – optional',
                          style: TextStyle(
                            color: headerGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: sizeCtrl,
                          decoration: deco(),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Category',
                          style: TextStyle(
                            color: headerGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField2<String>(
                          value: selectedCategory,
                          isExpanded: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Colors.black.withOpacity(.15),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: headerGreen,
                                width: 1.5,
                              ),
                            ),
                          ),
                          hint: const Text('Select a category'),
                          items: _categories
                              .map(
                                (c) => DropdownMenuItem<String>(
                                  value: c,
                                  child: Text(
                                    c,
                                    style: const TextStyle(fontSize: 14.5),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setLocal(() => selectedCategory = v),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Please select a category'
                              : null,
                          buttonStyleData: const ButtonStyleData(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                          ),
                          iconStyleData: IconStyleData(
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: headerGreen,
                            ),
                            iconSize: 22,
                          ),
                          dropdownStyleData: DropdownStyleData(
                            maxHeight: 260,
                            elevation: 2,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            offset: const Offset(0, 12),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                          ),
                          menuItemStyleData: const MenuItemStyleData(
                            height: 44,
                            padding: EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            InkWell(
                              onTap: () {
                                if (!formKey.currentState!.validate()) return;
                                final id =
                                    'id_${DateTime.now().millisecondsSinceEpoch}';
                                setState(() {
                                  _items.insert(
                                    0,
                                    _Item(
                                      id: id,
                                      name: nameCtrl.text.trim(),
                                      brand: brandCtrl.text.trim().isEmpty
                                          ? null
                                          : brandCtrl.text.trim(),
                                      sizeText: sizeCtrl.text.trim().isEmpty
                                          ? null
                                          : sizeCtrl.text.trim(),
                                      category: selectedCategory!,
                                      qty: 1,
                                    ),
                                  );
                                  _resort();
                                });
                                Navigator.of(ctx).pop();
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    const SnackBar(
                                      content: Text('Item added'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                              },
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: headerGreen,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: const Text(
                                  'Add',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => Navigator.of(ctx).pop(),
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: headerGreen,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: headerGreen,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _editItem(int index) async {
    final it = _items[index];
    final nameCtrl = TextEditingController(text: it.name);
    final brandCtrl = TextEditingController(text: it.brand ?? '');
    final sizeCtrl = TextEditingController(text: it.sizeText ?? '');
    String category = it.category;
    int qty = it.qty;

    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: Text(
                'Edit Item',
                style: TextStyle(
                  color: headerGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Item name',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: sep),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: brandCtrl,
                      decoration: InputDecoration(
                        labelText: 'Brand (optional)',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: sep),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: sizeCtrl,
                      decoration: InputDecoration(
                        labelText: 'Size (e.g. 1L, 600g)',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: sep),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Category',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: sep),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: category,
                          isExpanded: true,
                          items: _categories
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setLocal(() => category = v ?? category),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text(
                          'Quantity',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        _EditQtyButton(
                          icon: Icons.remove,
                          enabled: qty > 0,
                          onTap: () =>
                              setLocal(() => qty = (qty > 0) ? qty - 1 : qty),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$qty',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        _EditQtyButton(
                          icon: Icons.add,
                          enabled: true,
                          onTap: () => setLocal(() => qty++),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogCtx, rootNavigator: true).pop(),
                  child: Text('Cancel', style: TextStyle(color: headerGreen)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: headerGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      it.name = nameCtrl.text.trim().isEmpty
                          ? it.name
                          : nameCtrl.text.trim();
                      it.brand = brandCtrl.text.trim().isEmpty
                          ? null
                          : brandCtrl.text.trim();
                      it.sizeText = sizeCtrl.text.trim().isEmpty
                          ? null
                          : sizeCtrl.text.trim();
                      it.category = category;
                      it.qty = qty;
                    });
                    Navigator.of(dialogCtx, rootNavigator: true).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteItem(int index) async {
    final it = _items[index];
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeleteConfirmDialog(
        headerGreen: headerGreen,
        title: 'Delete item',
        message: 'Delete “${it.name}” from this list?',
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _items.removeAt(index));
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _SuccessDialog(
          headerGreen: headerGreen,
          title: 'Deleted',
          message: 'Item removed from the list.',
        ),
      );
    }
  }

  // Switches this list to be the active one used by shoppinglist.dart
  void _useAsCurrent() {
    MainShoppingListStore.instance.setMainList(
      title: widget.listTitle,
      items: _items,
    );
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Now using this as the current shopping list'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ===== Delete current list flow =====
  Future<void> _confirmDeleteCurrentList() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeleteConfirmDialog(
        headerGreen: headerGreen,
        title: 'Delete shopping list',
        message: 'Are you sure you want to delete “${widget.listTitle}”?',
      ),
    );

    if (confirmed == true && mounted) {
      // If this was the active list, clear shared store safely
      final store = MainShoppingListStore.instance;
      if (store.currentListTitle == widget.listTitle) {
        store.clearMain();
      }

      // Success card
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _SuccessDialog(
          headerGreen: headerGreen,
          title: 'Success!',
          message: 'Shopping list deleted.',
        ),
      );

      if (!mounted) return;
      Navigator.of(
        context,
      ).pop({'deleted': true, 'listTitle': widget.listTitle});
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color grey = Colors.grey.shade700;

    return Scaffold(
      backgroundColor: softCream,
      body: Column(
        children: [
          // === HEADER ===
          Container(
            width: double.infinity,
            color: headerGreen,
            padding: const EdgeInsets.fromLTRB(8, 48, 8, 14),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.listTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Use as current shopping list',
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.white,
                  ),
                  onPressed: _useAsCurrent,
                ),
                IconButton(
                  tooltip: 'Delete list',
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  onPressed: _confirmDeleteCurrentList,
                ),
              ],
            ),
          ),

          Divider(height: 1, thickness: 1, color: sep),

          // === CONTENT ===
          Expanded(
            child: ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => Divider(color: sep, height: 1),
              itemBuilder: (context, index) {
                final it = _items[index];

                return Slidable(
                  key: ValueKey(it.id),
                  endActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    extentRatio: 0.40,
                    children: [
                      SlidableAction(
                        onPressed: (_) => _editItem(index),
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                        backgroundColor: headerGreen,
                        foregroundColor: Colors.white,
                      ),
                      SlidableAction(
                        onPressed: (_) => _confirmDeleteItem(index),
                        icon: Icons.delete_outline,
                        label: 'Delete',
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.white,
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: _ShoppingRowSL(
                            item: it,
                            headerGreen: headerGreen,
                            grey: grey,
                            onToggleInCart: (v) =>
                                setState(() => it.inCart = v ?? false),
                            onToggleBookmark: () {
                              setState(() {
                                it.bookmarked = !it.bookmarked;
                                _resort();
                              });
                            },
                            onDecrement: () => _dec(index),
                            onIncrement: () => _inc(index),
                          ),
                        ),
                        if (it.inCart)
                          Positioned.fill(
                            child: IgnorePointer(
                              ignoring: true,
                              child: Container(
                                color: Colors.white.withOpacity(0.45),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Add new item
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 12, bottom: 12),
        child: ElevatedButton.icon(
          onPressed: _showAddItemDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add new item'),
          style: ElevatedButton.styleFrom(
            backgroundColor: headerGreen,
            foregroundColor: Colors.white,
            elevation: 3,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
      ),
    );
  }
}

/// ===== Icon helpers (name-aware → category fallback) =====
IconData _iconForCategory(String category) {
  switch (category) {
    case 'Beverages':
      return Icons.local_drink;
    case 'Baked Goods':
      return Icons.bakery_dining;
    case 'Condiments':
      return Icons.kitchen;
    case 'Canned Goods':
      return Icons.inventory_2;
    case 'Dairy':
      return Icons.icecream;
    case 'Produce':
      return Icons.eco;
    case 'Snacks':
      return Icons.fastfood;
    default:
      return Icons.category;
  }
}

IconData _iconForName(String name, String category) {
  final n = name.toLowerCase();
  if (n.contains('orange') && n.contains('juice')) return Icons.local_drink;
  if (n.contains('water')) return Icons.water_drop;
  if (n.contains('milk')) return Icons.local_drink;
  if (n.contains('bread') || n.contains('loaf')) return Icons.bakery_dining;
  if (n.contains('mayo') || n.contains('mayonnaise')) return Icons.kitchen;
  if (n.contains('ketchup') || n.contains('sauce')) return Icons.kitchen;
  if (n.contains('canned')) return Icons.inventory_2;
  if (n.contains('chips') || n.contains('snack')) return Icons.fastfood;
  if (n.contains('egg')) return Icons.egg;
  return _iconForCategory(category);
}

Color _chipBgForCategory(String category) {
  switch (category) {
    case 'Beverages':
      return Colors.lightBlue.shade50;
    case 'Baked Goods':
      return Colors.orange.shade50;
    case 'Condiments':
      return Colors.yellow.shade50;
    case 'Canned Goods':
      return Colors.blueGrey.shade50;
    case 'Dairy':
      return Colors.indigo.shade50;
    case 'Produce':
      return Colors.green.shade50;
    case 'Snacks':
      return Colors.red.shade50;
    default:
      return Colors.grey.shade200;
  }
}

/// ===== Row UI (now with Shoppinglist-style circular icon chip) =====
class _ShoppingRowSL extends StatelessWidget {
  const _ShoppingRowSL({
    required this.item,
    required this.headerGreen,
    required this.grey,
    required this.onToggleInCart,
    required this.onToggleBookmark,
    required this.onDecrement,
    required this.onIncrement,
  });

  final _Item item;
  final Color headerGreen;
  final Color grey;
  final ValueChanged<bool?> onToggleInCart;
  final VoidCallback onToggleBookmark;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    final bool selected = item.inCart;

    Widget pulseIcon({
      required bool active,
      required IconData outlineIcon,
      required IconData filledIcon,
      required VoidCallback onPressed,
    }) {
      final bg = active ? headerGreen.withOpacity(.12) : Colors.transparent;
      final iconData = active ? filledIcon : outlineIcon;
      final iconColor = active ? headerGreen : grey;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: IconButton(
          icon: Icon(iconData, color: iconColor),
          onPressed: onPressed,
          splashRadius: 20,
        ),
      );
    }

    // Compose the "brand · size" subline
    String? subline;
    if ((item.brand != null && item.brand!.trim().isNotEmpty) ||
        (item.sizeText != null && item.sizeText!.trim().isNotEmpty)) {
      final b = (item.brand ?? '').trim();
      final s = (item.sizeText ?? '').trim();
      subline = (b.isNotEmpty && s.isNotEmpty)
          ? '$b · $s'
          : (b.isNotEmpty ? b : s);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Checkbox
        Checkbox(
          value: selected,
          onChanged: onToggleInCart,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),

        // === Shoppinglist-style circular green icon chip ===
        Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: headerGreen.withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            _iconForName(item.name, item.category),
            size: 18,
            color: headerGreen,
          ),
        ),

        // Texts
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    decoration: selected
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: selected ? Colors.grey.shade600 : Colors.black87,
                  ),
                ),
              ),
              if (subline != null) ...[
                const SizedBox(height: 1),
                Text(
                  subline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: (selected
                        ? Colors.black54
                        : Colors.black87.withOpacity(.75)),
                    height: 1.1,
                  ),
                ),
              ],
              const SizedBox(height: 2),
              Text(
                item.category,
                style: TextStyle(
                  fontSize: 12.5,
                  color: selected ? Colors.black45 : Colors.black54,
                ),
              ),
            ],
          ),
        ),

        IconButton(
          icon: Icon(
            item.bookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: item.bookmarked ? headerGreen : grey,
          ),
          onPressed: onToggleBookmark,
          splashRadius: 20,
          tooltip: item.bookmarked ? 'Unpin' : 'Pin (priority)',
        ),
        pulseIcon(
          active: item.decPulse,
          outlineIcon: Icons.remove_circle_outline_rounded,
          filledIcon: Icons.remove_circle,
          onPressed: onDecrement,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey, width: 2)),
          ),
          child: Text('${item.qty}', style: const TextStyle(fontSize: 16)),
        ),
        pulseIcon(
          active: item.incPulse,
          outlineIcon: Icons.add_circle_outline_rounded,
          filledIcon: Icons.add_circle,
          onPressed: onIncrement,
        ),
      ],
    );
  }
}

/// ====== Dialogs styled like your mockups ======
class _DeleteConfirmDialog extends StatelessWidget {
  const _DeleteConfirmDialog({
    required this.headerGreen,
    required this.title,
    required this.message,
  });

  final Color headerGreen;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEDEDED),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: headerGreen, width: 6),
        ),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: headerGreen,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14.5, color: Colors.black87),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PillButton(
                  label: 'Yes',
                  color: headerGreen,
                  textColor: Colors.white,
                  onTap: () => Navigator.of(context).pop(true),
                ),
                const SizedBox(width: 12),
                _PillButton(
                  label: 'No',
                  color: const Color(0xFF9E9E9E),
                  textColor: Colors.white,
                  onTap: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog({
    required this.headerGreen,
    required this.title,
    required this.message,
  });

  final Color headerGreen;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    // Auto-close after a short delay
    Future.delayed(const Duration(milliseconds: 900), () {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    });

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEDEDED),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: headerGreen, width: 6),
        ),
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: headerGreen,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14.5, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            label,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _EditQtyButton extends StatelessWidget {
  const _EditQtyButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color border = enabled
        ? const Color(0xFF9E9E9E)
        : Colors.grey.shade300;
    final Color fg = enabled ? const Color(0xFF9E9E9E) : Colors.grey.shade300;
    return InkResponse(
      radius: 20,
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: border, width: 1.6),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: fg),
      ),
    );
  }
}
