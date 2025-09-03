import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:guests_main/pages/viewalllists.dart';
import 'package:guests_main/pages/listitemspage.dart'
    show MainShoppingListStore;

class Shoppinglist extends StatefulWidget {
  const Shoppinglist({super.key});
  @override
  State<Shoppinglist> createState() => _ShoppinglistState();
}

class _ShoppinglistState extends State<Shoppinglist> {
  // Palette
  final Color headerGreen = const Color(0xFF2E7D32);
  final Color softCream = const Color(0xFFFFFBE6);
  final Color sep = const Color.fromARGB(255, 230, 230, 230);
  // Deeper green for "View All List"
  final Color darkGreen = const Color(0xFF2F4F3A);

  // Header key so we can anchor SnackBars right under it (no layout shift)
  final GlobalKey _headerKey = GlobalKey();

  // ===== current title reflects the “Main” list when present =====
  String _currentTitle = 'Shopping List';

  // store listener for live updates from ListItemsPage
  VoidCallback? _storeListener;

  // Guest limit
  static const int maxGuestItems = 15;

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

  // Shopping list items (no thumbnails/icons)
  final items = <ShoppingItem>[
    ShoppingItem(
      id: 'oj1',
      name: 'Orange Juice',
      brand: 'Fruit Soda Orange',
      sizeText: '1L',
      category: 'Beverages',
      imageUrl: null,
      qty: 2,
    ),
    ShoppingItem(
      id: 'wb1',
      name: 'Bread',
      brand: 'Gardenia Wheat Bread',
      sizeText: null,
      category: 'Baked Goods',
      imageUrl: null,
      qty: 1,
    ),
    ShoppingItem(
      id: 'mayo1',
      name: 'Mayonnaise',
      brand: 'Ladies Choice Mayonnaise',
      sizeText: null,
      category: 'Condiments',
      imageUrl: null,
      qty: 1,
    ),
    ShoppingItem(
      id: 'canned1',
      name: 'Canned Meats',
      brand: 'Argentina',
      sizeText: '150g',
      category: 'Canned Goods',
      imageUrl: null,
      qty: 5,
    ),
    ShoppingItem(
      id: 'mush1',
      name: 'Mushrooms',
      brand: 'Jolly',
      sizeText: '400g',
      category: 'Canned Goods',
      imageUrl: null,
      qty: 2,
    ),
    // Added examples
    ShoppingItem(
      id: 'milk1',
      name: 'Fresh Milk',
      brand: 'Selecta Fortified',
      sizeText: '1L',
      category: 'Dairy',
      imageUrl: null,
      qty: 2,
    ),
    ShoppingItem(
      id: 'cheese1',
      name: 'Cheddar Cheese',
      brand: 'Eden',
      sizeText: '165g',
      category: 'Dairy',
      imageUrl: null,
      qty: 1,
    ),
    ShoppingItem(
      id: 'apple1',
      name: 'Red Apples',
      brand: null,
      sizeText: '6 pcs',
      category: 'Produce',
      imageUrl: null,
      qty: 6,
    ),
    ShoppingItem(
      id: 'banana1',
      name: 'Bananas',
      brand: null,
      sizeText: '5 pcs',
      category: 'Produce',
      imageUrl: null,
      qty: 5,
    ),
    ShoppingItem(
      id: 'chips1',
      name: 'Potato Chips',
      brand: 'Lay’s',
      sizeText: '150g',
      category: 'Snacks',
      imageUrl: null,
      qty: 3,
    ),
    ShoppingItem(
      id: 'cookies1',
      name: 'Chocolate Chip Cookies',
      brand: 'Chips Ahoy!',
      sizeText: '128g',
      category: 'Snacks',
      imageUrl: null,
      qty: 2,
    ),
    ShoppingItem(
      id: 'water1',
      name: 'Bottled Water',
      brand: 'Nature Spring',
      sizeText: '500ml',
      category: 'Beverages',
      imageUrl: null,
      qty: 12,
    ),
    ShoppingItem(
      id: 'rice1',
      name: 'White Rice',
      brand: 'Sinandomeng',
      sizeText: '5kg',
      category: 'Other',
      imageUrl: null,
      qty: 1,
    ),
    ShoppingItem(
      id: 'egg1',
      name: 'Eggs',
      brand: null,
      sizeText: '1 dozen',
      category: 'Dairy',
      imageUrl: null,
      qty: 1,
    ),
  ];

  // ===== Apply the “Main” list from the shared store =====
  void _applyMainStore(MainShoppingListStore store, {bool showToast = false}) {
    if (!store.hasMain) return;
    final incoming = store.currentItems;
    _currentTitle = store.currentListTitle ?? 'Shopping List';
    items
      ..clear()
      ..addAll(incoming.map(_mapFromStoreItem));
    _reorderByBookmark();
    if (showToast) {
      _showTopSnack('Loaded main list: “$_currentTitle”');
    }
    setState(() {});
  }

  // Map `_Item` (from ListItemsPage) -> `ShoppingItem` (this page)
  ShoppingItem _mapFromStoreItem(dynamic it) => ShoppingItem(
    id: it.id,
    name: it.name,
    brand: it.brand,
    sizeText: it.sizeText,
    category: it.category,
    imageUrl: null,
    qty: it.qty,
    inCart: it.inCart,
    bookmarked: it.bookmarked,
  );

  // ---------- Helpers: compute top margin under header ----------
  double _topSnackMargin() {
    final messengerTop = MediaQuery.of(context).padding.top;
    final render = _headerKey.currentContext?.findRenderObject() as RenderBox?;
    final headerHeight = render?.size.height ?? 0;
    return messengerTop + headerHeight + 8;
  }

  // ---------- toast-style snack (top, floating, no layout shift) ----------
  void _showTopSnack(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.up,
        margin: EdgeInsets.fromLTRB(16, _topSnackMargin(), 16, 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Same as above but with action (for UNDO etc.)
  void _showTopSnackWithAction({
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
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
        action: SnackBarAction(label: actionLabel, onPressed: onAction),
      ),
    );
  }

  // ---------- limit banner ----------
  Future<void> _showLimitDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.15),
      builder: (_) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 320,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFE6E6E6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: headerGreen, width: 5),
                boxShadow: [
                  BoxShadow(
                    color: headerGreen.withOpacity(.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    'Shopping list limit exceeded!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: headerGreen,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text.rich(
                    TextSpan(
                      text: 'Register',
                      style: const TextStyle(
                        fontSize: 14.5,
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                      children: const [
                        TextSpan(
                          text: ' or ',
                          style: TextStyle(fontWeight: FontWeight.normal),
                        ),
                        TextSpan(
                          text: 'Login',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text: ' to add more items.',
                          style: TextStyle(fontWeight: FontWeight.normal),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 26),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'OK',
                      style: TextStyle(
                        color: headerGreen,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _reorderByBookmark() {
    final bookmarked = <ShoppingItem>[];
    final others = <ShoppingItem>[];
    for (final it in items) {
      (it.bookmarked ? bookmarked : others).add(it);
    }
    items
      ..clear()
      ..addAll(bookmarked)
      ..addAll(others);
  }

  // ---------- Add Item Dialog ----------
  Future<void> _showAddItemDialog() async {
    if (items.length >= maxGuestItems) {
      _showLimitDialog();
      return;
    }

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
                                if (items.length >= maxGuestItems) {
                                  _showLimitDialog();
                                  return;
                                }
                                final id =
                                    'id_${DateTime.now().millisecondsSinceEpoch}';
                                setState(() {
                                  items.insert(
                                    0,
                                    ShoppingItem(
                                      id: id,
                                      name: nameCtrl.text.trim(),
                                      brand: brandCtrl.text.trim().isEmpty
                                          ? null
                                          : brandCtrl.text.trim(),
                                      sizeText: sizeCtrl.text.trim().isEmpty
                                          ? null
                                          : sizeCtrl.text.trim(),
                                      category: selectedCategory!,
                                      imageUrl: null,
                                      qty: 1,
                                    ),
                                  );
                                  _reorderByBookmark();
                                });
                                Navigator.of(ctx).pop();
                                _showTopSnack('Item added');
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

  // ---------- Edit Item Dialog ----------
  Future<void> _showEditItemDialog(ShoppingItem item) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: item.name);
    final brandCtrl = TextEditingController(text: item.brand ?? '');
    final sizeCtrl = TextEditingController(text: item.sizeText ?? '');
    String? selectedCategory = item.category;

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
                          'Edit Item',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: headerGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
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
                          'Size / Weight (optional)',
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
                                setState(() {
                                  item
                                    ..name = nameCtrl.text.trim()
                                    ..brand = brandCtrl.text.trim().isEmpty
                                        ? null
                                        : brandCtrl.text.trim()
                                    ..sizeText = sizeCtrl.text.trim().isEmpty
                                        ? null
                                        : sizeCtrl.text.trim()
                                    ..category = selectedCategory!;
                                });
                                Navigator.of(ctx).pop();
                                _showTopSnack('Item updated');
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
                                  'Save',
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

  // Small helper to trigger a short "pressed" pulse for +/-"
  Future<void> _pulseButton(ShoppingItem item, {required bool isInc}) async {
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

  // ===== hook up to the store =====
  @override
  void initState() {
    super.initState();
    final store = MainShoppingListStore.instance;
    if (store.hasMain) {
      _applyMainStore(store);
    }
    _storeListener = () {
      _applyMainStore(store, showToast: true);
    };
    store.addListener(_storeListener!);
  }

  @override
  void dispose() {
    final store = MainShoppingListStore.instance;
    if (_storeListener != null) {
      store.removeListener(_storeListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Divider(height: 1, thickness: 1, color: sep),
        Container(
          key: _headerKey, // <-- anchor for top snackbars
          width: double.infinity,
          color: softCream,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // current main list title if available
              Text(
                _currentTitle,
                style: TextStyle(
                  color: const Color(0xFF347928),
                  fontFamily: 'Inter',
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _GreenPillButton(
                    label: 'Add new Item',
                    onTap: _showAddItemDialog,
                    color: headerGreen,
                  ),
                  const SizedBox(width: 10),
                  _GreenPillButton(
                    label: 'View All List',
                    color: darkGreen,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const Viewalllist()),
                      );
                    },
                  ),
                  const Spacer(),
                  // (Export button removed)
                ],
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: sep),

        // Main list (no suggestions, no capture boundary)
        Expanded(
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, thickness: 1, color: sep),
            itemBuilder: (context, index) {
              final item = items[index];

              return Slidable(
                key: ValueKey(item.id),
                closeOnScroll: true,
                endActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  extentRatio: 0.40,
                  children: [
                    SlidableAction(
                      onPressed: (_) => _showEditItemDialog(item),
                      icon: Icons.edit,
                      label: 'Edit',
                      backgroundColor: headerGreen,
                      foregroundColor: Colors.white,
                      borderRadius: BorderRadius.circular(0),
                    ),
                    SlidableAction(
                      onPressed: (_) {
                        final removed = item;
                        final removedIndex = index;
                        setState(() => items.removeAt(removedIndex));

                        _showTopSnackWithAction(
                          message: 'Deleted "${removed.name}"',
                          actionLabel: 'UNDO',
                          onAction: () => setState(() {
                            final safeIndex = removedIndex.clamp(
                              0,
                              items.length,
                            );
                            items.insert(safeIndex, removed);
                          }),
                        );
                      },
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      borderRadius: BorderRadius.circular(0),
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
                        child: _ShoppingRow(
                          item: item,
                          headerGreen: headerGreen,
                          onToggleInCart: (v) =>
                              setState(() => item.inCart = v ?? false),
                          onToggleBookmark: () {
                            setState(() {
                              item.bookmarked = !item.bookmarked;
                              _reorderByBookmark();
                            });
                          },
                          onDecrement: () {
                            setState(
                              () =>
                                  item.qty = (item.qty > 0) ? item.qty - 1 : 0,
                            );
                            _pulseButton(item, isInc: false);
                          },
                          onIncrement: () {
                            setState(() => item.qty += 1);
                            _pulseButton(item, isInc: true);
                          },
                          onDelete: () {},
                          onEdit: () {},
                        ),
                      ),
                      if (item.inCart)
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
    );
  }
}

// ======================= Model =======================
class ShoppingItem {
  final String id;
  String name;
  String? brand;
  String? sizeText; // e.g., 150g, 1L, 5kg, 6 pcs
  String category;
  final String? imageUrl;
  int qty;
  bool inCart;
  bool bookmarked;
  bool incPulse;
  bool decPulse;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    this.brand,
    this.sizeText,
    this.qty = 1,
    this.inCart = false,
    this.bookmarked = false,
    this.incPulse = false,
    this.decPulse = false,
  });
}

// ======================= Row =======================
class _ShoppingRow extends StatelessWidget {
  const _ShoppingRow({
    required this.item,
    required this.headerGreen,
    required this.onToggleInCart,
    required this.onToggleBookmark,
    required this.onDecrement,
    required this.onIncrement,
    required this.onDelete,
    required this.onEdit,
  });

  final ShoppingItem item;
  final Color headerGreen;
  final ValueChanged<bool?> onToggleInCart;
  final VoidCallback onToggleBookmark;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onDelete; // (unused now; kept for compatibility)
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final grey = Colors.grey[700];
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

        // Keep spacing where the icon used to be
        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name with visual indicator when selected
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

// ======================= Pills =======================
class _GreenPillButton extends StatelessWidget {
  const _GreenPillButton({
    required this.label,
    required this.onTap,
    required this.color,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Roboto',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
