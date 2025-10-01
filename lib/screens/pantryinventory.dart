import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:numberpicker/numberpicker.dart'; // Import numberpicker
import 'package:shelf_control/models/pantry_item_model.dart'; // Import the new model
import 'package:shelf_control/services/firestore_service.dart'; // Import FirestoreService
import 'package:shelf_control/screens/editpantryitem.dart'; // Import EditPantryItem
import 'package:provider/provider.dart'; // Import provider
import 'package:shelf_control/widgets/consume_quantity_bottom_sheet.dart'; // Import the new bottom sheet

class Pantryinventory extends StatefulWidget {
  const Pantryinventory({super.key});

  @override
  State<Pantryinventory> createState() => _PantryInventoryBodyState();
}

// Define ItemStatus enum with the new 'consumed' and 'deleted' status
enum ItemStatus { active, atRisk, available, consumed, expired }

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
    'Expired',
  ];
  String sortBy = 'Expiry';
  String filterBy = 'All Items';

  List<PantryItemModel> _items = [];
  final Set<String> _selectedItemIds = {}; // To store IDs of selected items

  @override
  void initState() {
    super.initState();
  }

  // Determine if selection mode is active
  bool get _inSelectMode => _selectedItemIds.isNotEmpty;

  // Helper to determine item status based on expiration date and stored status
  ItemStatus _getItemStatus(PantryItemModel item) {
    // If the item is already consumed or deleted, return its status directly
    if (item.status == 'Consumed') return ItemStatus.consumed;

    if (item.expirationDate == null) {
      return ItemStatus.available;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expirationDay = DateTime(item.expirationDate!.year, item.expirationDate!.month, item.expirationDate!.day);
    final difference = expirationDay.difference(today).inDays;

    if (difference < 0) {
      return ItemStatus.expired; // Mark as 'Expired'
    } else if (difference <= 7) {
      return ItemStatus.atRisk;
    } else if (item.status == 'Active') {
      return ItemStatus.active;
    } else {
      return ItemStatus.available;
    }
  }

  // Helper to get the expiration text
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

  // Delete pantry item
  Future<void> _deletePantryItem(PantryItemModel item, FirestoreService firestoreService) async {
    if (item.id != null) {
      await firestoreService.deletePantryItem(item.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${item.name}"'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              // Re-add item if undo is pressed (requires more complex logic)
              // For now, we'll just show the message.
            },
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
        ),
      );
    }
  }



  // ---------- Filtering & Sorting ----------
  List<PantryItemModel> _filteredAndSorted() {
    List<PantryItemModel> list = _items.where((it) {
      // Do not show deleted items in the pantry inventory
      if (it.status == 'Deleted') return false;

      final status = _getItemStatus(it);
      // Apply filter based on selected filterBy option
      switch (filterBy) {
        case 'Active':
          if (status != ItemStatus.active) return false;
          break;
        case 'At risk':
          if (status != ItemStatus.atRisk) return false;
          break;
        case 'Available':
          if (status != ItemStatus.available) return false;
          break;
        case 'Consumed':
          if (status != ItemStatus.consumed) return false;
          break;
        case 'Expired':
          if (status != ItemStatus.expired) return false;
          break;
        default: // 'All Items'
          break;
      }
      // Apply search query if active
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        final hit =
            it.name.toLowerCase().contains(q) ||
            it.category.toLowerCase().contains(q) ||
            (it.brand?.toLowerCase().contains(q) ?? false);
        if (!hit) return false;
      }
      return true;
    }).toList();

    // Custom sorting: At risk first, then by user's preference
    list.sort((a, b) {
      // Apply special sorting for 'Expiry' only when sortBy is 'Expiry'
      if (sortBy == 'Expiry') {
        final statusA = _getItemStatus(a);
        final statusB = _getItemStatus(b);

        // Prioritize 'Expired' items
        if (statusA == ItemStatus.expired && statusB != ItemStatus.expired) {
          return -1;
        }
        if (statusA != ItemStatus.expired && statusB == ItemStatus.expired) {
          return 1;
        }

        // Then prioritize 'At risk' items
        if (statusA == ItemStatus.atRisk && statusB != ItemStatus.atRisk && statusB != ItemStatus.expired) {
          return -1;
        }
        if (statusA != ItemStatus.atRisk && statusB == ItemStatus.atRisk && statusA != ItemStatus.expired) {
          return 1;
        }
      }

      // Apply secondary sort based on selected sortBy option
      switch (sortBy) {
        case 'Name':
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case 'Quantity':
          return b.qty.compareTo(a.qty);
        case 'Expiry':
          // Handle null expiration dates by placing them at the end
          if (a.expirationDate == null && b.expirationDate == null) return 0;
          if (a.expirationDate == null) return 1; // Nulls last
          if (b.expirationDate == null) return -1; // Nulls last
          return a.expirationDate!.compareTo(b.expirationDate!);
        case 'Category':
        default:
          return a.category.toLowerCase().compareTo(b.category.toLowerCase());
      }
    });
    return list;
  }

  // Widget for the status chip
  Widget _statusChip(PantryItemModel item) {
    String text;
    Color bg;
    // Get the current status using the helper function
    ItemStatus currentStatus = _getItemStatus(item);

    // Determine text and background color based on status
    switch (currentStatus) {
      case ItemStatus.active:
        text = 'Active';
        bg = const Color(0xFF58A66A); // Green for active
        break;
      case ItemStatus.atRisk:
        text = 'At risk';
        bg = const Color(0xFFF1A648); // Orange for at risk
        break;
      case ItemStatus.available:
        text = 'Available';
        bg = const Color(0xFFF2DE7E); // Yellow for available (no expiry)
        break;
      case ItemStatus.consumed:
        text = 'Consumed';
        bg = Colors.grey.shade500; // Grey for consumed
        break;
      case ItemStatus.expired:
        text = 'Expired';
        bg = Colors.red.shade700; // Red for expired
        break;
    }
    // Make the chip tappable to change status
    return GestureDetector(
      onTap: () => _showStatusChangeDialog(item),
      child: Container(
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
      ),
    );
  }

  // Dialog to change item status
  void _showStatusChangeDialog(PantryItemModel item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Available'),
                onTap: () {
                  _updateItemStatus(item, 'Available');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('Active'),
                onTap: () {
                  _updateItemStatus(item, 'Active');
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                title: const Text('At risk'),
                onTap: () {
                  _updateItemStatus(item, 'At risk');
                  Navigator.of(context).pop();
                },
              ),
              // Only show 'Consumed' if (item.status != 'Consumed')
                ListTile(
                  title: const Text('Consumed'),
                  onTap: () {
                    _updateItemStatus(item, 'Consumed');
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // Update item status in Firestore
  Future<void> _updateItemStatus(PantryItemModel item, String newStatus, {int? consumedQuantity}) async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    if (newStatus == 'Consumed' && consumedQuantity != null) {
      await firestoreService.recordConsumedItem(item, consumedQuantity);
    } else if (newStatus == 'Consumed') {
      // If status is set to consumed without a specific quantity, assume all
      await firestoreService.recordConsumedItem(item, item.qty);
    } else {
      // For other status changes, just update the item
      PantryItemModel updatedItem = item.copyWith(status: newStatus);
      await firestoreService.updatePantryItem(updatedItem);
    }
  }

  // Dialog to pick quantity for consumption
  Future<void> _showQuantityPickerDialog(PantryItemModel item) async {
    int? selectedQuantity = item.qty; // Default to consuming all

    await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: softCream, // Apply softCream background
          title: Text(
            'Consume ${item.name}',
            style: TextStyle(color: headerGreen, fontWeight: FontWeight.bold), // Apply headerGreen to title
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Available: ${item.qty}', style: const TextStyle(color: Colors.grey)), // Apply grey to available text
                  NumberPicker(
                    value: selectedQuantity!,
                    minValue: 0,
                    maxValue: item.qty,
                    onChanged: (value) {
                      setState(() => selectedQuantity = value);
                    },
                    textStyle: const TextStyle(fontSize: 14, color: Colors.black54),
                    selectedTextStyle: TextStyle(fontSize: 18, color: headerGreen, fontWeight: FontWeight.bold), // Apply headerGreen
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: sep), // Apply sep for border
                    ),
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: headerGreen), // Apply headerGreen to Cancel button
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(selectedQuantity);
              },
              style: ElevatedButton.styleFrom(backgroundColor: headerGreen), // Apply headerGreen to Consume button
              child: const Text('Consume', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    ).then((quantity) async {
      if (quantity != null && quantity > 0) {
        // Explicitly set newStatus to 'Consumed' when consuming via the dialog
        await _updateItemStatus(item, 'Consumed', consumedQuantity: quantity);
      }
    });
  }

  // Widget for dropdown pills (Sort by, Filter)
  Widget _dropdownPill({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    double? width, // Optional width parameter
  }) {
    return Container(
      width: width, // Apply optional width
      decoration: BoxDecoration(
        color: const Color(0xFFE9E1C7),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4), // Reduced horizontal padding
      margin: const EdgeInsets.only(right: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          value: value,
          customButton: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6), // Reduced horizontal padding
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$label: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF20451F),
                    fontSize: 13, // Reduced font size
                  ),
                ),
                Flexible( // Use Flexible to prevent text overflow
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF20451F),
                      fontSize: 13, // Reduced font size
                    ),
                    overflow: TextOverflow.ellipsis, // Add ellipsis for long text
                  ),
                ),
                const SizedBox(width: 4), // Reduced spacing
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18, // Reduced icon size
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
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), // Reduced font size
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
            height: 36, // Reduced item height
            padding: EdgeInsets.symmetric(horizontal: 10), // Reduced padding
          ),
        ),
      ),
    );
  }

  // Selection mode top bar
  Widget _selectionModeTopBar(FirestoreService firestoreService) {
    return Container(
      color: headerGreen,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.check_box_rounded, color: Colors.white),
            onPressed: () {
              setState(() {
                _selectedItemIds.clear();
              });
            },
          ),
          Text(
            '${_selectedItemIds.length} Items',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Mark as Consumed',
            icon: const Icon(Icons.restaurant_menu, color: Colors.white),
            onPressed: () async {
              List<PantryItemModel> itemsToProcess = _selectedItemIds
                  .map((id) => _items.firstWhere((element) => element.id == id))
                  .toList();

              if (itemsToProcess.length == 1) {
                await _showQuantityPickerDialog(itemsToProcess.first);
              } else if (itemsToProcess.length > 1) {
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => ConsumeQuantityBottomSheet(items: itemsToProcess),
                );
              }
              setState(() {
                _selectedItemIds.clear();
              });
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
              setState(() {
                _selectedItemIds.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  // Title widget
  Widget _bigTitle() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Text(
        'Pantry Inventory',
        style: TextStyle(
          color: Color(0xFF20451F),
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // Controls row (Sort by, Filter, Search)
  Widget _controlsRow() {
    if (isSearching) {
      // Search input field
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

    // Pills for sorting and filtering
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
                  _dropdownPill(
                    label: 'Sort by',
                    value: sortBy,
                    items: _sortOptions,
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => sortBy = v);
                    },
                    width: 120, // Set a fixed width for Sort by
                  ),
                  _dropdownPill(
                    label: 'Filter',
                    value: filterBy,
                    items: _filterOptions,
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => filterBy = v);
                    },
                    width: 120, // Set a fixed width for Filter
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

  // Widget for each row in the inventory list
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
            // Navigate to item details/edit screen in view mode
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditPantryItem(item: item, isViewing: true),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Checkbox for selection mode
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
              ),
              // Item image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imageUrl ?? 'https://via.placeholder.com/150', // Placeholder if no image
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (error, stackTrace, hint) => const Icon(Icons.image),
                ),
              ),
              const SizedBox(width: 12),
              // Item details
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
                    const SizedBox(height: 4),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ${item.category}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6F6F6F),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getExpiresText(item), // Removed "Expires in:"
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6F6F6F),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Quantity control and status chip
              Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                        onPressed: () {
                          if (item.qty > 1) {
                            _updateItemQuantity(item, item.qty - 1);
                          } else {
                            _showQuantityPickerDialog(item); // Prompt to consume if quantity is 1
                          }
                        },
                      ),
Text(
  '${item.qty}',
  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
),
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

  // Update item quantity in Firestore
  Future<void> _updateItemQuantity(PantryItemModel item, int newQuantity) async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    if (newQuantity <= 0) {
      // If quantity becomes 0 or less, prompt to consume
      await _showQuantityPickerDialog(item);
    } else {
      PantryItemModel updatedItem = item.copyWith(qty: newQuantity);
      await firestoreService.updatePantryItem(updatedItem);
    }
  }

  // Widget for dismissible rows (delete/edit)
  Widget _dismissibleRow(List<PantryItemModel> view, int idx, FirestoreService firestoreService) {
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
          // Swipe right to delete
          await _deletePantryItem(item, firestoreService);
          return true; // Remove item from the visible list
        } else {
          // Swipe left to edit
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EditPantryItem(item: item)),
          );
          // If item was edited, update it in Firestore
          if (result != null && result is PantryItemModel) {
            await firestoreService.updatePantryItem(result);
          }
          return false; // Do not dismiss the item
        }
      },
      child: _rowTile(item, idx),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    // Show message if no household is selected
    if (firestoreService.selectedHouseholdId == null) {
      return const Center(child: Text('No household selected.'));
    }

    return Scaffold(
      backgroundColor: softCream,
      body: SafeArea(
        child: StreamBuilder<List<PantryItemModel>>(
          // Stream to get pantry items for the selected household
          stream: firestoreService.getPantryItemsForHousehold(firestoreService.selectedHouseholdId!),
          builder: (context, snapshot) {
            // Show loading indicator while fetching data
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            // Show error message if fetching fails
            if (snapshot.hasError) {
              return Center(child: Text('Error: \${snapshot.error}'));
            }
            // Show message if no items are found
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No pantry items yet. Add some!'));
            }

            // Update the local items list and filtered/sorted view
            _items = snapshot.data!;
            final view = _filteredAndSorted();

            // Build the main UI layout
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_inSelectMode)
                  _selectionModeTopBar(firestoreService)
                else ...[
                  _bigTitle(), // Pantry Inventory title
                  _controlsRow(), // Search, Sort, and Filter controls
                ],
                const Divider(height: 1, thickness: 1, color: Color(0xFFE9E1C7)),
                // List of pantry items
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
}
