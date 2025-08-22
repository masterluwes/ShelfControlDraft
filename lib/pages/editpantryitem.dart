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
    required PantryItem item, // kept as in your signature
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
  // Palette
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

  // Category options
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

  // ---- Date helpers / validator ----
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
        data: Theme.of(ctx).copyWith(
          // Calendar theming lives here
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: headerGreen),
          ),
        ),
        child: child!,
      ),
    );
    if (result != null) {
      onPicked(result);
      controller.text = _friendlyDate(result);
      setState(() {});
    }
  }

  String? _validateExpiryField(String? _) {
    DateTime toDayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

    final now = toDayOnly(DateTime.now());

    if (_expiry == null || _expiryCtrl.text.trim().isEmpty) {
      return 'Required';
    }

    final exp = toDayOnly(_expiry!);

    if (exp.isBefore(now)) {
      return 'Expiration date can’t be in the past';
    }

    if (_purchase != null && exp.isBefore(toDayOnly(_purchase!))) {
      return 'Expiration must be after purchase date';
    }

    return null;
  }

  // ---- Field decoration / label ----
  InputDecoration _fieldDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      fontFamily: 'Inter',
      fontSize: 14,
      color: Color.fromARGB(255, 105, 105, 105),
    ),
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
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 15,
        color: Color(0xFF000000),
      ),
    ),
  );

  // ---- UI ----
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
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w900,
                    fontSize: 32,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 22),

                // Item Name
                _label('Item Name'),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: _fieldDecoration('Ketchup (397g)'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Item Category
                _label('Item Category'),
                DropdownButtonHideUnderline(
                  child: DropdownButton2<String>(
                    isExpanded: true,
                    value: _category,
                    hint: const Text(
                      'Select Category',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        backgroundColor: Color(0xFF2E7D32),
                      ),
                    ),
                    // Style for the selected value (closed button text)
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    items: _categoryOptions
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c,
                            child: Text(
                              c,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: Color(0xFFFFFFFF),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _category = val),
                    dropdownStyleData: DropdownStyleData(
                      maxHeight: 240,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                      offset: const Offset(0, 4),
                    ),
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

                // Quantity
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

                // Expiration Date
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
                  validator: _validateExpiryField,
                ),
                const SizedBox(height: 16),

                // Date of Purchase
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

                // Notes
                _label('Notes (Optional)'),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 5,
                  decoration: _fieldDecoration("Don't put it on the fridge!"),
                ),
                const SizedBox(height: 24),

                // Actions
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

  // ---- Save ----
  void _save() {
    // Run field validators first
    if (!_formKey.currentState!.validate()) return;

    // Category required (since DropdownButton2 isn’t a FormField by default)
    if (_category == null || _category!.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    // Parse quantity safely
    final qty = int.tryParse(_qtyCtrl.text.trim());
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid quantity')));
      return;
    }

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
