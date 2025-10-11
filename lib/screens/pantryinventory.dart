import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shelf_control/models/pantry_item_model.dart';
import 'package:shelf_control/services/firestore_service.dart';
import 'package:shelf_control/screens/pantryitemdetails.dart';
import 'package:shelf_control/screens/editpantryitem.dart';
import 'package:provider/provider.dart';
import 'package:shelf_control/widgets/consume_quantity_bottom_sheet.dart';
import 'package:shelf_control/models/app_notification_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf_control/screens/addpantryitem.dart';

class Pantryinventory extends StatefulWidget {
  final bool isGuest;
  const Pantryinventory({super.key, this.isGuest = false});

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

  bool _inMultiSelectMode = false;
  Map<String, dynamic>? _notificationSettings;
  static const String _lastNotificationCheckKey = 'lastNotificationCheck';
  static const Duration _notificationCheckInterval = Duration(hours: 24);

  // Options
  final List<String> _sortOptions = const [
    'Category',
    'Name',
    'Quantity',
    'Expiry'
  ];
  final List<String> _filterOptions = const [
    'All Items',
    'Active',
    'At risk',
    'Available',
    'Expired'
  ];

  @override
  void initState() {
    super.initState();
    if (!widget.isGuest) {
      _loadNotificationSettings();
    }
  }

  Future<void> _loadNotificationSettings() async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userId = firestoreService.userId;
    if (userId != null) {
      _notificationSettings = await firestoreService.getNotificationSettings(userId);
      setState(() {}); // Update UI if settings affect anything visible
      _checkAndGenerateNotifications(); // Call after loading settings
    }
  }

  // Determine if selection mode is active
  bool get _inSelectMode => _inMultiSelectMode;

  ItemStatus _getItemStatus(PantryItemModel item) {
    if (item.status == 'Consumed') return ItemStatus.consumed;

    if (item.expirationDate == null) {
      return ItemStatus.available;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expirationDay = DateTime(item.expirationDate!.year,
        item.expirationDate!.month, item.expirationDate!.day);
    final difference = expirationDay.difference(today).inDays;

    // Default to 7 days for "at risk" status in the UI, independent of notification settings
    const int defaultAtRiskDays = 7; 

    ItemStatus status;
    if (difference < 0) {
      status = ItemStatus.expired;
    } else if (difference <= defaultAtRiskDays) { 
      status = ItemStatus.atRisk;
    } else {
      status = ItemStatus.available;
    }
    return status;
  }

  Future<void> _checkAndGenerateNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final lastCheckString = prefs.getString(_lastNotificationCheckKey);
    DateTime? lastCheck;
    if (lastCheckString != null) {
      lastCheck = DateTime.tryParse(lastCheckString);
    }

    // Only run the check if it hasn't been run within the interval
    if (lastCheck != null && DateTime.now().difference(lastCheck) < _notificationCheckInterval) {
      return;
    }

    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userId = firestoreService.userId;
    final householdId = firestoreService.selectedHouseholdId;

    if (userId == null || householdId == null) return;

    // Get all pantry items for the current household
    final pantryItemsSnapshot = await firestoreService.getPantryItemsForHousehold(householdId).first;

    int expiredCount = 0;
    int atRiskCount = 0;
    List<String> expiredItemNames = [];
    List<String> atRiskItemNames = [];

    for (var item in pantryItemsSnapshot) {
      final status = _getItemStatus(item); // Use the helper to get status without generating notifications
      if (status == ItemStatus.expired && (_notificationSettings?['expiredItems'] ?? false)) {
        expiredCount++;
        expiredItemNames.add(item.name);
      } else if (status == ItemStatus.atRisk && (_notificationSettings?['atRiskItems'] ?? false)) {
        atRiskCount++;
        atRiskItemNames.add(item.name);
      }
    }

    // Generate a single summary notification if there are any expired or at-risk items
    if (expiredCount > 0 || atRiskCount > 0) {
      String title = 'Pantry Alert!';
      String body = '';
      String type = 'pantry_summary';
      String payload = '{"type": "pantry_summary", "householdId": "$householdId"}';

      if (expiredCount > 0 && atRiskCount > 0) {
        body = 'You have $expiredCount expired item(s) and $atRiskCount item(s) at risk of expiring soon.';
      } else if (expiredCount > 0) {
        body = 'You have $expiredCount expired item(s).';
      } else if (atRiskCount > 0) {
        body = 'You have $atRiskCount item(s) at risk of expiring soon.';
      }

      await firestoreService.addAppNotification(
        AppNotificationModel(
          userId: userId,
          householdId: householdId,
          title: title,
          body: body,
          type: type,
          createdAt: Timestamp.now(),
          isRead: false,
          payload: payload,
        ),
      );
    }

    // Update the last check timestamp
    await prefs.setString(_lastNotificationCheckKey, DateTime.now().toIso8601String());
  }

  String _getExpiresText(PantryItemModel item) {
    if (item.expirationDate == null) {
      return 'No expiry date';
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expirationDay = DateTime(item.expirationDate!.year,
        item.expirationDate!.month, item.expirationDate!.day);
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

  Future<void> _deletePantryItem(
      PantryItemModel item, FirestoreService firestoreService) async {
    if (item.id != null) {
      if (widget.isGuest) {
        List<PantryItemModel> currentGuestPantry = await firestoreService.loadGuestPantryItems();
        currentGuestPantry.removeWhere((element) => element.id == item.id);
        await firestoreService.saveGuestPantryItems(currentGuestPantry);
      } else {
        await firestoreService.deletePantryItem(item.id!);
      }
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

  // Consume selected items
  Future<void> _consumeSelectedItems(FirestoreService firestoreService) async {
    if (_selectedItemIds.isEmpty) return;

    if (widget.isGuest) {
      List<PantryItemModel> currentGuestPantry = await firestoreService.loadGuestPantryItems();
      List<PantryItemModel> updatedGuestPantry = [];

      for (var item in currentGuestPantry) {
        if (_selectedItemIds.contains(item.id)) {
          // Mark as consumed and remove if quantity is 0
          if (item.qty > 0) {
            // For guest mode, we'll just remove the item for simplicity
            // A more complex guest implementation would involve a consume quantity dialog
          }
        } else {
          updatedGuestPantry.add(item);
        }
      }
      await firestoreService.saveGuestPantryItems(updatedGuestPantry);
    } else {
      // For registered users, use the batch consume method
      Map<String, int> itemsToConsume = {};
      for (String itemId in _selectedItemIds) {
        final item = _items.firstWhere((element) => element.id == itemId);
        itemsToConsume[itemId] = item.qty; // Consume all quantity for selected items
      }
      if (firestoreService.selectedHouseholdId != null) {
        await firestoreService.batchConsumePantryItems(
            firestoreService.selectedHouseholdId!, itemsToConsume);
      }
    }

    setState(() {
      _selectedItemIds.clear();
      _inMultiSelectMode = false;
    });
  }


  // ---------- Filtering & Sorting ----------
  List<PantryItemModel> _filteredAndSorted() {
    List<PantryItemModel> list = _items.where((it) {
      if (it.status == 'Deleted') return false;

      final status = _getItemStatus(it);
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
        default:
          break;
      }
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        if (!(it.name.toLowerCase().contains(q) || it.category.toLowerCase().contains(q))) {
          return false;
        }
      }
      return true;
    }).toList();

    list.sort((a, b) {
      if (sortBy == 'Expiry') {
        final statusA = _getItemStatus(a);
        final statusB = _getItemStatus(b);

        if (statusA == ItemStatus.expired && statusB != ItemStatus.expired)
          return -1;
        if (statusA != ItemStatus.expired && statusB == ItemStatus.expired)
          return 1;
        if (statusA == ItemStatus.atRisk &&
            statusB != ItemStatus.atRisk &&
            statusB != ItemStatus.expired) return -1;
        if (statusA != ItemStatus.atRisk &&
            statusB == ItemStatus.atRisk &&
            statusA != ItemStatus.expired) return 1;
      }

      switch (sortBy) {
        case 'Name':
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case 'Quantity':
          return b.qty.compareTo(a.qty);
        case 'Expiry':
          if (a.expirationDate == null && b.expirationDate == null) return 0;
          if (a.expirationDate == null) return 1;
          if (b.expirationDate == null) return -1;
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

    if (widget.isGuest) {
      List<PantryItemModel> currentGuestPantry = await firestoreService.loadGuestPantryItems();
      int itemIndex = currentGuestPantry.indexWhere((element) => element.id == item.id);
      if (itemIndex != -1) {
        PantryItemModel updatedItem = item.copyWith(status: newStatus);
        if (newStatus == 'Consumed' && consumedQuantity != null) {
          updatedItem = updatedItem.copyWith(qty: updatedItem.qty - consumedQuantity);
        } else if (newStatus == 'Consumed') {
          updatedItem = updatedItem.copyWith(qty: 0); // Consume all
        }

        if (updatedItem.qty <= 0) {
          currentGuestPantry.removeAt(itemIndex);
        } else {
          currentGuestPantry[itemIndex] = updatedItem;
        }
        await firestoreService.saveGuestPantryItems(currentGuestPantry);
      }
    } else {
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
  }

  Future<void> _showQuantityPickerDialog(PantryItemModel item) async {
    int? selectedQuantity = item.qty;
    await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: softCream,
          title: Text('Consume ${item.name}',
              style:
                  TextStyle(color: headerGreen, fontWeight: FontWeight.bold)),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Available: ${item.qty}',
                      style: const TextStyle(color: Colors.grey)),
                  NumberPicker(
                    value: selectedQuantity!,
                    minValue: 0,
                    maxValue: item.qty,
                    onChanged: (value) =>
                        setState(() => selectedQuantity = value),
                    textStyle:
                        const TextStyle(fontSize: 14, color: Colors.black54),
                    selectedTextStyle: TextStyle(
                        fontSize: 18,
                        color: headerGreen,
                        fontWeight: FontWeight.bold),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: sep)),
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
              child:
                  const Text('Consume', style: TextStyle(color: Colors.white)),
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

  Future<void> _updateItemQuantity(
      PantryItemModel item, int newQuantity) async {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    if (newQuantity <= 0) {
      await _showQuantityPickerDialog(item);
    } else {
      PantryItemModel updatedItem = item.copyWith(qty: newQuantity);
      await firestoreService.updatePantryItem(updatedItem);
    }
  }

  // Helper function to navigate to the edit screen and handle the result for the banner
  Future<void> _navigateToEditItem(PantryItemModel item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPantryItem(item: item),
      ),
    );

    if (result is Map<String, dynamic>) {
      final status = result['status'] as String?;
      final itemName = result['itemName'] as String?;

      print('DEBUG: _navigateToEditItem received status: $status, itemName: $itemName');

      if (itemName != null && status != null && status != 'none') {
        String message;
        Color backgroundColor;
        if (status == 'expired') {
          message = 'Heads up! The $itemName you updated has already expired.';
          backgroundColor = Colors.red.shade700;
        } else { // atRisk
          message = 'Heads up! The $itemName you updated is at risk of expiring soon.';
          backgroundColor = Colors.orange.shade700;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Helper function to navigate to the add item screen and handle the result for the banner
  void _handleAddItem(PantryItemModel item) async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    if (widget.isGuest) {
      List<PantryItemModel> currentGuestPantry = await firestoreService.loadGuestPantryItems();
      // Assign a temporary ID for guest items if not already present
      PantryItemModel itemWithId = item.copyWith(id: item.id?.isEmpty ?? true ? DateTime.now().millisecondsSinceEpoch.toString() : item.id!);
      currentGuestPantry.add(itemWithId);
      await firestoreService.saveGuestPantryItems(currentGuestPantry);
    } else {
      await firestoreService.addPantryItem(item);
    }
  }

  Future<void> _navigateToAddItem() async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPantryItem(
          isGuest: widget.isGuest,
          onAddItem: _handleAddItem,
          onBack: () => Navigator.of(context).pop(),
          householdId: firestoreService.selectedHouseholdId != null ? firestoreService.selectedHouseholdId! : '',
        ),
      ),
    );
    if (result is Map<String, dynamic>) {
      final status = result['status'] as String?;
      final itemName = result['itemName'] as String?;

      print('DEBUG: _navigateToAddItem received status: $status, itemName: $itemName');

      if (itemName != null && status != null && status != 'none') {
        String message;
        Color backgroundColor;
        if (status == 'expired') {
          message = 'Heads up! The $itemName you added has already expired.';
          backgroundColor = Colors.red.shade700;
        } else { // atRisk
          message = 'Heads up! The $itemName you added is at risk of expiring soon.';
          backgroundColor = Colors.orange.shade700;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Widget for the dropdown pills
  Widget _dropdownPill(
      {required String label,
      required String value,
      required List<String> items,
      required void Function(String?) onChanged}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          value: value,
          customButton: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: sep, borderRadius: BorderRadius.circular(24)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$label: ',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF20451F),
                        fontSize: 13)),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF20451F),
                        fontSize: 13)),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: Color(0xFF20451F)),
              ],
            ),
          ),
          items: items
              .map((e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(e,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13))))
              .toList(),
          onChanged: onChanged,
          dropdownStyleData: DropdownStyleData(
            padding: EdgeInsets.zero,
            maxHeight: 240,
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12)),
          ),
          menuItemStyleData: const MenuItemStyleData(
              height: 36, padding: EdgeInsets.symmetric(horizontal: 10)),
        ),
      ),
    );
  }

  Widget _rowTile(PantryItemModel item, int visualIndex) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return Material(
      color: visualIndex.isEven ? Colors.white : rowAlt,
      child: InkWell(
        onLongPress: () {
          setState(() {
            _inMultiSelectMode = true;
            if (_selectedItemIds.contains(item.id)) {
              _selectedItemIds.remove(item.id);
            } else {
              _selectedItemIds.add(item.id!);
            }
          });
        },
        onTap: () {
          if (_inMultiSelectMode) {
            setState(() {
              if (_selectedItemIds.contains(item.id)) {
                _selectedItemIds.remove(item.id);
              } else {
                _selectedItemIds.add(item.id!);
              }
            });
          } else {
            // Navigate to item details screen in view mode
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
              // Checkbox for selection mode (only visible in multi-select mode)
              if (_inMultiSelectMode)
                Checkbox(
                  value: _selectedItemIds.contains(item.id),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _selectedItemIds.add(item.id!);
                      } else {
                        _selectedItemIds.remove(item.id);
                        if (_selectedItemIds.isEmpty) {
                          _inMultiSelectMode = false; // Exit if no items selected
                        }
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
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF20451F)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('Unknown Member', // Changed from brand
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF6F6F6F))),
                    const SizedBox(height: 2),
                    Text(_getExpiresText(item),
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6F6F6F),
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Quantity controls
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                        onPressed: () => _updateItemQuantity(item, item.qty - 1),
                      ),
                      Text('${item.qty}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
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

  // Mark as wasted
  Future<void> _markAsWasted(PantryItemModel item, FirestoreService firestoreService) async {
    if (item.id != null) {
      if (widget.isGuest) {
        List<PantryItemModel> currentGuestPantry = await firestoreService.loadGuestPantryItems();
        int itemIndex = currentGuestPantry.indexWhere((element) => element.id == item.id);
        if (itemIndex != -1) {
          PantryItemModel updatedItem = item.copyWith(status: 'Wasted', wastedAt: DateTime.now());
          currentGuestPantry[itemIndex] = updatedItem;
          await firestoreService.saveGuestPantryItems(currentGuestPantry);
        }
      } else {
        await firestoreService.markAsWasted(item);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Marked "${item.name}" as wasted'),
        ),
      );
    }
  }

  // Widget for dismissible rows (delete/edit/consume/waste)
  Widget _dismissibleRow(List<PantryItemModel> view, int idx, FirestoreService firestoreService) {
    final item = view[idx];
    final ItemStatus currentStatus = _getItemStatus(item);
    final bool isExpired = currentStatus == ItemStatus.expired;

    return Slidable(
      key: ValueKey(item.id),
      groupTag: 'pantry_items',
      enabled: !_inSelectMode, // Disable slidable in multi-select mode
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25, // For 'Consume'
        children: [
          SlidableAction(
            onPressed: (_) async {
              if (item.qty > 1) {
                await _showQuantityPickerDialog(item);
              } else {
                await _updateItemStatus(item, 'Consumed', consumedQuantity: 1);
              }
            },
            backgroundColor: isExpired ? Colors.grey : Colors.green.shade700,
            foregroundColor: Colors.white,
            icon: Icons.restaurant_menu,
            label: 'Consume',
            flex: 1,
            // Disable consume if expired
            // enabled: !isExpired,
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.50, // For 'Edit' and 'Delete'
        children: [
          SlidableAction(
            onPressed: (_) => _navigateToEditItem(item),
            backgroundColor: headerGreen,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
          ),
          SlidableAction(
            onPressed: (_) async {
              if (isExpired) {
                await _markAsWasted(item, firestoreService);
              } else {
                await _deletePantryItem(item, firestoreService);
              }
            },
            backgroundColor: isExpired ? Colors.orange.shade700 : Colors.red.shade700,
            foregroundColor: Colors.white,
            icon: isExpired ? Icons.delete_sweep : Icons.delete_outline,
            label: isExpired ? 'Wasted' : 'Delete',
          ),
        ],
      ),
      child: _rowTile(item, idx),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      backgroundColor: softCream,
      body: SafeArea(
        child: StreamBuilder<List<PantryItemModel>>(
          stream: widget.isGuest
              ? Stream.fromFuture(firestoreService.loadGuestPantryItems())
              : (firestoreService.selectedHouseholdId == null
                  ? Stream.value([])
                  : firestoreService.getPantryItemsForHousehold(firestoreService.selectedHouseholdId!)),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            _items = snapshot.data ?? [];
            final view = _filteredAndSorted();

            if (view.isEmpty) {
              return const Center(child: Text('No pantry items yet. Add some!'));
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_inMultiSelectMode)
                  _selectionModeTopBar(firestoreService)
                else ...[
                  _bigTitle(),
                  _controlsRow(),
                ],
                const Divider(height: 1, thickness: 1, color: Color(0xFFE9E1C7)),
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
            icon: const Icon(Icons.cancel_rounded, color: Colors.white), // Changed icon to cancel
            onPressed: () {
              setState(() {
                _selectedItemIds.clear();
                _inMultiSelectMode = false; // Exit multi-select mode
              });
            },
          ),
          Text(
            '${_selectedItemIds.length} Items Selected', // Updated text
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Consume Selected', // Changed tooltip
            icon: const Icon(Icons.restaurant_menu, color: Colors.white),
            onPressed: () async {
              await _consumeSelectedItems(firestoreService); // Use new consume method
            },
          ),
          IconButton(
            tooltip: 'Delete Selected',
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: () async {
              for (String itemId in _selectedItemIds) {
                final item =
                    _items.firstWhere((element) => element.id == itemId);
                await _deletePantryItem(item, firestoreService);
              }
              setState(() {
                _selectedItemIds.clear();
                _inMultiSelectMode = false; // Exit multi-select mode
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _bigTitle() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Text('Pantry Inventory',
          style: TextStyle(
              color: Color(0xFF20451F),
              fontSize: 24,
              fontWeight: FontWeight.w900)),
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSearch,
              ),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: sep)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: sep)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: headerGreen)),
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
                  _dropdownPill(
                      label: 'Sort by',
                      value: sortBy,
                      items: _sortOptions,
                      onChanged: (v) => setState(() => sortBy = v!)),
                  _dropdownPill(
                      label: 'Filter',
                      value: filterBy,
                      items: _filterOptions,
                      onChanged: (v) => setState(() => filterBy = v!)),
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
}
