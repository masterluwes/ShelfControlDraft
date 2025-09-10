import 'package:flutter/material.dart';
import 'package:shelf_control/models/pantry_item_model.dart'; // Import PantryItemModel

import 'package:intl/intl.dart';

class EditPantryItem extends StatefulWidget {
  final PantryItemModel item;
  final VoidCallback onBack;
  final Function(PantryItemModel) onSave;

  const EditPantryItem({super.key, required this.item, required this.onBack, required this.onSave});

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

  String? _selectedCategory;
  final List<String> _categories = <String>[
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
    _selectedCategory = widget.item.category; // Initialize with item's category
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _expCtrl.dispose();
    _dopCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final updatedItem = PantryItemModel(
      id: widget.item.id,
      name: _nameCtrl.text,
      category: _selectedCategory!,
      imageUrl: widget.item.imageUrl, // Keep existing image URL
      qty: int.tryParse(_qtyCtrl.text) ?? 1,
      expiresText: _expCtrl.text,
      barcode: widget.item.barcode,
      brand: widget.item.brand,
      quantityUnit: widget.item.quantityUnit,
      nutritionFacts: widget.item.nutritionFacts,
      shelfLifeDays: widget.item.shelfLifeDays,
      shelfLifeWeeks: widget.item.shelfLifeWeeks,
      shelfLifeMonths: widget.item.shelfLifeMonths,
      manufacturedDate: DateFormat('MMMM d, yyyy').parse(_dopCtrl.text),
      expirationDate: DateFormat('MMMM d, yyyy').parse(_expCtrl.text),
      netWeight: widget.item.netWeight,
      selected: widget.item.selected,
    );
    widget.onSave(updatedItem);
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
    return Container(
      color: softCream,
      width: double.infinity,
      child: SafeArea(
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
                      onPressed: widget.onBack,
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

                // Item Category (green dropdown)
                _label('Item Category'),
                _greenDropdown(),
                const SizedBox(height: 14),

                // Quantity
                _label('Quantity'),
                _filledField(_qtyCtrl, keyboardType: TextInputType.number), // Set keyboardType
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
                      onPressed: widget.onBack,
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
                      onPressed: _saveChanges,
                      child: const Text('Save'),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              // Delete button
              Center(
                child: TextButton(
                  onPressed: () {
                    // Implement delete functionality
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
