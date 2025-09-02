import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

/// In-memory singleton store to hold the "current/main" shopping list.
class MainShoppingListStore extends ChangeNotifier {
  MainShoppingListStore._();
  static final MainShoppingListStore instance = MainShoppingListStore._();

  String? currentListTitle;
  List<_Item> currentItems = const [];

  void setMainList({required String title, required List<_Item> items}) {
    currentListTitle = title;
    // Deep(ish) copy so edits on the source page don’t mutate the main list
    currentItems = items.map((e) => e.copy()).toList(growable: false);
    notifyListeners();
  }

  bool get hasMain => currentListTitle != null && currentItems.isNotEmpty;
}

class ListItemsPage extends StatefulWidget {
  const ListItemsPage({super.key, required this.listTitle});

  final String listTitle;

  @override
  State<ListItemsPage> createState() => _ListItemsPageState();
}

class _ListItemsPageState extends State<ListItemsPage> {
  final Color headerGreen = const Color(0xFF2E7D32);
  final Color softCream = const Color(0xFFFFFBE6);
  final Color sep = const Color.fromARGB(255, 230, 230, 230);

  // Protects against double navigations
  bool _navBusy = false;

  /// Safely pop after dialogs/animations without hitting !debugLocked.
  /// - Defers to next frame.
  /// - Pops if possible; else tries maybePop.
  /// - ALWAYS clears _navBusy, even if nothing popped.
  void _safePop([Object? result]) {
    if (_navBusy) return;
    _navBusy = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!mounted) return;
        final navigator = Navigator.of(context);
        bool popped = false;
        if (navigator.canPop()) {
          navigator.pop(result);
          popped = true;
        } else {
          popped = await navigator.maybePop(result);
        }
      } finally {
        if (mounted) {
          Future.microtask(() => _navBusy = false);
        }
      }
    });
  }

  // Simple categories for editing dialog
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

  // Items use the same shape as the Shopping List format (brand + sizeText are optional)
  final items = <_Item>[
    _Item(
      id: 'oj1',
      name: 'Orange Juice',
      brand: 'Fruit Soda Orange',
      sizeText: '1L',
      category: 'Beverages',
      qty: 2,
    ),
    _Item(
      id: 'wb1',
      name: 'Bread',
      brand: 'Gardenia Wheat Bread',
      category: 'Baked Goods',
      qty: 1,
    ),
    _Item(
      id: 'mayo1',
      name: 'Mayonnaise',
      brand: 'Ladies Choice Mayonnaise',
      category: 'Condiments',
      qty: 1,
    ),
  ];

  // --- Bookmark priority (same behavior as Shopping List) ---
  void _reorderByBookmark() {
    final bookmarked = <_Item>[];
    final others = <_Item>[];
    for (final it in items) {
      (it.bookmarked ? bookmarked : others).add(it);
    }
    items
      ..clear()
      ..addAll(bookmarked)
      ..addAll(others);
  }

  // ---------------- LIST-LEVEL DELETE POPUPS ----------------
  Future<bool?> _showDeleteListConfirmDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 320,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
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
                  Text(
                    'Delete list',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: headerGreen,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Are you sure you want to delete this list?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14.5, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Yes
                      InkWell(
                        onTap: () => Navigator.of(context).pop(true),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: headerGreen,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Text(
                            'Yes',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // No
                      InkWell(
                        onTap: () => Navigator.of(context).pop(false),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9E9E9E),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Text(
                            'No',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showListDeleteSuccessDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 320,
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
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
                  Text(
                    'Success!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: headerGreen,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'List deleted.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14.5, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
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

  Future<void> _confirmAndDeleteList() async {
    final ok = await _showDeleteListConfirmDialog();
    if (ok == true) {
      items.clear();
      setState(() {});
      await _showListDeleteSuccessDialog();
      _safePop(true); // return true = list deleted
    }
  }

  // ---------- NEW: Set-as-Main flow ----------
  Future<void> _confirmUseAsMain() async {
    final makeMain = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 320,
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
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
                  Text(
                    'Use as current shopping list?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: headerGreen,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This will replace your existing main shopping list.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14.5, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).pop(true),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: headerGreen,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Text(
                            'Yes',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(false),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9E9E9E),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Text(
                            'No',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (makeMain == true) {
      MainShoppingListStore.instance.setMainList(
        title: widget.listTitle,
        items: items,
      );
      _showSnack('“${widget.listTitle}” is now your current shopping list');
      _safePop({'setMain': true, 'title': widget.listTitle});
    }
  }

  // ---------- Edit Item Dialog (lightweight, standard Dropdown) ----------
  Future<void> _showEditItemDialog(_Item item) async {
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
                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          decoration: deco(),
                          isExpanded: true,
                          items: _categories
                              .map(
                                (c) => DropdownMenuItem<String>(
                                  value: c,
                                  child: Text(c),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setLocal(() => selectedCategory = v),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Select a category'
                              : null,
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
                                _showSnack('Item updated');
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

  void _showSnack(String msg) {
    final m = ScaffoldMessenger.of(context);
    m.hideCurrentSnackBar();
    m.showSnackBar(SnackBar(content: Text(msg)));
  }

  // Small helper to trigger a short “pressed” pulse (optional)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softCream,
      body: Column(
        children: [
          // ===== Custom Header with LIST delete icon + USE AS MAIN =====
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
                  // Back button should feel immediate and reliable
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
                // NEW: Use-as-main icon
                IconButton(
                  tooltip: 'Use as current shopping list',
                  icon: const Icon(
                    Icons.shopping_cart_checkout,
                    color: Colors.white,
                  ),
                  onPressed: _confirmUseAsMain,
                ),
                // Existing: list-level delete icon
                IconButton(
                  tooltip: 'Delete list',
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  onPressed: _confirmAndDeleteList,
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: sep),

          // ===== Items list (keeps per-item slide actions as before) =====
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
                    extentRatio: 0.40, // room for Edit + Delete
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Deleted "${removed.name}"'),
                              action: SnackBarAction(
                                label: 'UNDO',
                                onPressed: () => setState(() {
                                  final safeIndex = removedIndex.clamp(
                                    0,
                                    items.length,
                                  );
                                  items.insert(safeIndex, removed);
                                }),
                              ),
                            ),
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
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: _ListRow(
                      item: item,
                      headerGreen: headerGreen,
                      onToggleInCart: (v) =>
                          setState(() => item.inCart = v ?? false),
                      onToggleBookmark: () {
                        setState(() {
                          item.bookmarked = !item.bookmarked;
                          _reorderByBookmark(); // prioritize bookmarked
                        });
                      },
                      onDecrement: () {
                        setState(
                          () => item.qty = (item.qty > 0) ? item.qty - 1 : 0,
                        );
                        _pulseButton(item, isInc: false);
                      },
                      onIncrement: () {
                        setState(() => item.qty += 1);
                        _pulseButton(item, isInc: true);
                      },
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

/* ======================= Item model ======================= */
class _Item {
  final String id;
  String name;
  String? brand; // optional
  String? sizeText; // optional e.g. 1L, 150g
  String category;
  int qty;
  bool inCart;
  bool bookmarked;
  bool incPulse;
  bool decPulse;

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

  _Item copy() => _Item(
    id: id,
    name: name,
    category: category,
    brand: brand,
    sizeText: sizeText,
    qty: qty,
    inCart: inCart,
    bookmarked: bookmarked,
    incPulse: false,
    decPulse: false,
  );
}

/* ======================= Row UI (with selected indicator) ======================= */
class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.item,
    required this.headerGreen,
    required this.onToggleInCart,
    required this.onToggleBookmark,
    required this.onDecrement,
    required this.onIncrement,
  });

  final _Item item;
  final Color headerGreen;
  final ValueChanged<bool?> onToggleInCart;
  final VoidCallback onToggleBookmark;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    final grey = Colors.grey[700];
    final bool selected = item.inCart; // <-- visual selection state

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

    final nameStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      decoration: selected ? TextDecoration.lineThrough : TextDecoration.none,
      color: selected ? Colors.grey.shade600 : Colors.black,
    );
    final subStyle = TextStyle(
      fontSize: 13.5,
      color: selected ? Colors.grey.shade500 : Colors.black87.withOpacity(.75),
      height: 1.1,
    );
    final catStyle = TextStyle(
      fontSize: 12.5,
      color: selected ? Colors.grey.shade500 : Colors.black54,
    );

    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Checkbox(
              value: item.inCart,
              onChanged: onToggleInCart,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name (not tappable; we use slide actions for edit)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: nameStyle,
                    ),
                  ),
                  if (subline != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: subStyle,
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(item.category, style: catStyle),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                item.bookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: item.bookmarked
                    ? (selected ? Colors.grey.shade500 : headerGreen)
                    : (selected ? Colors.grey.shade500 : grey),
              ),
              onPressed: onToggleBookmark,
              splashRadius: 20,
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
                border: Border(
                  bottom: BorderSide(color: Colors.grey, width: 2),
                ),
              ),
              child: Text(
                '${item.qty}',
                style: TextStyle(
                  fontSize: 16,
                  color: selected ? Colors.grey.shade600 : Colors.black,
                ),
              ),
            ),
            pulseIcon(
              active: item.incPulse,
              outlineIcon: Icons.add_circle_outline_rounded,
              filledIcon: Icons.add_circle,
              onPressed: onIncrement,
            ),
          ],
        ),
        if (selected)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: Container(color: Colors.white.withOpacity(0.45)),
            ),
          ),
      ],
    );
  }
}
