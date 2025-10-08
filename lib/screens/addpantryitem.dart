import 'package:flutter/material.dart';
import 'package:shelf_control/models/pantry_item_model.dart'; // Import PantryItemModel
import 'package:shelf_control/models/product_model.dart'; // Import ProductModel
import 'package:intl/intl.dart';
import 'dart:io'; // Import dart:io for File

import 'package:shelf_control/services/firestore_service.dart'; // Import FirestoreService
import 'package:provider/provider.dart'; // Import provider
import 'package:image_picker/image_picker.dart'; // Import image_picker
import 'package:firebase_storage/firebase_storage.dart'; // Import firebase_storage
import 'package:shelf_control/screens/dashboard_page.dart'; // Import DashboardPage

class AddPantryItem extends StatefulWidget {
  final bool isGuest; // New parameter to indicate if it's a guest user
  const AddPantryItem({super.key, this.isGuest = false});

  @override
  State<AddPantryItem> createState() => _AddPantryItemBodyState();
}

class _AddPantryItemBodyState extends State<AddPantryItem> {
  final Color headerGreen = const Color(0xFF2E7D32);
  final Color softCream = const Color(0xFFFFFBE6);

  late TextEditingController _nameCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _expCtrl;
  late TextEditingController _dopCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _barcodeCtrl;
  late TextEditingController _brandCtrl;
  late TextEditingController _netWeightCtrl;

  String? _selectedCategory;
  File? _imageFile; // To store the picked image
  final ImagePicker _picker = ImagePicker(); // Image picker instance

  DateTime? _selectedExpDate; // To store the actual expiration date
  DateTime? _selectedDopDate; // To store the actual date of purchase

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
    _selectedDopDate = DateTime.now(); // Initialize with today's date
    _nameCtrl = TextEditingController(text: '');
    _qtyCtrl = TextEditingController(text: '1');
    _expCtrl = TextEditingController(text: '');
    _dopCtrl = TextEditingController(text: DateFormat('MMMM d, yyyy').format(_selectedDopDate!));
    _notesCtrl = TextEditingController(text: '');
    _barcodeCtrl = TextEditingController(text: '');
    _brandCtrl = TextEditingController(text: '');
    _netWeightCtrl = TextEditingController(text: '');
    _selectedCategory = null;
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) {
      return null; // No new image to upload
    }
    try {
      final storageRef = FirebaseStorage.instance.ref().child('pantry_item_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await storageRef.putFile(_imageFile!);
      return await storageRef.getDownloadURL();
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: ${e.toString()}')),
      );
      return null;
    }
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
    _netWeightCtrl.dispose();
    super.dispose();
  }

  Future<void> _registerItem(FirestoreService firestoreService) async {
    if (_nameCtrl.text.isEmpty || _selectedCategory == null || _qtyCtrl.text.isEmpty || _expCtrl.text.isEmpty || _selectedDopDate == null) {
      if (!mounted) return; // Guard against async gap
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    String? imageUrl;
    if (_imageFile != null) {
      imageUrl = await _uploadImage();
      if (imageUrl == null) {
        return; // Image upload failed
      }
    }

    final newItem = PantryItemModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      householdId: widget.isGuest ? 'guest_household' : firestoreService.selectedHouseholdId!, // Use a dummy ID for guests
      name: _nameCtrl.text,
      category: _selectedCategory!,
      imageUrl: imageUrl ?? 'https://via.placeholder.com/150',
      qty: int.tryParse(_qtyCtrl.text) ?? 1,
      expiresText: _expCtrl.text,
      barcode: _barcodeCtrl.text.isEmpty ? null : _barcodeCtrl.text,
      brand: _brandCtrl.text.isEmpty ? null : _brandCtrl.text,
      netWeight: _netWeightCtrl.text.isEmpty ? null : _netWeightCtrl.text,
      expirationDate: _selectedExpDate,
      manufacturedDate: _selectedDopDate,
      status: 'Available',
    );

    try {
      if (widget.isGuest) {
        List<PantryItemModel> guestPantry = await firestoreService.loadGuestPantryItems();
        guestPantry.add(newItem);
        await firestoreService.saveGuestPantryItems(guestPantry);
        if (!mounted) return;
        _returnToPantryWithStatus(context, newItem, isGuest: true);
      } else {
        if (firestoreService.selectedHouseholdId == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No household selected. Please select or create a household.')),
          );
          return;
        }
        await firestoreService.addPantryItem(newItem);
        if (!mounted) return;
        _returnToPantryWithStatus(context, newItem);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add item: ${e.toString()}')),
      );
    }
  }

  Widget label(String text) {
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

  Widget filledField(
    TextEditingController ctrl, {
    bool readOnly = false,
    int maxLines = 1,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
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
      keyboardType: keyboardType,
    );
  }

  Widget greenDropdown() {
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
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2E7D32)),
                      onPressed: () {
                        // When cancelling, just pop without a result
                        Navigator.of(context).pop();
                      },
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
                'Register Pantry Item',
                style: TextStyle(
                  color: headerGreen,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 24),
              // Image placeholder
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!) as ImageProvider
                        : null, // No initial image from item
                    child: _imageFile == null
                        ? Icon(
                            Icons.camera_alt,
                            color: Colors.grey[600],
                            size: 50,
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              label('Item Name'),
              Autocomplete<Product>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<Product>.empty();
                  }
                  return firestoreService.searchProducts(textEditingValue.text).first;
                },
                displayStringForOption: (Product option) => option.productName,
                fieldViewBuilder: (BuildContext context,
                    TextEditingController fieldTextEditingController,
                    FocusNode fieldFocusNode,
                    VoidCallback onFieldSubmitted) {
                  _nameCtrl = fieldTextEditingController; // Keep _nameCtrl updated
                  return TextField(
                    controller: fieldTextEditingController,
                    focusNode: fieldFocusNode,
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
                  );
                },
                onSelected: (Product selection) {
                  setState(() {
                    _nameCtrl.text = selection.productName;
                    _netWeightCtrl.text = selection.netWeight ?? '';
                    // Optionally set brand if available in Product model
                    // _brandCtrl.text = selection.brand ?? '';
                  });
                },
              ),
              const SizedBox(height: 14),
              label('Barcode (Optional)'),
              filledField(_barcodeCtrl),
              const SizedBox(height: 14),
              label('Brand (Optional)'),
              filledField(_brandCtrl),
              const SizedBox(height: 14),
              label('Item Category'),
              greenDropdown(),
              const SizedBox(height: 14),
              label('Quantity'),
              filledField(_qtyCtrl, keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              label('Net Weight (e.g., "1L", "397g") (Optional)'),
              filledField(_netWeightCtrl),
              const SizedBox(height: 14),
              label('Expiration Date'),
              filledField(
                _expCtrl,
                readOnly: true,
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedExpDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _selectedExpDate = pickedDate;
                      _expCtrl.text = DateFormat('MMMM d, yyyy').format(pickedDate);
                    });
                  }
                },
              ),
              const SizedBox(height: 14),
              label('Date of Purchase'),
              filledField(
                _dopCtrl,
                readOnly: true,
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDopDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _selectedDopDate = pickedDate;
                      _dopCtrl.text = DateFormat('MMMM d, yyyy').format(pickedDate);
                    });
                  }
                },
              ),
              const SizedBox(height: 14),
              label('Notes (Optional)'),
              filledField(_notesCtrl, maxLines: 5),
              const SizedBox(height: 22),
              Row(
                children: [
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
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const DashboardPage(initialIndex: 1)), // Navigate back to Dashboard with Pantry tab
                        (Route<dynamic> route) => false, // Remove all routes from the stack
                      );
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
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
                    onPressed: () => _registerItem(firestoreService),
                    child: const Text('Register'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper to return to pantry with item status for banner
  void _returnToPantryWithStatus(BuildContext context, PantryItemModel item, {bool isGuest = false}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expirationDay = item.expirationDate != null ? DateTime(item.expirationDate!.year, item.expirationDate!.month, item.expirationDate!.day) : null;
    final difference = expirationDay?.difference(today).inDays;

    String status = 'none';
    if (difference != null) {
      if (difference < 0) {
        status = 'expired';
      } else if (difference <= 7) { // Using a default of 7 days for UI feedback
        status = 'atRisk';
      }
    }

    Navigator.of(context).pop({
      'status': status,
      'itemName': item.name,
    });
  }
}
