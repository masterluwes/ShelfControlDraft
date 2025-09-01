import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

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
  // Deeper green for "Reuse previous list" (per your UI)
  final Color darkGreen = const Color(0xFF2F4F3A);

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

  final items = <ShoppingItem>[
    ShoppingItem(
      id: 'oj1',
      name: 'Orange Juice (1L)',
      category: 'Beverages',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/0/0b/Orange_juice_1.jpg',
      qty: 2,
    ),
    ShoppingItem(
      id: 'wb1',
      name: 'Wheat Bread',
      category: 'Baked Goods',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/d/d0/Sliced_Wholemeal_Bread.jpg',
      qty: 1,
    ),
    ShoppingItem(
      id: 'mayo1',
      name: 'Mayonnaise',
      category: 'Condiments',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/5/5a/Mayonnaise_%281%29.jpg',
      qty: 1,
    ),
    ShoppingItem(
      id: 'canned1',
      name: 'Canned Meats',
      category: 'Canned Goods',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/4/47/Spam_cans.JPG',
      qty: 5,
    ),
    ShoppingItem(
      id: 'mush1',
      name: 'Mushrooms',
      category: 'Canned Goods',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/1/1e/Canned_mushrooms.jpg',
      qty: 2,
    ),

    // -------- Added items --------
    ShoppingItem(
      id: 'milk1',
      name: 'Fresh Milk (1L)',
      category: 'Dairy',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/0/0b/Milk_glass.jpg',
      qty: 2,
    ),
    ShoppingItem(
      id: 'cheese1',
      name: 'Cheddar Cheese',
      category: 'Dairy',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/0/0b/Red_cheddar.jpg',
      qty: 1,
    ),
    ShoppingItem(
      id: 'apple1',
      name: 'Red Apples',
      category: 'Produce',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/1/15/Red_Apple.jpg',
      qty: 6,
    ),
    ShoppingItem(
      id: 'banana1',
      name: 'Bananas',
      category: 'Produce',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/8/8a/Banana-Single.jpg',
      qty: 5,
    ),
    ShoppingItem(
      id: 'chips1',
      name: 'Potato Chips',
      category: 'Snacks',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/6/69/Potato-Chips.jpg',
      qty: 3,
    ),
    ShoppingItem(
      id: 'cookies1',
      name: 'Chocolate Chip Cookies',
      category: 'Snacks',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/7/70/Chocolate_Chip_Cookies_-_kimberlykv.jpg',
      qty: 2,
    ),
    ShoppingItem(
      id: 'water1',
      name: 'Bottled Water (500ml)',
      category: 'Beverages',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/3/3a/Water_bottle.jpg',
      qty: 12,
    ),
    ShoppingItem(
      id: 'rice1',
      name: 'White Rice (5kg)',
      category: 'Other',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/6/6f/Long_grain_white_rice.jpg',
      qty: 1,
    ),
    ShoppingItem(
      id: 'egg1',
      name: 'Eggs (Dozen)',
      category: 'Dairy',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/b/b9/Chicken_eggs.jpg',
      qty: 1,
    ),
  ];

  // ---------- toast-style snack ----------
  void _showTopSnack(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    final topSafe = MediaQuery.of(context).padding.top;
    final topMargin = topSafe + 64 + 8;

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.up,
        margin: EdgeInsets.fromLTRB(16, topMargin, 16, 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ---------- limit banner ----------
  Future<void> _showLimitDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withAlpha(38),
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
                    color: headerGreen.withAlpha(64),
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

  void _reusePreviousList() => _showTopSnack('Reuse previous list tapped');
  void _shareList() => _showTopSnack('Share list tapped');

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
    String? selectedCategory;

    InputDecoration deco() => InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withAlpha(38)),
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
                color: headerGreen.withAlpha(191),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: headerGreen.withAlpha(77),
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
                              color: Colors.black.withAlpha(38),
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
                        onChanged: (v) => setLocal(() => selectedCategory = v),
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
                                color: Colors.black.withAlpha(15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          offset: const Offset(0, 12), // drop a bit lower
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
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ---------- Edit Item Dialog (tap name text) ----------
  Future<void> _showEditItemDialog(ShoppingItem item) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: item.name);
    String? selectedCategory = item.category;

    InputDecoration deco() => InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withAlpha(38)),
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
                color: headerGreen.withAlpha(191),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: headerGreen.withAlpha(77),
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
                              color: Colors.black.withAlpha(38),
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
                        onChanged: (v) => setLocal(() => selectedCategory = v),
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
                                color: Colors.black.withAlpha(15),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Divider(height: 1, thickness: 1, color: sep),
        Container(
          width: double.infinity,
          color: softCream,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shopping List',
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
                    label: 'Reuse previous list',
                    onTap: _reusePreviousList,
                    color: darkGreen, // darker per UI
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _shareList,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Icon(
                        Icons.ios_share,
                        color: headerGreen,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: sep),
        // List
        Expanded(
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, index) =>
                Divider(height: 1, thickness: 1, color: sep),
            itemBuilder: (context, index) {
              final item = items[index];

              // === SWIPE TO DELETE (like Pantry) ===
              return Dismissible(
                key: ValueKey(item.id),
                direction: DismissDirection.endToStart, // swipe left to delete
                background: _deleteBg(), // underlay when swiping
                onDismissed: (_) {
                  final removed = item;
                  final removedIndex = index;
                  setState(() => items.removeAt(index));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Deleted "${removed.name}"'),
                      action: SnackBarAction(
                        label: 'UNDO',
                        onPressed: () => setState(() {
                          items.insert(removedIndex, removed);
                        }),
                      ),
                    ),
                  );
                },
                child: Container(
                  color: Colors.white,
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
                      setState(() {
                        item.qty = (item.qty > 0) ? item.qty - 1 : 0;
                      });
                      _pulseButton(item, isInc: false);
                    },
                    onIncrement: () {
                      setState(() {
                        item.qty += 1;
                      });
                      _pulseButton(item, isInc: true);
                    },
                    onDelete: () {}, // not used anymore (kept for signature)
                    onEdit: () => _showEditItemDialog(item),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Red delete background when swiping left
  Widget _deleteBg() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.red.shade600,
      child: const Icon(Icons.delete, color: Colors.white, size: 26),
    );
  }
}

// ======================= Model =======================
class ShoppingItem {
  final String id;
  String name;
  String category;
  final String? imageUrl;
  int qty;
  bool inCart;
  bool bookmarked;

  // transient UI flags for pressed-state pulse
  bool incPulse;
  bool decPulse;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
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

    // Quick rounded pulse icon widget
    Widget pulseIcon({
      required bool active,
      required IconData outlineIcon,
      required IconData filledIcon,
      required VoidCallback onPressed,
    }) {
      final bg = active ? headerGreen.withAlpha(31) : Colors.transparent;
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

    // Base row content (no trailing delete icon anymore)
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(
          value: item.inCart,
          onChanged: onToggleInCart,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),

        // Name + category (tap name to edit)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    item.name,
                    maxLines: 2, // allow long names
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.category,
                style: const TextStyle(fontSize: 12.5, color: Colors.black54),
              ),
            ],
          ),
        ),

        // Bookmark → green when active
        IconButton(
          icon: Icon(
            item.bookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: item.bookmarked ? headerGreen : grey,
          ),
          onPressed: onToggleBookmark,
          splashRadius: 20,
        ),

        // Decrement with pulse
        pulseIcon(
          active: item.decPulse,
          outlineIcon: Icons.remove_circle_outline_rounded,
          filledIcon: Icons.remove_circle,
          onPressed: onDecrement,
        ),

        // Quantity (underlined)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey, width: 2)),
          ),
          child: Text('${item.qty}', style: const TextStyle(fontSize: 16)),
        ),

        // Increment with pulse
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
