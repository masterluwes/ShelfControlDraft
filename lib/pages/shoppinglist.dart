import 'package:flutter/material.dart';

class Shoppinglist extends StatefulWidget {
  const Shoppinglist({super.key});
  @override
  State<Shoppinglist> createState() => _ShoppinglistState();
}

class _ShoppinglistState extends State<Shoppinglist> {
  // Palette
  final Color headerGreen = const Color(0xFF2E7D32);
  final Color softCream = const Color(0xFFFFFBE6);
  final Color rowAlt = const Color(0xFFF7EFD3);

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
  ];

  // ---------- toast-style snack that doesn't move the FAB ----------
  void _showTopSnack(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    final topSafe = MediaQuery.of(context).padding.top;
    // Position just under the app bar; tweak 64 if your app bar height differs
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

  void _reusePreviousList() {
    _showTopSnack('Reuse previous list tapped');
  }

  void _shareList() {
    _showTopSnack('Share list tapped');
  }

  void _deleteItem(ShoppingItem item) {
    final index = items.indexWhere((e) => e.id == item.id);
    if (index < 0) return;
    final removed = items.removeAt(index);
    setState(() {});
    // You can also switch this to _showTopSnack with an action if you
    // want ZERO FAB movement everywhere.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${removed.name}"'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () => setState(() => items.insert(index, removed)),
        ),
      ),
    );
  }

  // ---------- Add Item Dialog (no image placeholder) ----------
  Future<void> _showAddItemDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    String? selectedCategory;

    InputDecoration deco() => InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: .15)),
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
                color: headerGreen.withValues(alpha: .75),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: headerGreen.withValues(alpha: .30),
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
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        items: _categories
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (v) => setLocal(() => selectedCategory = v),
                        decoration: deco(),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Please select a category'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Add
                          InkWell(
                            onTap: () {
                              if (!formKey.currentState!.validate()) return;
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
                          // Cancel
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

  @override
  Widget build(BuildContext context) {
    // Body only; rendered inside MainDashboard scaffold
    return Column(
      children: [
        // Header row
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
                  color: headerGreen,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
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
                    onTap: _reusePreviousList, // top-floating snackbar
                    color: headerGreen.withValues(alpha: 0.90),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _shareList, // top-floating snackbar
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
        const Divider(height: 1),
        // List
        Expanded(
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              final Color altBg = index.isOdd
                  ? rowAlt.withValues(alpha: 0.25)
                  : Colors.white;
              return Container(
                color: altBg,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: _ShoppingRow(
                  item: item,
                  headerGreen: headerGreen,
                  onToggleInCart: (v) =>
                      setState(() => item.inCart = v ?? false),
                  onToggleBookmark: () =>
                      setState(() => item.bookmarked = !item.bookmarked),
                  onDecrement: () => setState(
                    () => item.qty = (item.qty > 0) ? item.qty - 1 : 0,
                  ),
                  onIncrement: () => setState(() => item.qty += 1),
                  onDelete: () => _deleteItem(item),
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
  final String name;
  final String category;
  final String? imageUrl; // nullable; if null, no thumbnail shown
  int qty;
  bool inCart; // selected / already in cart
  bool bookmarked;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    this.qty = 1,
    this.inCart = false,
    this.bookmarked = false,
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
  });

  final ShoppingItem item;
  final Color headerGreen;
  final ValueChanged<bool?> onToggleInCart;
  final VoidCallback onToggleBookmark;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final grey = Colors.grey[700];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Checkbox -> marks item as selected / already in cart
        Checkbox(
          value: item.inCart,
          onChanged: onToggleInCart,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),

        // Name + category
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
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

        // Right-side icons: bookmark, - , qty(underlined), + , delete
        IconButton(
          icon: Icon(
            item.bookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: grey,
          ),
          onPressed: onToggleBookmark,
          splashRadius: 20,
        ),
        IconButton(
          icon: Icon(Icons.remove_circle_outline_rounded, color: grey),
          onPressed: onDecrement,
          splashRadius: 20,
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey, width: 2)),
          ),
          child: Text(
            '${item.qty}',
            style: const TextStyle(fontSize: 16), // single number only
          ),
        ),

        IconButton(
          icon: Icon(Icons.add_circle_outline_rounded, color: grey),
          onPressed: onIncrement,
          splashRadius: 20,
        ),

        IconButton(
          icon: Icon(Icons.delete, color: grey),
          onPressed: onDelete,
          splashRadius: 20,
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
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}
