import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:shelf_control/models/pantry_item_model.dart';
import 'package:shelf_control/services/firestore_service.dart';
import 'package:shelf_control/screens/pantryitemdetails.dart'; // UPDATED Import
import 'package:shelf_control/screens/editpantryitem.dart'; // UPDATED Import
import 'package:provider/provider.dart';
import 'package:shelf_control/widgets/consume_quantity_bottom_sheet.dart';

class Pantryinventory extends StatefulWidget {
  const Pantryinventory({super.key});

  @override
  State<Pantryinventory> createState() => _PantryInventoryBodyState();
}

enum ItemStatus { active, atRisk, available, consumed, expired }

class _PantryInventoryBodyState extends State<Pantryinventory> {
  // Palette
  final Color headerGreen = const Color(0xFF2E7D32);
  final Color softCream = const Color(0xFFFFFBE6);
  final Color rowAlt = const Color(0xFFF7EFD3);
  final Color sep = const Color(0xFFE9E1C7);

  // State
  bool isSearching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  String sortBy = 'Expiry';
  String filterBy = 'All Items';
  final Set<String> _selectedItemIds = {};
  List<PantryItemModel> _items = [];

  // Options
  final List<String> _sortOptions = const ['Category', 'Name', 'Quantity', 'Expiry'];
  final List<String> _filterOptions = const ['All Items', 'Active', 'At risk', 'Available', 'Expired'];

  bool get _inSelectMode => _selectedItemIds.isNotEmpty;

  ItemStatus _getItemStatus(PantryItemModel item) {
    if (item.status == 'Consumed') return ItemStatus.consumed;

    if (item.expirationDate == null) {
      return ItemStatus.available;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expirationDay = DateTime(item.expirationDate!.year, item.expirationDate!.month, item.expirationDate!.day);
    final difference = expirationDay.difference(today).inDays;

    if (difference < 0) {
      return ItemStatus.expired;
    } else if (difference <= 7) {
      return ItemStatus.atRisk;
    } else if (item.status == 'Active') {
      return ItemStatus.active;
    } else {
      return ItemStatus.available;
    }
  }

  String _getExpiresText(PantryItemModel item) {
    if (item.expirationDate == null) {
      return 'No expiry date';
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expirationDay = DateTime(item.expirationDate!.year, item.expirationDate!.month, item.expirationDate!.day);
    final difference = expirationDay.difference(today).inDays;

    if (difference == 0) {
      return 'Expires today';
    } else if (difference == 1) {
      return 'Expires tomorrow';
    } else if (difference > 1) {
      return 'Expires in $difference days';
    } else {
      return 'Expired ${difference.abs()} days ago';
    }
  }

  void _toggleSearch() {
    setState(() {
      isSearching = !isSearching;
      if (!isSearching) {
        _query = '';
        _searchCtrl.clear();
      }
    });
  }

  Future<void> _deletePantryItem(PantryItemModel item, FirestoreService firestoreService) async {
    if (item.id != null) {
      await firestoreService.deletePantryItem(item.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${item.name}"'),
          action: SnackBarAction(label: 'Undo', onPressed: () {}),
        ),
      );
    }
  }

  List<PantryItemModel> _filteredAndSorted() {
    List<PantryItemModel> list = _items.where((it) {
      if (it.status == 'Deleted') return false;

      final status = _getItemStatus(it);
      switch (filterBy) {
        case 'Active': if (status != ItemStatus.active) return false; break;
        case 'At risk': if (status != ItemStatus.atRisk) return false; break;
        case 'Available': if (status != ItemStatus.available) return false; break;
        case 'Consumed': if (status != ItemStatus.consumed) return false; break;
        case 'Expired': if (status != ItemStatus.expired) return false; break;
        default: break;
      }
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        final hit = it.name.toLowerCase().contains(q) ||
            it.category.toLowerCase().contains(q) ||
            (it.brand?.toLowerCase().contains(q) ?? false);
        if (!hit) return false;
      }
      return true;
    }).toList();

    list.sort((a, b) {
      if (sortBy == 'Expiry') {
        final statusA = _getItemStatus(a);
        final statusB = _getItemStatus(b);

        if (statusA == ItemStatus.expired && statusB != ItemStatus.expired) return -1;
        if (statusA != ItemStatus.expired && statusB == ItemStatus.expired) return 1;
        if (statusA == ItemStatus.atRisk && statusB != ItemStatus.atRisk && statusB != ItemStatus.expired) return -1;
        if (statusA != ItemStatus.atRisk && statusB == ItemStatus.atRisk && statusA != ItemStatus.expired) return 1;
      }

      switch (sortBy) {
        case 'Name': return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case 'Quantity': return b.qty.compareTo(a.qty);
        case 'Expiry':
          if (a.expirationDate == null && b.expirationDate == null) return 0;
          if (a.expirationDate == null) return 1;
          if (b.expirationDate == null) return -1;
          return a.expirationDate!.compareTo(b.expirationDate!);
        case 'Category':
        default: return a.category.toLowerCase().compareTo(b.category.toLowerCase());
      }
    });
    return list;
  }

  Future<void> _updateItemStatus(PantryItemModel item, String newStatus, {int? consumedQuantity}) async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    if (newStatus == 'Consumed' && consumedQuantity != null) {
      await firestoreService.recordConsumedItem(item, consumedQuantity);
    } else if (newStatus == 'Consumed') {
      await firestoreService.recordConsumedItem(item, item.qty);
    } else {
      PantryItemModel updatedItem = item.copyWith(status: newStatus);
      await firestoreService.updatePantryItem(updatedItem);
    }
  }

  Future<void> _showQuantityPickerDialog(PantryItemModel item) async {
    int? selectedQuantity = item.qty;
    await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: softCream,
          title: Text('Consume ${item.name}', style: TextStyle(color: headerGreen, fontWeight: FontWeight.bold)),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Available: ${item.qty}', style: const TextStyle(color: Colors.grey)),
                  NumberPicker(
                    value: selectedQuantity!,
                    minValue: 0,
                    maxValue: item.qty,
                    onChanged: (value) => setState(() => selectedQuantity = value),
                    textStyle: const TextStyle(fontSize: 14, color: Colors.black54),
                    selectedTextStyle: TextStyle(fontSize: 18, color: headerGreen, fontWeight: FontWeight.bold),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: sep)),
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: headerGreen),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(selectedQuantity),
              style: ElevatedButton.styleFrom(backgroundColor: headerGreen),
              child: const Text('Consume', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ).then((quantity) async {
      if (quantity != null && quantity > 0) {
        await _updateItemStatus(item, 'Consumed', consumedQuantity: quantity);
      }
    });
  }

  Future<void> _updateItemQuantity(PantryItemModel item, int newQuantity) async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    if (newQuantity <= 0) {
      await _showQuantityPickerDialog(item);
    } else {
      PantryItemModel updatedItem = item.copyWith(qty: newQuantity);
      await firestoreService.updatePantryItem(updatedItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    if (firestoreService.selectedHouseholdId == null) {
      return const Center(child: Text('No household selected.'));
    }

    return Scaffold(
      backgroundColor: softCream,
      body: SafeArea(
        child: StreamBuilder<List<PantryItemModel>>(
          stream: firestoreService.getPantryItemsForHousehold(firestoreService.selectedHouseholdId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No pantry items yet. Add some!'));
            }

            _items = snapshot.data!;
            final view = _filteredAndSorted();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_inSelectMode) _selectionModeTopBar(firestoreService) else ...[
                  _bigTitle(),
                  _controlsRow(),
                ],
                Divider(height: 1, thickness: 1, color: sep),
                Expanded(
                  child: ListView.separated(
                    itemCount: view.length,
                    separatorBuilder: (_, __) => Divider(height: 1, thickness: 1, color: sep),
                    itemBuilder: (_, i) => _dismissibleRow(view, i, firestoreService),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------- WIDGETS ----------

  Widget _selectionModeTopBar(FirestoreService firestoreService) {
    return Container(
      color: headerGreen,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.check_box_outline_blank, color: Colors.white),
            onPressed: () => setState(() => _selectedItemIds.clear()),
          ),
          Text('${_selectedItemIds.length} Items', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const Spacer(),
          IconButton(
            tooltip: 'Mark as Consumed',
            icon: const Icon(Icons.restaurant_menu, color: Colors.white),
            onPressed: () async {
              List<PantryItemModel> itemsToProcess = _selectedItemIds.map((id) => _items.firstWhere((element) => element.id == id)).toList();
              if (itemsToProcess.length == 1) {
                await _showQuantityPickerDialog(itemsToProcess.first);
              } else if (itemsToProcess.length > 1) {
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => ConsumeQuantityBottomSheet(items: itemsToProcess),
                );
              }
              setState(() => _selectedItemIds.clear());
            },
          ),
          IconButton(
            tooltip: 'Delete Selected',
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () async {
              for (String itemId in _selectedItemIds) {
                final item = _items.firstWhere((element) => element.id == itemId);
                await _deletePantryItem(item, firestoreService);
              }
              setState(() => _selectedItemIds.clear());
            },
          ),
        ],
      ),
    );
  }

  Widget _bigTitle() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Text('Pantry Inventory', style: TextStyle(color: Color(0xFF20451F), fontSize: 24, fontWeight: FontWeight.w900)),
    );
  }

  Widget _controlsRow() {
    if (isSearching) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: SizedBox(
          height: 44,
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v.trim()),
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search items or categories...',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSearch,
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: sep)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: sep)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: headerGreen)),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _dropdownPill(label: 'Sort by', value: sortBy, items: _sortOptions, onChanged: (v) => setState(() => sortBy = v!)),
                  _dropdownPill(label: 'Filter', value: filterBy, items: _filterOptions, onChanged: (v) => setState(() => filterBy = v!)),
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

  Widget _dropdownPill({required String label, required String value, required List<String> items, required void Function(String?) onChanged}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          value: value,
          customButton: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: sep, borderRadius: BorderRadius.circular(24)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF20451F), fontSize: 13)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF20451F), fontSize: 13)),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF20451F)),
              ],
            ),
          ),
          items: items.map((e) => DropdownMenuItem<String>(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)))).toList(),
          onChanged: onChanged,
          dropdownStyleData: DropdownStyleData(
            padding: EdgeInsets.zero,
            maxHeight: 240,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          ),
          menuItemStyleData: const MenuItemStyleData(height: 36, padding: EdgeInsets.symmetric(horizontal: 10)),
        ),
      ),
    );
  }

  Widget _statusChip(PantryItemModel item) {
    String text;
    Color bg;
    ItemStatus currentStatus = _getItemStatus(item);

    switch (currentStatus) {
      case ItemStatus.active: text = 'Active'; bg = const Color(0xFF58A66A); break;
      case ItemStatus.atRisk: text = 'At risk'; bg = const Color(0xFFF1A648); break;
      case ItemStatus.available: text = 'Available'; bg = const Color(0xFFF2DE7E); break;
      case ItemStatus.consumed: text = 'Consumed'; bg = Colors.grey.shade500; break;
      case ItemStatus.expired: text = 'Expired'; bg = Colors.red.shade700; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }

  Widget _rowTile(PantryItemModel item, int visualIndex) {
    return Material(
      color: visualIndex.isEven ? Colors.white : rowAlt,
      child: InkWell(
        onLongPress: () {
          setState(() {
            if (_selectedItemIds.contains(item.id)) {
              _selectedItemIds.remove(item.id);
            } else {
              _selectedItemIds.add(item.id!);
            }
          });
        },
        onTap: () {
          if (_inSelectMode) {
            setState(() {
              if (_selectedItemIds.contains(item.id)) {
                _selectedItemIds.remove(item.id);
              } else {
                _selectedItemIds.add(item.id!);
              }
            });
          } else {
            // UPDATED: Navigate to the new view-only details screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PantryItemDetails(item: item),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              if (_inSelectMode)
                Checkbox(
                  value: _selectedItemIds.contains(item.id),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _selectedItemIds.add(item.id!);
                      } else {
                        _selectedItemIds.remove(item.id);
                      }
                    });
                  },
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.imageUrl ?? 'https://via.placeholder.com/150',
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (error, stackTrace, hint) => const Icon(Icons.image),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF20451F)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('• ${item.category}', style: const TextStyle(fontSize: 11, color: Color(0xFF6F6F6F))),
                    const SizedBox(height: 2),
                    Text(_getExpiresText(item), style: const TextStyle(fontSize: 11, color: Color(0xFF6F6F6F), fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                        onPressed: () => _updateItemQuantity(item, item.qty - 1),
                      ),
                      Text('${item.qty}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        onPressed: () => _updateItemQuantity(item, item.qty + 1),
                      ),
                    ],
                  ),
                  _statusChip(item),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dismissibleRow(List<PantryItemModel> view, int idx, FirestoreService firestoreService) {
    final item = view[idx];
    return Dismissible(
      key: ValueKey(item.id),
      direction: _inSelectMode ? DismissDirection.none : DismissDirection.horizontal,
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
          await _deletePantryItem(item, firestoreService);
          return true;
        } else {
          // UPDATED: Navigate to the new dedicated edit screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EditPantryItem(item: item)),
          );
          return false;
        }
      },
      child: _rowTile(item, idx),
    );
  }
}