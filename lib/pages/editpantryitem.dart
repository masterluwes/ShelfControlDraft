import 'package:flutter/material.dart';
import 'package:guests_main/pages/pantryinventory.dart';

class EditPantryItem extends StatefulWidget {
  const EditPantryItem({super.key, required PantryItem item});

  @override
  State<EditPantryItem> createState() => _EditPantryItemBodyState();
}

class _EditPantryItemBodyState extends State<EditPantryItem> {
  // Colors consistent with your app
  final Color headerGreen = const Color(0xFF2E7D32);
  final Color softCream = const Color(0xFFFFFBE6);

  // Controllers / state
  final _nameCtrl = TextEditingController(text: 'Ketchup (397g)');
  final _qtyCtrl = TextEditingController(text: '1');
  final _expCtrl = TextEditingController(text: 'June 30, 2025');
  final _dopCtrl = TextEditingController(text: 'January 5, 2025');
  final _notesCtrl = TextEditingController(text: "Don't put it on the fridge!");

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
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _expCtrl.dispose();
    _dopCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
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
      keyboardType: maxLines == 1
          ? TextInputType.text
          : TextInputType.multiline,
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
    // BODY ONLY — place this inside your Scaffold that already uses the back-only top bar
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
              // Page title
              Text(
                'Edit Pantry Item',
                style: TextStyle(
                  color: headerGreen,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 16),

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
              _filledField(_qtyCtrl),
              const SizedBox(height: 14),

              // Expiration Date
              _label('Expiration Date'),
              _filledField(
                _expCtrl,
                readOnly: true,
                onTap: () async {
                  // Optional date picker if you want interaction:
                  // final picked = await showDatePicker(...);
                },
              ),
              const SizedBox(height: 14),

              // Date of Purchase
              _label('Date of Purchase'),
              _filledField(
                _dopCtrl,
                readOnly: true,
                onTap: () async {
                  // Optional date picker if you want interaction
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
                    onPressed: () => Navigator.maybePop(context),
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
                    onPressed: () {
                      // TODO: save edits
                      Navigator.maybePop(context);
                    },
                    child: const Text('Edit'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
