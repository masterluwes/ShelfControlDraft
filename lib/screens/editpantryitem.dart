import 'package:flutter/material.dart';
import 'package:shelf_control/models/pantry_item_model.dart'; // Import PantryItemModel
import 'package:shelf_control/models/product_model.dart'; // Import ProductModel

import 'package:intl/intl.dart';
import 'dart:io'; // Import dart:io for File
import 'dart:async'; // Import for Timer

import 'package:shelf_control/services/firestore_service.dart'; // Import FirestoreService
import 'package:provider/provider.dart'; // Import provider
import 'package:image_picker/image_picker.dart'; // Import image_picker
import 'package:firebase_storage/firebase_storage.dart'; // Import firebase_storage
import 'package:shelf_control/screens/recipe_suggestions_page.dart'; // Import RecipeSuggestionsPage

class EditPantryItem extends StatefulWidget {
  final PantryItemModel item;
  final bool isViewing; // New parameter

  const EditPantryItem({super.key, required this.item, this.isViewing = false});

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
  File? _imageFile; // To store the picked image
  final ImagePicker _picker = ImagePicker(); // Image picker instance

  Timer? _debounce; // For autocomplete debouncing

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
    _nameCtrl = TextEditingController(text: widget.item.name);
    _qtyCtrl = TextEditingController(text: widget.item.qty.toString());
    _expCtrl = TextEditingController(text: widget.item.expirationDate != null ? DateFormat('MMMM d, yyyy').format(widget.item.expirationDate!) : '');
    _dopCtrl = TextEditingController(text: widget.item.manufacturedDate != null ? DateFormat('MMMM d, yyyy').format(widget.item.manufacturedDate!) : '');
    _notesCtrl = TextEditingController(text: widget.item.notes ?? ''); // Initialize with item's notes
    _barcodeCtrl = TextEditingController(text: widget.item.barcode ?? '');
    _brandCtrl = TextEditingController(text: widget.item.brand ?? '');
    _quantityUnitCtrl = TextEditingController(text: widget.item.netWeight ?? '');
    _netWeightCtrl = TextEditingController(); // No longer used
    _selectedCategory = widget.item.category; // Initialize with item's category
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
    _quantityUnitCtrl.dispose();
    _netWeightCtrl.dispose();
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

  void _updateExpirationDateFromCategory({bool forceUpdate = false}) {
    // Only update if the expiration date is not manually set, or if forced
    if ((_expCtrl.text.isEmpty || forceUpdate) && _selectedCategory != null && widget.item.manufacturedDate != null) {
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
          _expCtrl.text = DateFormat('MMMM d, yyyy').format(widget.item.manufacturedDate!.add(Duration(days: shelfLife!)));
        });
      }
    }
  }

  Future<void> _saveChanges(FirestoreService firestoreService) async {
    if (firestoreService.selectedHouseholdId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No household selected. Cannot update item.')),
      );
      return;
    }

    String? newImageUrl = widget.item.imageUrl;
    if (_imageFile != null) {
      newImageUrl = await _uploadImage();
      if (newImageUrl == null) {
        return; // Image upload failed
      }
    }

    // Attempt to suggest category if not already set or if it's 'Other'
    if (_selectedCategory == null || _selectedCategory == 'Other' && _nameCtrl.text.isNotEmpty) {
      setState(() {
        _selectedCategory = _suggestCategoryFromName(_nameCtrl.text);
      });
    }

    // After category is set (either by user or suggestion), attempt to set expiration date
    _updateExpirationDateFromCategory();

    final updatedItem = PantryItemModel(
      id: widget.item.id,
      householdId: firestoreService.selectedHouseholdId!, // Pass the selected household ID
      name: _nameCtrl.text,
      category: _selectedCategory!,
      imageUrl: newImageUrl, // Use the new image URL
      qty: int.tryParse(_qtyCtrl.text) ?? 1,
      expiresText: _expCtrl.text,
      barcode: _barcodeCtrl.text.isEmpty ? null : _barcodeCtrl.text,
      brand: _brandCtrl.text.isEmpty ? null : _brandCtrl.text,
      quantityUnit: null,
      netWeight: _quantityUnitCtrl.text.isEmpty ? null : _quantityUnitCtrl.text,
      nutritionFacts: widget.item.nutritionFacts,
      shelfLifeDays: widget.item.shelfLifeDays,
      shelfLifeWeeks: widget.item.shelfLifeWeeks,
      shelfLifeMonths: widget.item.shelfLifeMonths,
      manufacturedDate: _dopCtrl.text.isNotEmpty ? DateFormat('MMMM d, yyyy').parse(_dopCtrl.text) : null,
      expirationDate: _expCtrl.text.isNotEmpty ? DateFormat('MMMM d, yyyy').parse(_expCtrl.text) : null,
      selected: widget.item.selected,
      notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text, // Save notes
    );
    await firestoreService.updatePantryItem(updatedItem);
    if (!mounted) return;

    // Determine the status of the item to pass back to the pantry screen
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expirationDay = updatedItem.expirationDate != null ? DateTime(updatedItem.expirationDate!.year, updatedItem.expirationDate!.month, updatedItem.expirationDate!.day) : null;
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
      'itemName': updatedItem.name,
    });
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
      keyboardType: keyboardType, // Used keyboardType
    );
  }

  // Green dropdown like in the mock
  Widget _greenDropdown({bool readOnly = false}) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: readOnly ? const Color(0xFFE9E9E9) : headerGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedCategory,
          icon: Icon(Icons.keyboard_arrow_down, color: readOnly ? Colors.black54 : Colors.white),
          dropdownColor: Colors.white,
          hint: Text(
            'Select Category',
            style: TextStyle(color: readOnly ? Colors.black54 : Colors.white, fontWeight: FontWeight.w600),
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
          onChanged: readOnly ? null : (val) => setState(() {
            _selectedCategory = val;
            _updateExpirationDateFromCategory(); // Update expiration date when category changes
          }),
        ),
      ),
    );
  }

  // Widget to display a read-only value
  Widget _displayField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFE9E9E9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.isEmpty ? 'N/A' : value,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  // Widget for Storage Location
  Widget _storageLocationSection() {
    final String storageLocation = widget.item.storageLocation ?? 'Not specified';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Storage Location'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFE9E9E9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            storageLocation,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  // Widget for Tips Section
  Widget _tipsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tips',
          style: TextStyle(
            color: headerGreen,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 12),
        _tipCard(
          title: 'Meal Plan Suggestions',
          content: 'This section will provide meal ideas using ${widget.item.name}.',
          icon: Icons.restaurant_menu,
        ),
        _tipCard(
          title: 'Proper Storage',
          content: 'Learn how to store ${widget.item.name} to maximize its shelf life.',
          icon: Icons.archive,
        ),
        _tipCard(
          title: 'Nutrition Information',
          content: 'Get detailed nutritional facts for ${widget.item.name}.',
          icon: Icons.food_bank, // Changed to a valid icon
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RecipeSuggestionsPage(itemName: widget.item.name),
              ),
            );
          },
          icon: const Icon(Icons.restaurant_menu, color: Colors.white),
          label: const Text(
            'Find Recipes',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: headerGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        const SizedBox(height: 22),
      ],
    );
  }

  // Helper for tip cards
  Widget _tipCard({required String title, required String content, required IconData icon}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: headerGreen, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: headerGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget for section titles
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(
          color: headerGreen,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
    );
  }

  // Helper widget for compact info fields
  Widget _compactInfoField({
    required String label,
    required String value,
    required bool isViewing,
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
  }) {
    return SizedBox(
      width: 150, // Fixed width for compact fields
      child: isViewing
          ? _displayField(label, value)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label(label),
                _filledField(
                  controller!,
                  readOnly: readOnly,
                  onTap: onTap,
                  keyboardType: keyboardType,
                  onChanged: onChanged,
                ),
                const SizedBox(height: 14),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final bool isViewing = widget.isViewing; // Get the isViewing state

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
                    const Spacer(),
                    if (isViewing)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFF2E7D32)),
                        onPressed: () {
                          // Navigate to edit mode
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditPantryItem(item: widget.item, isViewing: false),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              Text(
                isViewing ? 'Pantry Item Details' : 'Edit Pantry Item',
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
                  onTap: isViewing ? null : _pickImage, // Disable tap if viewing
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!) as ImageProvider
                        : (widget.item.imageUrl != null && widget.item.imageUrl!.isNotEmpty
                            ? NetworkImage(widget.item.imageUrl!)
                            : null),
                    child: _imageFile == null && (widget.item.imageUrl == null || widget.item.imageUrl!.isEmpty)
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

              // Item Name
              _sectionTitle('Item Details'),
              const SizedBox(height: 12),
              isViewing
                  ? _displayField('Item Name', _nameCtrl.text)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Item Name'),
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
                              _quantityUnitCtrl.text = selection.netWeight ?? ''; // Assuming netWeight is quantityUnit
                              if (selection.category != null) {
                                _selectedCategory = selection.category;
                              } else {
                                // If product from autocomplete doesn't have a category, try to suggest one
                                _selectedCategory = _suggestCategoryFromName(selection.productName);
                              }

                              // Attempt to set expiration date based on category default
                              _updateExpirationDateFromCategory();
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),

              // Quantity, Net Weight, Expiration Date, Date of Purchase in a more compact layout
              Wrap(
                spacing: 12.0, // Horizontal space between chips
                runSpacing: 12.0, // Vertical space between lines of chips
                children: [
                  _compactInfoField(
                    label: 'Quantity',
                    value: _qtyCtrl.text,
                    isViewing: isViewing,
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                  ),
                  _compactInfoField(
                    label: 'Net Weight',
                    value: _quantityUnitCtrl.text,
                    isViewing: isViewing,
                    controller: _quantityUnitCtrl,
                  ),
                  _compactInfoField(
                    label: 'Expiration Date',
                    value: _expCtrl.text,
                    isViewing: isViewing,
                    controller: _expCtrl,
                    readOnly: true,
                    onTap: isViewing
                        ? null
                        : () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                _expCtrl.text = DateFormat('MMMM d, yyyy').format(pickedDate);
                                // No shelf life calculator in edit, so no need to clear
                              });
                            }
                          },
                  ),
                  _compactInfoField(
                    label: 'Date of Purchase',
                    value: _dopCtrl.text,
                    isViewing: isViewing,
                    controller: _dopCtrl,
                    readOnly: true,
                    onTap: isViewing
                        ? null
                        : () async {
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
                ],
              ),
              const SizedBox(height: 14),

              // Barcode and Brand in a row
              Wrap(
                spacing: 12.0,
                runSpacing: 12.0,
                children: [
                  _compactInfoField(
                    label: 'Barcode',
                    value: _barcodeCtrl.text,
                    isViewing: isViewing,
                    controller: _barcodeCtrl,
                  ),
                  _compactInfoField(
                    label: 'Brand',
                    value: _brandCtrl.text,
                    isViewing: isViewing,
                    controller: _brandCtrl,
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Item Category
              _sectionTitle('Item Category'),
              const SizedBox(height: 12),
              isViewing
                  ? _displayField('Category', _selectedCategory ?? 'N/A')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _greenDropdown(readOnly: isViewing),
                        const SizedBox(height: 14),
                      ],
                    ),

              // Notes
              _sectionTitle('Notes'),
              const SizedBox(height: 12),
              isViewing
                  ? _displayField('Notes', _notesCtrl.text)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Notes (Optional)'),
                        _filledField(_notesCtrl, maxLines: 5, readOnly: isViewing),
                        const SizedBox(height: 22),
                      ],
                    ),

              // Storage Location Section
              if (isViewing) _storageLocationSection(),

              // Tips Section
              if (isViewing) _tipsSection(),

              // Action buttons
              if (!isViewing)
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
