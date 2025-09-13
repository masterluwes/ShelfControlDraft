import 'package:flutter/material.dart';
import 'package:shelf_control/models/pantry_item_model.dart'; // Import PantryItemModel

import 'package:intl/intl.dart';
import 'package:shelf_control/services/firestore_service.dart'; // Import FirestoreService
import 'package:provider/provider.dart'; // Import provider

class EditPantryItem extends StatefulWidget {
  final PantryItemModel item;

  const EditPantryItem({super.key, required this.item});

  @override
  State<EditPantryItem> createState() => _EditPantryItemBodyState();
}

class _EditPantryItemBodyState extends State<EditPantryItem> {
  // Colors consistent with your app
  final Color headerGreen = const Color(0xFF2E7D32);
  final Color softCream = const Color(0xFFFFFBE6);

  // Controllers / state
  late TextEditingController _nameCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _expCtrl;
  late TextEditingController _dopCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _barcodeCtrl;
  late TextEditingController _brandCtrl;
  late TextEditingController _quantityUnitCtrl;
  late TextEditingController _netWeightCtrl;

  String? _selectedCategory;
  final List<String> _categories = <String>[
    'Uncategorized',
    'Beverages',
    'Canned Goods',
    'Dairy',
    'Dry Goods',
    'Snacks',
    'Condiments',
    'Frozen',
    'Produce',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.name);
    _qtyCtrl = TextEditingController(text: widget.item.qty.toString());
    _expCtrl = TextEditingController(text: widget.item.expirationDate != null ? DateFormat('MMMM d, yyyy').format(widget.item.expirationDate!) : '');
    _dopCtrl = TextEditingController(text: widget.item.manufacturedDate != null ? DateFormat('MMMM d, yyyy').format(widget.item.manufacturedDate!) : '');
    _notesCtrl = TextEditingController(text: ''); // Assuming notes are not part of PantryItemModel yet
    _barcodeCtrl = TextEditingController(text: widget.item.barcode ?? '');
    _brandCtrl = TextEditingController(text: widget.item.brand ?? '');
    _quantityUnitCtrl = TextEditingController(text: widget.item.quantityUnit ?? '');
    _netWeightCtrl = TextEditingController(text: widget.item.netWeight ?? '');
    _selectedCategory = widget.item.category; // Initialize with item's category
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _expCtrl.dispose();
    _dopCtrl.dispose();
    _notesCtrl.dispose();
    _barcodeCtrl.dispose();
    _brandCtrl.dispose();
    _quantityUnitCtrl.dispose();
    _netWeightCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges(FirestoreService firestoreService) async {
    if (firestoreService.selectedHouseholdId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No household selected. Cannot update item.')),
      );
      return;
    }

    final updatedItem = PantryItemModel(
      id: widget.item.id,
      householdId: firestoreService.selectedHouseholdId!, // Pass the selected household ID
      name: _nameCtrl.text,
      category: _selectedCategory!,
      imageUrl: widget.item.imageUrl, // Keep existing image URL
      qty: int.tryParse(_qtyCtrl.text) ?? 1,
      expiresText: _expCtrl.text,
      barcode: _barcodeCtrl.text.isEmpty ? null : _barcodeCtrl.text,
      brand: _brandCtrl.text.isEmpty ? null : _brandCtrl.text,
      quantityUnit: _quantityUnitCtrl.text.isEmpty ? null : _quantityUnitCtrl.text,
      nutritionFacts: widget.item.nutritionFacts,
      shelfLifeDays: widget.item.shelfLifeDays,
      shelfLifeWeeks: widget.item.shelfLifeWeeks,
      shelfLifeMonths: widget.item.shelfLifeMonths,
      manufacturedDate: _dopCtrl.text.isNotEmpty ? DateFormat('MMMM d, yyyy').parse(_dopCtrl.text) : null,
      expirationDate: _expCtrl.text.isNotEmpty ? DateFormat('MMMM d, yyyy').parse(_expCtrl.text) : null,
      netWeight: _netWeightCtrl.text.isEmpty ? null : _netWeightCtrl.text,
      selected: widget.item.selected,
    );
    await firestoreService.updatePantryItem(updatedItem);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  // Small label
  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2E2E2E),
        ),
      ),
    );
  }

  // Filled, rounded text field (looks like the screenshot)
  Widget _filledField(
    TextEditingController ctrl, {
    bool readOnly = false,
    int maxLines = 1,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text, // Added keyboardType
  }) {
    return TextField(
      controller: ctrl,
      readOnly: readOnly,
      maxLines: maxLines,
      onTap: onTap,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFE9E9E9),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      style: const TextStyle(fontSize: 14),
      keyboardType: keyboardType, // Used keyboardType
    );
  }

  // Green dropdown like in the mock
  Widget _greenDropdown() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: headerGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedCategory,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
          dropdownColor: Colors.white,
          hint: const Text(
            'Select Category',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          items: _categories
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(
                    c,
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                  ),
                ),
              )
              .toList(),
          onChanged: (val) => setState(() => _selectedCategory = val),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context); // Get the FirestoreService instance

    return Scaffold(
      backgroundColor: softCream,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom AppBar-like section
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2E7D32)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Text(
                      'Back',
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Edit Pantry Item',
                style: TextStyle(
                  color: headerGreen,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 24),
              // Item Name
              _label('Item Name'),
              _filledField(_nameCtrl),
              const SizedBox(height: 14),

              // Barcode
              _label('Barcode (Optional)'),
              _filledField(_barcodeCtrl),
              const SizedBox(height: 14),

              // Brand
              _label('Brand (Optional)'),
              _filledField(_brandCtrl),
              const SizedBox(height: 14),

              // Item Category (green dropdown)
              _label('Item Category'),
              _greenDropdown(),
              const SizedBox(height: 14),

              // Quantity
              _label('Quantity'),
              _filledField(_qtyCtrl, keyboardType: TextInputType.number), // Set keyboardType
              const SizedBox(height: 14),

              // Quantity Unit
              _label('Quantity Unit (e.g., "1L", "397g") (Optional)'),
              _filledField(_quantityUnitCtrl),
              const SizedBox(height: 14),

              // Net Weight
              _label('Net Weight (Optional)'),
              _filledField(_netWeightCtrl),
              const SizedBox(height: 14),

              // Expiration Date
              _label('Expiration Date'),
              _filledField(
                _expCtrl,
                readOnly: true,
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _expCtrl.text = DateFormat('MMMM d, yyyy').format(pickedDate);
                    });
                  }
                },
              ),
              const SizedBox(height: 14),

              // Date of Purchase
              _label('Date of Purchase'),
              _filledField(
                _dopCtrl,
                readOnly: true,
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _dopCtrl.text = DateFormat('MMMM d, yyyy').format(pickedDate);
                    });
                  }
                },
              ),
              const SizedBox(height: 14),

              // Notes
              _label('Notes (Optional)'),
              _filledField(_notesCtrl, maxLines: 5),
              const SizedBox(height: 22),

              // Action buttons
              Row(
                children: [
                  // Cancel (light with green border)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: headerGreen,
                      side: BorderSide(color: headerGreen, width: 1.2),
                      backgroundColor: softCream,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),

                  // Edit (solid green)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: headerGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    onPressed: () => _saveChanges(firestoreService),
                    child: const Text('Save'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Delete button
              Center(
                child: TextButton(
                  onPressed: () async {
                    if (widget.item.id != null) {
                      final navigator = Navigator.of(context);
                      await firestoreService.deletePantryItem(widget.item.id!);
                      if (!mounted) return;
                      navigator.pop(); // Pop after deleting
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  child: const Text('Delete Item'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
