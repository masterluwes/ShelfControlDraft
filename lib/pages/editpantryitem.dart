import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:guests_main/pages/pantryinventory.dart';

class EditPantryItem extends StatefulWidget {
  const EditPantryItem({
    super.key,
    this.initialName = '',
    this.initialCategory,
    this.initialQuantity = 1,
    this.initialExpiry,
    this.initialPurchaseDate,
    this.initialNotes = '',
    this.categories,
    required PantryItem item,
  });

  final String initialName;
  final String? initialCategory;
  final int initialQuantity;
  final DateTime? initialExpiry;
  final DateTime? initialPurchaseDate;
  final String initialNotes;
  final List<String>? categories;

  @override
  State<EditPantryItem> createState() => _EditPantryItemState();
}

class _EditPantryItemState extends State<EditPantryItem> {
  // Palette to match screenshot
  final Color headerGreen = const Color(0xFF2E7D32);
  final Color softCream = const Color(0xFFFFFBE6);

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _expiryCtrl;
  late final TextEditingController _purchaseCtrl;
  late final TextEditingController _notesCtrl;

  String? _category;
  DateTime? _expiry;
  DateTime? _purchase;

  List<String> get _categoryOptions =>
      widget.categories ??
      const [
        'Beverages',
        'Canned Goods',
        'Dairy',
        'Snacks',
        'Produce',
        'Meat',
        'Bakery',
        'Household',
        'Other',
      ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _qtyCtrl = TextEditingController(text: widget.initialQuantity.toString());
    _notesCtrl = TextEditingController(text: widget.initialNotes);

    _category = widget.initialCategory;

    _expiry = widget.initialExpiry;
    _purchase = widget.initialPurchaseDate;

    _expiryCtrl = TextEditingController(
      text: _expiry != null ? _friendlyDate(_expiry!) : '',
    );
    _purchaseCtrl = TextEditingController(
      text: _purchase != null ? _friendlyDate(_purchase!) : '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _expiryCtrl.dispose();
    _purchaseCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _friendlyDate(DateTime d) =>
      '${_monthNames[d.month - 1]} ${d.day}, ${d.year}';

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  Future<void> _pickDate({
    required TextEditingController controller,
    required DateTime? initial,
    required ValueChanged<DateTime?> onPicked,
  }) async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: ColorScheme.fromSeed(seedColor: headerGreen)),
        child: child!,
      ),
    );
    if (result != null) {
      onPicked(result);
      controller.text = _friendlyDate(result);
      setState(() {});
    }
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: const Color(0xFFE9E9E9),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: headerGreen, width: 1.2),
    ),
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12.5, color: Colors.black87),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softCream,
      appBar: AppBar(
        backgroundColor: headerGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
        titleSpacing: 0,
        title: const Text(
          'Back',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Pantry Item',
                  style: TextStyle(
                    color: headerGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 22),

                _label('Item Name'),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: _fieldDecoration('Ketchup (397g)'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                _label('Item Category'),
                // --- Green pill dropdown using DropdownButton2
                DropdownButtonHideUnderline(
                  child: DropdownButton2<String>(
                    isExpanded: true,
                    value: _category,
                    hint: const Text(
                      'Select Category',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    items: _categoryOptions
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c,
                            child: Text(
                              c,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _category = val),
                    // Ensure the menu ONLY shows below the button
                    dropdownStyleData: DropdownStyleData(
                      maxHeight: 240,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                      offset: const Offset(0, 4),
                    ),
                    // Style the green "main dropdown" button
                    buttonStyleData: ButtonStyleData(
                      height: 42,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: headerGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    iconStyleData: const IconStyleData(
                      icon: Icon(Icons.expand_more, color: Colors.white),
                    ),
                    menuItemStyleData: const MenuItemStyleData(height: 42),
                  ),
                ),
                const SizedBox(height: 16),

                _label('Quantity'),
                TextFormField(
                  controller: _qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _fieldDecoration('1'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final n = int.tryParse(v);
                    if (n == null || n <= 0) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _label('Expiration Date'),
                TextFormField(
                  controller: _expiryCtrl,
                  readOnly: true,
                  onTap: () => _pickDate(
                    controller: _expiryCtrl,
                    initial: _expiry,
                    onPicked: (d) => _expiry = d,
                  ),
                  decoration: _fieldDecoration('June 30, 2025'),
                ),
                const SizedBox(height: 16),

                _label('Date of Purchase'),
                TextFormField(
                  controller: _purchaseCtrl,
                  readOnly: true,
                  onTap: () => _pickDate(
                    controller: _purchaseCtrl,
                    initial: _purchase,
                    onPicked: (d) => _purchase = d,
                  ),
                  decoration: _fieldDecoration('January 5, 2025'),
                ),
                const SizedBox(height: 16),

                _label('Notes (Optional)'),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 5,
                  decoration: _fieldDecoration("Don't put it on the fridge!"),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: headerGreen),
                          foregroundColor: headerGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: headerGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        onPressed: _save,
                        child: const Text('Edit'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final qty = int.parse(_qtyCtrl.text);

    Navigator.of(context).pop({
      'name': _nameCtrl.text.trim(),
      'category': _category,
      'quantity': qty,
      'expiry': _expiry?.toIso8601String(),
      'purchaseDate': _purchase?.toIso8601String(),
      'notes': _notesCtrl.text.trim(),
    });
  }
}
