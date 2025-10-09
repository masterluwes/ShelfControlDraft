import 'package:flutter/material.dart';
import 'package:shelf_control/models/pantry_item_model.dart'; // Import PantryItemModel
import 'package:shelf_control/models/product_model.dart'; // Import ProductModel
import 'package:intl/intl.dart';
import 'dart:io'; // Import dart:io for File
import 'dart:async'; // Import for Timer

// import 'package:fuzzywuzzy/fuzzywuzzy.dart'; // Removed fuzzywuzzy

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
  late TextEditingController _netWeightCtrl;

  String? _selectedCategory;
  File? _imageFile; // To store the picked image
  final ImagePicker _picker = ImagePicker(); // Image picker instance

  DateTime? _selectedExpDate; // To store the actual expiration date
  DateTime? _selectedDopDate; // To store the actual date of purchase

  Timer? _debounce; // For autocomplete debouncing

  // For optional shelf life calculator
  bool _showShelfLifeCalculator = false;
  late TextEditingController _shelfLifeValueCtrl;
  String? _selectedShelfLifeUnit;
  final List<String> _shelfLifeUnits = ['Days', 'Weeks', 'Months', 'Years'];

  final List<String> _categories = <String>[
    'Beverages',
    'Canned Goods',
    'Condiments',
    'Dairy',
    'Dry Goods',
    'Snacks',
    'Other',
  ];

  // Define default shelf lives for categories in days based on research
  // Define default shelf lives for categories in days based on research
  // These are general defaults; specific items will override in _updateExpirationDateFromCategory
  final Map<String, int> _categoryShelfLives = {
    'Beverages': 270, // 9 months (general, UHT milk/juice longer, fresh juice shorter)
    'Canned Goods': 730, // 2 years
    'Condiments': 365, // 12 months (unopened)
    'Dairy': 14, // 2 weeks (for refrigerated items like milk, yogurt)
    'Dry Goods': 547, // 18 months (rice, pasta, flour)
    'Snacks': 180, // 6 months
    'Other': 180, // 6 months
  };

  // More granular shelf lives for specific subcategories/keywords
  final Map<String, Map<String, int>> _subcategoryShelfLives = {
    'Dairy': {
      'fresh milk': 7,
      'powdered milk': 270, // 9 months
      'cheese': 60, // 2 months (hard cheese, softer cheese shorter)
      'yogurt': 21, // 3 weeks
      'butter': 90, // 3 months
      'eggs': 30, // 1 month
    },
    'Beverages': {
      'fresh juice': 7,
      'uht milk': 270, // 9 months
      'coffee': 365, // 12 months (unopened)
      'tea': 730, // 2 years
      'soda': 180, // 6 months
      'water': 730, // 2 years
    },
    'Condiments': {
      'vinegar': 730, // 2 years
      'soy sauce': 365, // 1 year
      'ketchup': 365, // 1 year
      'mustard': 365, // 1 year
      'dressing': 180, // 6 months
      'spices': 730, // 2 years
      'powder': 730, // 2 years
      'salt': 1825, // 5 years
      // 'sugar': 1825, // Moved to Dry Goods
    },
    'Dry Goods': {
      'rice': 730, // 2 years
      'pasta': 730, // 2 years
      'flour': 180, // 6 months
      'cereal': 180, // 6 months
      'oil': 365, // 1 year
      'beans': 730, // 2 years (dried)
      'sugar': 1825, // 5 years (moved from Condiments)
    },
    'Snacks': {
      'chips': 90, // 3 months
      'crackers': 180, // 6 months
      'cookies': 180, // 6 months
      'chocolates': 270, // 9 months
      'biscuits': 180, // 6 months (from Bakery)
      'packed fudge bars': 180, // 6 months (from Bakery)
      'mamon': 7, // 1 week (from Bakery)
      'donut': 3, // 3 days (from Bakery)
      'pandesal': 7, // 1 week (from Bakery)
      'ensaymada': 7, // 1 week (from Bakery)
    }
  };

  @override
  void initState() {
    super.initState();
    _selectedDopDate = DateTime.now(); // Initialize with today's date
    _nameCtrl = TextEditingController(text: '');
    _qtyCtrl = TextEditingController(text: '1');
    _expCtrl = TextEditingController(text: '');
    _dopCtrl = TextEditingController(text: DateFormat('MMMM d, yyyy').format(_selectedDopDate!));
    _notesCtrl = TextEditingController(text: '');
    _netWeightCtrl = TextEditingController(text: '');
    _selectedCategory = 'Other'; // Default to 'Other' instead of null or 'Uncategorized'
    _shelfLifeValueCtrl = TextEditingController(text: '');
    _selectedShelfLifeUnit = 'Days'; // Default unit
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
    _netWeightCtrl.dispose();
    _shelfLifeValueCtrl.dispose();
    super.dispose();
  }

  String? _suggestCategoryFromName(String itemName) {
    itemName = itemName.toLowerCase();

    // Define keywords for each category, prioritizing more specific ones
    final Map<String, List<String>> categoryKeywords = {
      'Dairy': ['milk', 'yogurt', 'cheese', 'butter', 'margarine', 'spread', 'cream', 'eggs', 'evaporada', 'condensada'],
      'Beverages': ['coffee', 'tea', 'juice', 'soda', 'water', 'chocolate drink', 'malt', 'drink', 'softdrink', 'powdered drink'],
      'Canned Goods': ['canned', 'beans', 'soup', 'tuna', 'sardines', 'corned beef', 'meat loaf', 'luncheon meat', 'fruit cocktail'],
      'Dry Goods': ['rice', 'pasta', 'flour', 'cereal', 'grains', 'seeds', 'oil', 'legumes', 'beans', 'soup mix', 'broth', 'noodles', 'sago', 'oats', 'oatmeal', 'sugar'], // Added sugar
      'Snacks': [
        'chips', 'crackers', 'cookies', 'nuts', 'candies', 'chocolates', 'biscuits', 'dips', 'wafer', 'bar', 'pastillas', 'polvoron',
        'bread', 'cake', 'pastries', 'baking needs', 'buns', 'muffin', 'donut', 'pandesal', 'ensaymada', 'packed fudge bars', 'mamon' // Merged from Bakery
      ],
      'Condiments': ['vinegar', 'soy sauce', 'ketchup', 'mustard', 'dressing', 'sauce', 'spices', 'powder', 'salt', 'bbq', 'seasoning', 'garlic bits', 'bagoong', 'chili', 'patis', 'fish sauce'], // Removed sugar
      'Other': [], // Explicitly define 'Other' for clarity, though it's the fallback
    };

    // Iterate through categories and their keywords to find a match
    for (final categoryEntry in categoryKeywords.entries) {
      final category = categoryEntry.key;
      final keywords = categoryEntry.value;
      for (final keyword in keywords) {
        if (itemName.contains(keyword)) {
          return category;
        }
      }
    }

    return 'Other'; // Default if no strong match
  }

  void _calculateExpirationDate({bool forceUpdate = false}) {
    // Only calculate if the expiration date is not manually set, or if forced
    if ((_expCtrl.text.isEmpty || forceUpdate) && _selectedDopDate != null && _shelfLifeValueCtrl.text.isNotEmpty && _selectedShelfLifeUnit != null) {
      final int? value = int.tryParse(_shelfLifeValueCtrl.text);
      if (value == null || value <= 0) return;

      DateTime calculatedExpDate = _selectedDopDate!;
      switch (_selectedShelfLifeUnit) {
        case 'Days':
          calculatedExpDate = _selectedDopDate!.add(Duration(days: value));
          break;
        case 'Weeks':
          calculatedExpDate = _selectedDopDate!.add(Duration(days: value * 7));
          break;
        case 'Months':
          calculatedExpDate = DateTime(_selectedDopDate!.year, _selectedDopDate!.month + value, _selectedDopDate!.day);
          break;
        case 'Years':
          calculatedExpDate = DateTime(_selectedDopDate!.year + value, _selectedDopDate!.month, _selectedDopDate!.day);
          break;
      }

      setState(() {
        _selectedExpDate = calculatedExpDate;
        _expCtrl.text = DateFormat('MMMM d, yyyy').format(_selectedExpDate!);
      });
    }
  }

  void _updateExpirationDateFromCategory({bool forceUpdate = false}) {
    // Only update if the expiration date is not manually set, or if forced
    if ((_expCtrl.text.isEmpty || forceUpdate) && _selectedCategory != null && _selectedDopDate != null) {
      int? shelfLife = _categoryShelfLives[_selectedCategory];
      String itemName = _nameCtrl.text.toLowerCase();

      // Check for more granular shelf lives based on subcategory keywords
      if (_subcategoryShelfLives.containsKey(_selectedCategory)) {
        final subcategoryMap = _subcategoryShelfLives[_selectedCategory]!;
        for (final subcategoryEntry in subcategoryMap.entries) {
          final subcategoryKeyword = subcategoryEntry.key;
          final subcategorySpecificShelfLife = subcategoryEntry.value;
          if (itemName.contains(subcategoryKeyword)) {
            shelfLife = subcategorySpecificShelfLife;
            break; // Found a more specific match, use it
          }
        }
      }

      if (shelfLife != null) {
        setState(() {
          _selectedExpDate = _selectedDopDate!.add(Duration(days: shelfLife!)); // Use null-assertion operator
          _expCtrl.text = DateFormat('MMMM d, yyyy').format(_selectedExpDate!);
        });
      }
    }
  }

  Future<void> _registerItem(FirestoreService firestoreService) async {
    // Attempt to suggest category if not already set
    if (_selectedCategory == null || _selectedCategory == 'Other' && _nameCtrl.text.isNotEmpty) {
      setState(() {
        _selectedCategory = _suggestCategoryFromName(_nameCtrl.text);
      });
    }

    // After category is set (either by user or suggestion), attempt to set expiration date
    _updateExpirationDateFromCategory();

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
    ValueChanged<String>? onChanged, // Add onChanged parameter
  }) {
    return TextField(
      controller: ctrl,
      readOnly: readOnly,
      maxLines: maxLines,
      onTap: onTap,
      onChanged: onChanged, // Pass onChanged to TextField
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
          onChanged: (val) {
            setState(() {
              _selectedCategory = val;
              _updateExpirationDateFromCategory(); // Update expiration date when category changes
            });
          },
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
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<Product>.empty();
                  }

                  // Debounce the search
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  await Future.delayed(const Duration(milliseconds: 300)); // Small delay for better UX

                  final products = await firestoreService.searchProducts(textEditingValue.text).first;
                  return products.take(5); // Limit to 5 suggestions
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
                    onChanged: (value) {
                      // Trigger category suggestion and expiration date update on manual text change
                      setState(() {
                        _selectedCategory = _suggestCategoryFromName(value);
                        _updateExpirationDateFromCategory();
                      });
                    },
                  );
                },
                onSelected: (Product selection) {
                  setState(() {
                    _nameCtrl.text = selection.productName;
                    _netWeightCtrl.text = selection.netWeight ?? '';
                    if (selection.category != null) {
                      _selectedCategory = selection.category;
                    } else {
                      // If product from autocomplete doesn't have a category, try to suggest one
                      _selectedCategory = _suggestCategoryFromName(selection.productName);
                    }

                    // If the selected product has a manufactured date, use it for DOP
                    if (selection.manufacturedDate != null) {
                      _selectedDopDate = selection.manufacturedDate;
                      _dopCtrl.text = DateFormat('MMMM d, yyyy').format(_selectedDopDate!);
                    } else {
                      // Otherwise, reset DOP to today if no specific date is available
                      _selectedDopDate = DateTime.now();
                      _dopCtrl.text = DateFormat('MMMM d, yyyy').format(_selectedDopDate!);
                    }

                    // Attempt to set expiration date based on category default, forcing an update
                    _updateExpirationDateFromCategory(forceUpdate: true);
                  });
                },
              ),
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
              Row(
                children: [
                  label('Expiration Date'),
                  const SizedBox(width: 8),
                  // Tooltip for expiration date guidance
                  Tooltip(
                    message: 'Look for "EXP", "USE BY", or "BEST BEFORE" on the lid, bottom, or side of the packaging. Dates are typically in Day-Month-Year format (e.g., 09 September 2025). On mobile, long-press to view this tip.',
                    child: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
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
                        // Clear shelf life calculator fields if expiration date is manually set
                        _shelfLifeValueCtrl.clear();
                        _selectedShelfLifeUnit = 'Days';
                      });
                    }
                  },
                ),
                const SizedBox(height: 14),
                // Optional Shelf Life Calculator Section
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showShelfLifeCalculator = !_showShelfLifeCalculator;
                      if (_showShelfLifeCalculator) {
                        // If showing, try to calculate based on existing data
                        _calculateExpirationDate(forceUpdate: true);
                      } else {
                        // If hiding, clear shelf life calculator fields
                        _shelfLifeValueCtrl.clear();
                        _selectedShelfLifeUnit = 'Days';
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          _showShelfLifeCalculator ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: headerGreen,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Calculate from Production Date (Optional)',
                          style: TextStyle(
                            color: headerGreen,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showShelfLifeCalculator) ...[
                  const SizedBox(height: 14),
                  label('Production Date'),
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
                          _calculateExpirationDate(forceUpdate: true); // Recalculate expiration if DOP changes
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  label('Shelf Life Duration'),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: filledField(
                          _shelfLifeValueCtrl,
                          keyboardType: TextInputType.number,
                          onTap: () {
                            // Clear expiration date if user starts typing here
                            setState(() {
                              _expCtrl.text = '';
                              _selectedExpDate = null;
                            });
                          },
                          onChanged: (value) {
                            _calculateExpirationDate(forceUpdate: true);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: headerGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: _selectedShelfLifeUnit,
                              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                              dropdownColor: Colors.white,
                              hint: const Text(
                                'Unit',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                              items: _shelfLifeUnits
                                  .map(
                                    (unit) => DropdownMenuItem(
                                      value: unit,
                                      child: Text(
                                        unit,
                                        style: const TextStyle(color: Colors.black87, fontSize: 14),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedShelfLifeUnit = val;
                                  _calculateExpirationDate(forceUpdate: true); // Recalculate expiration if unit changes
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
