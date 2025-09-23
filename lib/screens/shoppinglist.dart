import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shelf_control/models/shopping_list_item_model.dart';
import 'package:shelf_control/models/shopping_list_model.dart';
import 'package:shelf_control/screens/viewalllists.dart' hide Text, Navigator;
import 'package:shelf_control/services/shopping_list_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:provider/provider.dart'; // Import provider
import 'package:shelf_control/services/firestore_service.dart'; // Import FirestoreService

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

  // For PNG export — wrap the list with a RepaintBoundary
  final GlobalKey _captureKey = GlobalKey();

  String _currentTitle = 'Shopping List';
  ShoppingListModel? _activeList;
  String? _householdId;
  final ShoppingListService _shoppingListService = ShoppingListService();

  // Guest limit
  static const int maxGuestItems = 15;

  // Listener for FirestoreService changes
  late VoidCallback _firestoreServiceListener;

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

  List<ShoppingListItemModel> items = [];

  // ------- Suggestions dropdown (collapsible) -------
  bool _suggestionsOpen = true;

  /// Suggestions now include optional brand & size
  List<_Suggestion> _suggestions = [];

  @override
  void initState() {
    super.initState();
    // Initialize the listener
    _firestoreServiceListener = () {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      if (_householdId != firestoreService.selectedHouseholdId) {
        setState(() {
          _householdId = firestoreService.selectedHouseholdId;
        });
        _fetchHouseholdAndListsAndSuggestions();
      }
    };

    // Add the listener
    Provider.of<FirestoreService>(context, listen: false).addListener(_firestoreServiceListener);

    // Initial fetch
    _fetchHouseholdAndListsAndSuggestions();
  }

  @override
  void dispose() {
    // Remove the listener
    Provider.of<FirestoreService>(context, listen: false).removeListener(_firestoreServiceListener);
    super.dispose();
  }

  Future<void> _fetchHouseholdAndListsAndSuggestions() async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _householdId = firestoreService.selectedHouseholdId; // Get householdId from service

    if (_householdId != null) {
      // Fetch active list
      var snapshot = await FirebaseFirestore.instance
          .collection('shoppingLists')
          .where('householdId', isEqualTo: _householdId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      if (!mounted) return;
      setState(() {
        if (snapshot.docs.isNotEmpty) {
          _activeList = ShoppingListModel.fromFirestore(snapshot.docs.first);
          _currentTitle = _activeList!.name;
          items = _activeList!.items;
          _reorderByBookmark();
        } else {
          _activeList = null;
          _currentTitle = 'Shopping List';
          items = [];
        }
      });

      // Fetch suggestions
      await _fetchSuggestions();
    } else {
      if (!mounted) return;
      setState(() {
        _activeList = null;
        _currentTitle = 'Shopping List';
        items = [];
        _suggestions = [];
      });
    }
  }

  Future<void> _fetchSuggestions() async {
    if (_householdId != null) {
      List<ShoppingListItemModel> generatedSuggestions = await _shoppingListService.generateHassleFreeSuggestions(_householdId!);
      setState(() {
        _suggestions = generatedSuggestions.map((item) => _Suggestion(
          name: item.name,
          brand: item.brand,
          sizeText: item.netWeight,
          note: 'Suggested', // You might want to refine this note based on the actual reason for suggestion (e.g., 'Low Stock', 'Out of Stock')
          category: item.category ?? 'Other',
        )).toList();
      });
    }
  }

  // ---------- Helpers: compute top margin under header ----------
  double _topSnackMargin() {
    final messengerTop = MediaQuery.of(context).padding.top;
    final render = _headerKey.currentContext?.findRenderObject() as RenderBox?;
    final headerHeight = render?.size.height ?? 0;
    // +8px breathing room under the header
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


  // ---------- limit banner ----------
  Future<void> _showLimitDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withAlpha((255 * 0.15).round()),
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
                    color: headerGreen.withAlpha((255 * 0.25).round()),
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
    final bookmarked = <ShoppingListItemModel>[];
    final others = <ShoppingListItemModel>[];
    for (final it in items) {
      (it.isBookmarked ? bookmarked : others).add(it);
    }
    items
      ..clear()
      ..addAll(bookmarked)
      ..addAll(others);
  }

  // ---------- Export helpers ----------
  String _asPlainText() {
    final buf = StringBuffer()
      ..writeln(_currentTitle)
      ..writeln('-' * _currentTitle.length)
      ..writeln();

    for (final it in items) {
      final checked = it.isPurchased ? 'x' : ' ';
      final sub = [
        if ((it.brand ?? '').trim().isNotEmpty) it.brand!.trim(),
        if ((it.netWeight ?? '').trim().isNotEmpty) it.netWeight!.trim(),
      ].join(' · ');
      final name = sub.isEmpty ? it.name : '${it.name} ($sub)';
      buf.writeln('[$checked] $name  —  Qty: ${it.quantity}  ·  ${it.category}  ·  ₱${(it.unitPrice * it.quantity).toStringAsFixed(2)}');
    }
    return buf.toString();
  }

  Future<Uint8List> _capturePng() async {
    final boundary =
        _captureKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) throw Exception('Nothing to capture');
    final ui.Image image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception('Failed to encode PNG');
    return byteData.buffer.asUint8List();
  }

  Future<File> _writeTemp(Uint8List bytes, String filename) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> _exportAsTxt() async {
    try {
      final text = _asPlainText();
      final bytes = Uint8List.fromList(utf8.encode(text));
      final file = await _writeTemp(
        bytes,
        '${_currentTitle.replaceAll(' ', '_').toLowerCase()}.txt',
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/plain')],
          subject: 'Shopping List',
        ),
      );
    } catch (e) {
      _showTopSnack('Failed to export TXT: $e');
    }
  }

  Future<void> _exportAsPng() async {
    try {
      final png = await _capturePng();
      final file = await _writeTemp(
        png,
        '${_currentTitle.replaceAll(' ', '_').toLowerCase()}.png',
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          subject: 'Shopping List',
        ),
      );
    } catch (e) {
      _showTopSnack('Failed to export PNG: $e');
    }
  }

  void _openExportSheet() {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Export "$_currentTitle"',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade900,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Export as TXT'),
                  subtitle: const Text('Share a plain text list'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _exportAsTxt();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.image_outlined),
                  title: const Text('Export as PNG'),
                  subtitle: const Text('Share an image of the list'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _exportAsPng();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------- Add Item Dialog ----------
  Future<void> _showAddItemDialog() async {
    if (_householdId == null) {
      _showTopSnack("Household not found. Please log in again.");
      return;
    }

    // If no active list, try to find or create a default "My Shopping List"
    if (_activeList == null) {
      // Check for an existing manual list
      var existingManualListSnapshot = await FirebaseFirestore.instance
          .collection('shoppingLists')
          .where('householdId', isEqualTo: _householdId)
          .where('type', isEqualTo: 'Manual')
          .limit(1)
          .get();

      if (existingManualListSnapshot.docs.isNotEmpty) {
        // Use the existing manual list
        setState(() {
          _activeList = ShoppingListModel.fromFirestore(existingManualListSnapshot.docs.first);
          _currentTitle = _activeList!.name;
          items = _activeList!.items;
          _reorderByBookmark();
        });
        _showTopSnack("Using existing manual list: ${_activeList!.name}");
      } else {
        // Create a new default manual list
        final newDefaultList = ShoppingListModel(
          householdId: _householdId!,
          name: 'My Shopping List',
          createdAt: DateTime.now(),
          items: [],
          type: 'Manual',
          isActive: false, // Manual lists are not "active" in the generated sense
        );
        DocumentReference docRef = await FirebaseFirestore.instance.collection('shoppingLists').add(newDefaultList.toFirestore());
        newDefaultList.id = docRef.id;

        setState(() {
          _activeList = newDefaultList;
          _currentTitle = _activeList!.name;
          items = _activeList!.items;
          _reorderByBookmark();
        });
        _showTopSnack("Created a new default shopping list.");
      }
    }

    // After ensuring _activeList is not null (either found or created)
    if (_activeList == null) {
      _showTopSnack("Could not create or find a shopping list.");
      return;
    }

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
        borderSide: BorderSide(color: Colors.black.withAlpha((255 * 0.15).round())),
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
                color: headerGreen.withAlpha((255 * 0.75).round()),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: headerGreen.withAlpha((255 * 0.30).round()),
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
                                color: Colors.black.withAlpha((255 * 0.15).round()),
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
                                  color: Colors.black.withAlpha((255 * 0.06).round()),
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
                                final newItem = ShoppingListItemModel(
                                  id: 'id_${DateTime.now().millisecondsSinceEpoch}',
                                  name: nameCtrl.text.trim(),
                                  brand: brandCtrl.text.trim().isEmpty ? null : brandCtrl.text.trim(),
                                  netWeight: sizeCtrl.text.trim().isEmpty ? null : sizeCtrl.text.trim(),
                                  category: selectedCategory!,
                                  unitPrice: 0, // Default price
                                  quantity: 1,
                                );
                                setState(() {
                                  items.insert(0, newItem);
                                  _reorderByBookmark();
                                });
                                if (_activeList != null) {
                                  _activeList!.items = items;
                                  FirebaseFirestore.instance.collection('shoppingLists').doc(_activeList!.id).update(_activeList!.toFirestore());
                                }
                                if (!mounted) return;
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
  Future<void> _showEditItemDialog(ShoppingListItemModel item) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: item.name);
    final brandCtrl = TextEditingController(text: item.brand ?? '');
    final sizeCtrl = TextEditingController(text: item.netWeight ?? '');
    String? selectedCategory = item.category;

    InputDecoration deco() => InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withAlpha((255 * 0.15).round())),
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
                color: headerGreen.withAlpha((255 * 0.75).round()),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: headerGreen.withAlpha((255 * 0.30).round()),
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
                                color: Colors.black.withAlpha((255 * 0.15).round()),
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
                                  color: Colors.black.withAlpha((255 * 0.06).round()),
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
                                  item.name = nameCtrl.text.trim();
                                  item.brand = brandCtrl.text.trim().isEmpty ? null : brandCtrl.text.trim();
                                  item.netWeight = sizeCtrl.text.trim().isEmpty ? null : sizeCtrl.text.trim();
                                  item.category = selectedCategory!;
                                });
                                if (_activeList != null) {
                                  _activeList!.items = items;
                                  FirebaseFirestore.instance.collection('shoppingLists').doc(_activeList!.id).update(_activeList!.toFirestore());
                                }
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
              // ===== NEW: show the current main list title if available =====
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
                      _fetchHouseholdAndListsAndSuggestions(); // Refresh active list when returning
                    },
                  ),
                  const Spacer(),
                  // === Export button (changed icon) ===
                  InkWell(
                    onTap: _openExportSheet,
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.file_download_outlined, size: 22),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: sep),

        // ------- Suggestions (collapsible) -------
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
          child: Column(
            children: [
              InkWell(
                onTap: () =>
                    setState(() => _suggestionsOpen = !_suggestionsOpen),
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    Text(
                      'Suggestions (${_suggestions.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade800,
                        fontSize: 15.5,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _suggestionsOpen
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey.shade800,
                    ),
                  ],
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  children: [
                    const SizedBox(height: 8),
                    ..._suggestions.map(
                      (s) => _SuggestionCard(
                        suggestion: s,
                        sep: sep,
                        headerGreen: headerGreen,
                        onAdd: () {
                          if (items.length >= maxGuestItems) {
                            _showLimitDialog();
                            return;
                          }
                          final newItem = ShoppingListItemModel(
                            id: 'sugg_${DateTime.now().millisecondsSinceEpoch}',
                            name: s.name,
                            brand: s.brand,
                            netWeight: s.sizeText,
                            category: s.category,
                            unitPrice: 0, // Default price
                            quantity: 1,
                          );
                          setState(() {
                            items.insert(0, newItem);
                            _reorderByBookmark();
                            _suggestions.remove(s);
                          });
                          if (_activeList != null) {
                            _activeList!.items = items;
                            FirebaseFirestore.instance.collection('shoppingLists').doc(_activeList!.id).update(_activeList!.toFirestore());
                          }
                          _showTopSnack('Added "${s.name}"');
                        },
                      ),
                    ),
                  ],
                ),
                crossFadeState: _suggestionsOpen
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 180),
                sizeCurve: Curves.easeInOut,
              ),
            ],
          ),
        ),

        Divider(height: 1, thickness: 1, color: sep),

        // ------- Main list (wrapped for PNG capture) -------
        Expanded(
          child: RepaintBoundary(
            key: _captureKey,
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _ ) =>
                  Divider(height: 1, thickness: 1, color: sep),
              itemBuilder: (context, index) {
                final item = items[index];

                return Slidable(
                  key: ValueKey(item.id),
                  closeOnScroll: true,
                  endActionPane: ActionPane(
                    motion: const DrawerMotion(), // stops and reveals actions
                    extentRatio: 0.40, // ~40% of tile width for two actions
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
                          setState(() => items.remove(removed));
                          if (_activeList != null) {
                            _activeList!.items = items;
                            FirebaseFirestore.instance.collection('shoppingLists').doc(_activeList!.id).update(_activeList!.toFirestore());
                          }
                          _showTopSnack('Deleted "${removed.name}"');
                        },
                        icon: Icons.delete_outline,
                        label: 'Delete',
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        borderRadius: BorderRadius.circular(0),
                      ),
                    ],
                  ),
                  // === Pantry-style overlay to indicate selection ===
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
                            onToggleInCart: (v) {
                              setState(() => item.isPurchased = v ?? false);
                              if (_activeList != null) {
                                _activeList!.items = items;
                                FirebaseFirestore.instance.collection('shoppingLists').doc(_activeList!.id).update(_activeList!.toFirestore());
                              }
                            },
                            onToggleBookmark: () {
                              setState(() {
                                item.isBookmarked = !item.isBookmarked;
                                _reorderByBookmark();
                              });
                              if (_activeList != null) {
                                _activeList!.items = items;
                                FirebaseFirestore.instance.collection('shoppingLists').doc(_activeList!.id).update(_activeList!.toFirestore());
                              }
                            },
                            onDecrement: () {
                              setState(() => item.quantity = (item.quantity > 0) ? item.quantity - 1 : 0);
                              if (_activeList != null) {
                                _activeList!.items = items;
                                FirebaseFirestore.instance.collection('shoppingLists').doc(_activeList!.id).update(_activeList!.toFirestore());
                              }
                            },
                            onIncrement: () {
                              setState(() => item.quantity += 1);
                              if (_activeList != null) {
                                _activeList!.items = items;
                                FirebaseFirestore.instance.collection('shoppingLists').doc(_activeList!.id).update(_activeList!.toFirestore());
                              }
                            },
                            onDelete: () {}, // kept for compatibility
                            onEdit: () {}, // disabled (no tap-to-edit on name)
                          ),
                        ),
                        if (item.isPurchased)
                          Positioned.fill(
                            child: IgnorePointer(
                              ignoring: true,
                              child: Container(
                                color: Colors.white.withAlpha((255 * 0.45).round()),
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
        ),
      ],
    );
  }
}

// ======================= Category → Icon helper =======================
IconData iconForCategory(String category) {
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

// ======================= Suggestion types/UI =======================
class _Suggestion {
  final String name;
  final String? brand; // NEW
  final String? sizeText; // NEW
  final String note; // e.g., "Low Stock", "Out of Stock"
  final String category;
  _Suggestion({
    required this.name,
    required this.note,
    required this.category,
    this.brand,
    this.sizeText,
  });
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.suggestion,
    required this.sep,
    required this.headerGreen,
    required this.onAdd,
  });

  final _Suggestion suggestion;
  final Color sep;
  final Color headerGreen;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    String? subline;
    final b = (suggestion.brand ?? '').trim();
    final s = (suggestion.sizeText ?? '').trim();
    if (b.isNotEmpty || s.isNotEmpty) {
      subline = (b.isNotEmpty && s.isNotEmpty)
          ? '$b · $s'
          : (b.isNotEmpty ? b : s);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: sep),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
          child: Row(
            children: [
              // Category icon for suggestion
              Icon(
                iconForCategory(suggestion.category),
                size: 22,
                color: headerGreen,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                    if (subline != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.black87.withAlpha((255 * 0.75).round()),
                          height: 1.1,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      suggestion.note,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle_outline_rounded),
                color: headerGreen,
                splashRadius: 20,
                tooltip: 'Add',
              ),
            ],
          ),
        ),
      ),
    );
  }
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

  final ShoppingListItemModel item;
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
    final bool selected = item.isPurchased;

    // Compose the "brand · size" subline
    String? subline;
    if ((item.brand != null && item.brand!.trim().isNotEmpty) ||
        (item.netWeight != null && item.netWeight!.trim().isNotEmpty)) {
      final b = (item.brand ?? '').trim();
      final s = (item.netWeight ?? '').trim();
      subline = (b.isNotEmpty && s.isNotEmpty)
          ? '$b · $s'
          : (b.isNotEmpty ? b : s);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // === Pantry-like checkbox behavior (no status change) ===
        Checkbox(
          value: selected,
          onChanged: onToggleInCart,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),

        // === Category icon chip ===
        Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: headerGreen.withAlpha((255 * 0.10).round()),
            shape: BoxShape.circle,
          ),
          child: Icon(
            iconForCategory(item.category ?? 'Other'),
            size: 18,
            color: headerGreen,
          ),
        ),

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
                        : Colors.black87.withAlpha((255 * 0.75).round())),
                    height: 1.1,
                  ),
                ),
              ],
              const SizedBox(height: 2),
              Text(
                item.category ?? 'Other',
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
            item.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: item.isBookmarked ? headerGreen : grey,
          ),
          onPressed: onToggleBookmark,
          splashRadius: 20,
          tooltip: item.isBookmarked ? 'Unpin' : 'Pin (priority)',
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Compact quantity controls
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.remove_circle_outline_rounded, color: grey, size: 18),
                    onPressed: onDecrement,
                    splashRadius: 16,
                  ),
                ),
                Container(
                  width: 26,
                  alignment: Alignment.center,
                  child: Text(
                    '${item.quantity}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.add_circle_outline_rounded, color: grey, size: 18),
                    onPressed: onIncrement,
                    splashRadius: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Price
            Text(
              '₱${(item.unitPrice * item.quantity).toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.grey.shade600 : headerGreen,
              ),
            ),
            // Unit price (smaller)
            Text(
              '₱${item.unitPrice.toStringAsFixed(2)}/item',
              style: TextStyle(
                fontSize: 11,
                color: selected ? Colors.grey.shade500 : Colors.grey.shade600,
              ),
            ),
          ],
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
