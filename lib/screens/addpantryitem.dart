import 'dart:io';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shelf_control/models/pantry_item_model.dart';
import 'package:shelf_control/models/product_model.dart';
// For navigation back to dashboard

class AddPantryItem extends StatefulWidget {
  final Function(PantryItemModel) onAddItem;
  final VoidCallback onBack;
  final String householdId;
  final bool isGuest;

  const AddPantryItem({
    super.key,
    required this.onAddItem,
    required this.onBack,
    required this.householdId,
    this.isGuest = false,
  });

  @override
  State<AddPantryItem> createState() => _AddPantryItemState();
}

class _AddPantryItemState extends State<AddPantryItem> {
  // --- UI Colors from Design ---
  final Color headerGreen = const Color(0xFF2E7D32);
  final Color softCream = const Color(0xFFFAF8ED);
  final Color inputFillColor = const Color(0xFFFDFDFC);
  final Color inputBorderColor = const Color(0xFFB8B8B8);
  final Color labelTextColor = const Color(0xFF666666);
  final Color inputTextColor = const Color(0xFF222222);
  final Color errorColor = const Color.fromARGB(255, 253, 52, 38);

  // Controllers for all fields
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _netWeightCtrl;
  late TextEditingController _expCtrl;
  late TextEditingController _dopCtrl; // Date of Production controller
  late TextEditingController _notesCtrl;
  late TextEditingController _quantityCtrl;
  int _quantity = 1;

  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _notesFocusNode = FocusNode();
  final FocusNode _priceFocusNode = FocusNode();

  // Image picker state
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;

  String? _selectedCategory;
  final List<String> _categories = <String>[
    'Beverages', 'Canned Goods', 'Condiments', 'Dairy', 'Dry Goods', 'Snacks', 'Frozen', 'Produce', 'Other',
  ];

  String _selectedUnit = 'lbs';
  final List<String> _units = ['lbs', 'kg', 'g', 'L', 'mL'];

  bool _isNameInvalid = false;
  bool _isCategoryInvalid = false;
  bool _isExpDateInvalid = false;
  bool _isPriceInvalid = false;
  String? _netWeightErrorText;

  // For optional shelf life calculator
  DateTime? _selectedExpDate; // To store the actual expiration date
  DateTime? _selectedDopDate; // To store the actual date of production
  bool _showShelfLifeCalculator = false;
  late TextEditingController _shelfLifeValueCtrl;
  String? _selectedShelfLifeUnit;
  final List<String> _shelfLifeUnits = ['Days', 'Weeks', 'Months', 'Years'];
  Timer? _debounce; // For autocomplete debouncing

  // Define default shelf lives for categories in days based on research
  final Map<String, int> _categoryShelfLives = {
    'Beverages': 270, // 9 months (general, UHT milk/juice longer, fresh juice shorter)
    'Canned Goods': 730, // 2 years
    'Condiments': 365, // 12 months (unopened)
    'Dairy': 14, // 2 weeks (for refrigerated items like milk, yogurt)
    'Dry Goods': 547, // 18 months (rice, pasta, flour)
    'Snacks': 180, // 6 months
    'Frozen': 365, // 1 year
    'Produce': 7, // 1 week
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
    },
    'Dry Goods': {
      'rice': 730, // 2 years
      'pasta': 730, // 2 years
      'flour': 180, // 6 months
      'cereal': 180, // 6 months
      'oil': 365, // 1 year
      'beans': 730, // 2 years (dried)
      'sugar': 1825, // 5 years
    },
    'Snacks': {
      'chips': 90, // 3 months
      'crackers': 180, // 6 months
      'cookies': 180, // 6 months
      'chocolates': 270, // 9 months
      'biscuits': 180, // 6 months
      'packed fudge bars': 180, // 6 months
      'mamon': 7, // 1 week
      'donut': 3, // 3 days
      'pandesal': 7, // 1 week
      'ensaymada': 7, // 1 week
    }
  };

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _priceCtrl = TextEditingController(text: '0.00');
    _netWeightCtrl = TextEditingController();
    _expCtrl = TextEditingController();
    _dopCtrl = TextEditingController(text: DateFormat('MMMM d, yyyy').format(DateTime.now()));
    _notesCtrl = TextEditingController();
    _quantityCtrl = TextEditingController(text: _quantity.toString());
    _shelfLifeValueCtrl = TextEditingController();
    _selectedShelfLifeUnit = 'Days';
    _selectedDopDate = DateTime.now();

    _nameCtrl.addListener(() {
      if (_isNameInvalid && _nameCtrl.text.isNotEmpty) {
        setState(() => _isNameInvalid = false);
      } else {
        setState(() {});
      }
      if (_nameCtrl.text.isNotEmpty) {
        setState(() {
          _selectedCategory = _suggestCategoryFromName(_nameCtrl.text);
          _updateExpirationDateFromCategory();
        });
      }
    });

    _expCtrl.addListener(() {
      if (_isExpDateInvalid && _expCtrl.text.isNotEmpty) {
        setState(() => _isExpDateInvalid = false);
      }
    });

    _priceCtrl.addListener(() {
      final price = double.tryParse(_priceCtrl.text) ?? 0.0;
      if (_isPriceInvalid && price > 0.0) {
        setState(() => _isPriceInvalid = false);
      } else {
        setState(() {});
      }
    });

    _netWeightCtrl.addListener(() {
      if (_netWeightErrorText != null) {
        setState(() {
          _netWeightErrorText = null;
        });
      }
    });

    _notesFocusNode.addListener(_onNotesFocusChange);
    _priceFocusNode.addListener(_formatPrice);
  }

  @override
  void dispose() {
    _notesFocusNode.removeListener(_onNotesFocusChange);
    _notesFocusNode.dispose();
    _priceFocusNode.removeListener(_formatPrice);
    _priceFocusNode.dispose();
    _nameFocusNode.dispose();
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _netWeightCtrl.dispose();
    _expCtrl.dispose();
    _dopCtrl.dispose();
    _notesCtrl.dispose();
    _quantityCtrl.dispose();
    _shelfLifeValueCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  String? _suggestCategoryFromName(String itemName) {
    itemName = itemName.toLowerCase();

    final Map<String, List<String>> categoryKeywords = {
      'Dairy': ['milk', 'yogurt', 'cheese', 'butter', 'margarine', 'spread', 'cream', 'eggs', 'evaporada', 'condensada'],
      'Beverages': ['coffee', 'tea', 'juice', 'soda', 'water', 'chocolate drink', 'malt', 'drink', 'softdrink', 'powdered drink'],
      'Canned Goods': ['canned', 'beans', 'soup', 'tuna', 'sardines', 'corned beef', 'meat loaf', 'luncheon meat', 'fruit cocktail'],
      'Dry Goods': ['rice', 'pasta', 'flour', 'cereal', 'grains', 'seeds', 'oil', 'legumes', 'beans', 'soup mix', 'broth', 'noodles', 'sago', 'oats', 'oatmeal', 'sugar'],
      'Snacks': [
        'chips', 'crackers', 'cookies', 'nuts', 'candies', 'chocolates', 'biscuits', 'dips', 'wafer', 'bar', 'pastillas', 'polvoron',
        'bread', 'cake', 'pastries', 'baking needs', 'buns', 'muffin', 'donut', 'pandesal', 'ensaymada', 'packed fudge bars', 'mamon'
      ],
      'Condiments': ['vinegar', 'soy sauce', 'ketchup', 'mustard', 'dressing', 'sauce', 'spices', 'powder', 'salt', 'bbq', 'seasoning', 'garlic bits', 'bagoong', 'chili', 'patis', 'fish sauce'],
      'Frozen': ['ice cream', 'frozen', 'meat', 'fish', 'vegetables', 'fries', 'nuggets'],
      'Produce': ['fruit', 'vegetable', 'apple', 'banana', 'orange', 'potato', 'onion', 'garlic', 'tomato', 'lettuce'],
      'Other': [],
    };

    for (final categoryEntry in categoryKeywords.entries) {
      final category = categoryEntry.key;
      final keywords = categoryEntry.value;
      for (final keyword in keywords) {
        if (itemName.contains(keyword)) {
          return category;
        }
      }
    }
    return 'Other';
  }

  void _calculateExpirationDate({bool forceUpdate = false}) {
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
    if ((_expCtrl.text.isEmpty || forceUpdate) && _selectedCategory != null && _selectedDopDate != null) {
      int? shelfLife = _categoryShelfLives[_selectedCategory];
      String itemName = _nameCtrl.text.toLowerCase();

      if (_subcategoryShelfLives.containsKey(_selectedCategory)) {
        final subcategoryMap = _subcategoryShelfLives[_selectedCategory]!;
        for (final subcategoryEntry in subcategoryMap.entries) {
          final subcategoryKeyword = subcategoryEntry.key;
          final subcategorySpecificShelfLife = subcategoryEntry.value;
          if (itemName.contains(subcategoryKeyword)) {
            shelfLife = subcategorySpecificShelfLife;
            break;
          }
        }
      }

      if (shelfLife != null) {
        final int actualShelfLife = shelfLife;
        setState(() {
          _selectedExpDate = _selectedDopDate!.add(Duration(days: actualShelfLife));
          _expCtrl.text = DateFormat('MMMM d, yyyy').format(_selectedExpDate!);
        });
      }
    }
  }

  bool _isFormDirty() {
    return _nameCtrl.text.isNotEmpty ||
        _priceCtrl.text != '0.00' ||
        _netWeightCtrl.text.isNotEmpty ||
        _expCtrl.text.isNotEmpty ||
        _notesCtrl.text.isNotEmpty ||
        _quantity != 1 ||
        _selectedCategory != null ||
        _selectedImage != null ||
        _shelfLifeValueCtrl.text.isNotEmpty;
  }

  Future<Iterable<Product>> _searchProducts(String query) async {
    final String searchQuery = query.trim();
    if (searchQuery.isEmpty) return const Iterable<Product>.empty();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('local_products_ph')
          .where('productName', isGreaterThanOrEqualTo: searchQuery)
          .where('productName', isLessThan: '$searchQuery\uf8ff')
          .limit(5)
          .get();

      return snapshot.docs.map((doc) => Product.fromFirestore(doc));
    } catch (e) {
      debugPrint("Error fetching product suggestions: $e");
      return const Iterable<Product>.empty();
    }
  }

  void _parseNetWeight(String netWeight) {
    if (netWeight.isEmpty) return;
    final RegExp regex = RegExp(r'(\d+\.?\d*)\s*([a-zA-Z]+)');
    final Match? match = regex.firstMatch(netWeight);

    if (match != null) {
      final String? value = match.group(1);
      final String? unit = match.group(2)?.toLowerCase();
      if (value != null) _netWeightCtrl.text = value;
      if (unit != null) {
        String normalizedUnit = unit;
        if (unit == 'ml') {
          normalizedUnit = 'mL';
        } else if (unit == 'l') normalizedUnit = 'L';
        else if (unit == 'g') normalizedUnit = 'g';
        else if (unit == 'kg') normalizedUnit = 'kg';
        else if (unit == 'lbs') normalizedUnit = 'lbs';
        if (_units.contains(normalizedUnit)) _selectedUnit = normalizedUnit;
      }
    } else {
      _netWeightCtrl.text = netWeight;
    }
  }

  void _onNotesFocusChange() {
    if (_notesFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 300), () {
        Scrollable.ensureVisible(_notesFocusNode.context!,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            alignment: 0.05);
      });
    }
  }

  void _formatPrice() {
    if (!_priceFocusNode.hasFocus) {
      final String currentText = _priceCtrl.text;
      final double? value = double.tryParse(currentText);
      _priceCtrl.text = value != null ? value.toStringAsFixed(2) : '0.00';
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
          source: source, maxWidth: 800, maxHeight: 800, imageQuality: 85);
      if (image != null) setState(() => _selectedImage = File(image.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.green),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  }),
              ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.blue),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  }),
              if (_selectedImage != null)
                ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Remove Image'),
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() => _selectedImage = null);
                    }),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _uploadImageToFirebase() async {
    if (_selectedImage == null) return null;
    setState(() => _isUploadingImage = true);
    try {
      final String fileName = 'pantry_items/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = FirebaseStorage.instance.ref().child(fileName);
      final TaskSnapshot snapshot = await ref.putFile(_selectedImage!);
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      setState(() => _isUploadingImage = false);
      return downloadUrl;
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (!mounted) return null;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      return null;
    }
  }

  Future<void> _addItem() async {
    final price = double.tryParse(_priceCtrl.text) ?? 0.0;
    setState(() {
      _isNameInvalid = _nameCtrl.text.isEmpty;
      _isCategoryInvalid = _selectedCategory == null;
      _isExpDateInvalid = _expCtrl.text.isEmpty;
      _isPriceInvalid = price <= 0.0;
    });

    if (_isNameInvalid || _isCategoryInvalid || _isExpDateInvalid || _isPriceInvalid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please fill all required fields marked in red.')));
      return;
    }

    String? imageUrl = await _uploadImageToFirebase();
    if (imageUrl == null && _selectedImage != null) return;

    final newItem = PantryItemModel(
      id: '',
      householdId: widget.householdId,
      name: _nameCtrl.text,
      category: _selectedCategory!,
      price: price,
      imageUrl: imageUrl,
      qty: _quantity,
      expirationDate: DateFormat('MMMM d, yyyy').parse(_expCtrl.text),
      manufacturedDate: _selectedDopDate,
      netWeight: _netWeightCtrl.text.trim().isEmpty
          ? null
          : '${_netWeightCtrl.text.trim()} $_selectedUnit',
      notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
    );

    widget.onAddItem(newItem);
    if (mounted) _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, color: headerGreen, size: 60),
              const SizedBox(height: 16),
              Text('Success!', style: TextStyle(
                  color: headerGreen, fontSize: 24, fontWeight: FontWeight.w800, fontFamily: 'Inter')),
              const SizedBox(height: 8),
              Text('Pantry item added!', style: TextStyle(
                  color: inputTextColor, fontSize: 16, fontFamily: 'Inter'), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                      backgroundColor: headerGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    widget.onBack();
                  },
                  child: const Text('Continue', style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Inter')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCancelConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 60),
              const SizedBox(height: 16),
              Text('Cancel Registration', style: TextStyle(
                  color: inputTextColor, fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Inter')),
              const SizedBox(height: 8),
              Text('Are you sure you want to cancel? The details will not be saved.',
                  style: TextStyle(color: labelTextColor, fontSize: 16, fontFamily: 'Inter'), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                          backgroundColor: const Color(0xFF9E9E9E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('No', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                          backgroundColor: headerGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        widget.onBack();
                      },
                      child: const Text('Yes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  double? _convertNetWeight(double value, String from, String to) {
    if (from == to) return value;
    const weightUnits = ['g', 'kg', 'lbs'];
    const volumeUnits = ['mL', 'L'];
    if (!(weightUnits.contains(from) && weightUnits.contains(to)) &&
        !(volumeUnits.contains(from) && volumeUnits.contains(to))) {
      return null;
    }
    const gPerKg = 1000.0;
    const gPerLbs = 453.592;
    const mlPerL = 1000.0;
    double valueInBaseUnit;
    switch (from) {
      case 'kg': valueInBaseUnit = value * gPerKg; break;
      case 'lbs': valueInBaseUnit = value * gPerLbs; break;
      case 'L': valueInBaseUnit = value * mlPerL; break;
      default: valueInBaseUnit = value; break;
    }
    switch (to) {
      case 'kg': return valueInBaseUnit / gPerKg;
      case 'lbs': return valueInBaseUnit / gPerLbs;
      case 'L': return valueInBaseUnit / mlPerL;
      default: return valueInBaseUnit;
    }
  }

  void _formatNetWeight() {
    final currentValue = _netWeightCtrl.text.trim();
    if (currentValue.isNotEmpty) {
      final numValue = double.tryParse(currentValue);
      if (numValue != null) {
        if (_selectedUnit == 'lbs' || _selectedUnit == 'kg') {
          if (!currentValue.contains('.')) _netWeightCtrl.text = '$currentValue.0';
        } else {
          if (currentValue.endsWith('.0')) _netWeightCtrl.text = currentValue.replaceAll('.0', '');
        }
      }
    }
  }

  // --- UI WIDGET BUILDERS ---

  Widget textField(TextEditingController ctrl,
      {required String labelText, String? prefixText, String hintText = '',
      bool readOnly = false, int maxLines = 1, FocusNode? focusNode,
      VoidCallback? onTap, void Function(String)? onSubmitted, void Function(String)? onChanged, TextInputType keyboardType = TextInputType.text,
      List<TextInputFormatter>? inputFormatters, Widget? suffixIcon,
      String? errorText, BorderSide? borderSide}) {
    final currentBorderSide = borderSide ?? BorderSide(color: inputBorderColor);
    return TextField(
      controller: ctrl, readOnly: readOnly, maxLines: maxLines, focusNode: focusNode,
      onTap: onTap, onSubmitted: onSubmitted, onChanged: onChanged,
      style: TextStyle(fontFamily: 'Roboto', fontSize: 16, color: inputTextColor),
      decoration: InputDecoration(
        labelText: labelText, prefixText: prefixText, hintText: hintText,
        labelStyle: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 14, color: labelTextColor),
        filled: true, fillColor: inputFillColor, suffixIcon: suffixIcon, errorText: errorText,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: currentBorderSide),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: currentBorderSide),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: currentBorderSide.copyWith(width: 2.0)),
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
    );
  }

  Widget _quantityField() {
    final borderSide = BorderSide(color: headerGreen, width: 1.5);
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Quantity',
        labelStyle: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 14, color: labelTextColor),
        filled: true, fillColor: inputFillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: borderSide),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: borderSide),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: borderSide.copyWith(width: 2.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.remove, color: headerGreen),
            onPressed: () {
              if (_quantity > 1) {
                setState(() {
                _quantity--;
                _quantityCtrl.text = _quantity.toString();
              });
              }
            },
          ),
          SizedBox(
            width: 40,
            child: TextField(
              controller: _quantityCtrl, textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: inputTextColor),
              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
              onChanged: (value) {
                final newQuantity = int.tryParse(value);
                if (newQuantity != null && newQuantity > 0) _quantity = newQuantity;
              },
              onTapOutside: (_) {
                if (_quantityCtrl.text.isEmpty || _quantity == 0) {
                  setState(() {
                  _quantity = 1;
                  _quantityCtrl.text = '1';
                });
                }
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.add, color: headerGreen),
            onPressed: () => setState(() {
              _quantity++;
              _quantityCtrl.text = _quantity.toString();
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nameBorderSide = _isNameInvalid ? BorderSide(color: errorColor, width: 1.5)
        : _nameCtrl.text.isNotEmpty ? BorderSide(color: headerGreen, width: 1.5)
        : BorderSide(color: inputBorderColor);
    final categoryBorderSide = _isCategoryInvalid ? BorderSide(color: errorColor, width: 1.5)
        : _selectedCategory != null ? BorderSide(color: headerGreen, width: 1.5)
        : BorderSide(color: inputBorderColor);
    final expDateBorderSide = _isExpDateInvalid ? BorderSide(color: errorColor, width: 1.5)
        : _expCtrl.text.isNotEmpty ? BorderSide(color: headerGreen, width: 1.5)
        : BorderSide(color: inputBorderColor);
    final priceValue = double.tryParse(_priceCtrl.text) ?? 0.0;
    final priceBorderSide = _isPriceInvalid ? BorderSide(color: errorColor, width: 1.5)
        : priceValue > 0.0 ? BorderSide(color: headerGreen, width: 1.5)
        : BorderSide(color: inputBorderColor);

    return Scaffold(
      backgroundColor: softCream,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: headerGreen, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            if (_isFormDirty()) {
              _showCancelConfirmationDialog();
            } else {
              widget.onBack();
            }
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IconButton(
              icon: _isUploadingImage
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save, color: Colors.white, size: 28),
              onPressed: _isUploadingImage ? null : _addItem,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, 180 + MediaQuery.of(context).padding.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Pantry Item', style: TextStyle(
                color: headerGreen, fontWeight: FontWeight.w800, fontSize: 28)),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _showImagePickerOptions,
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _selectedImage != null ? headerGreen : Colors.grey,
                          width: 2),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(_selectedImage!, fit: BoxFit.cover))
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, color: Colors.grey, size: 30),
                                SizedBox(height: 4),
                                Text('Add Photo', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RawAutocomplete<Product>(
                        textEditingController: _nameCtrl,
                        focusNode: _nameFocusNode,
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (_debounce?.isActive ?? false) _debounce!.cancel();
                          _debounce = Timer(const Duration(milliseconds: 300), () {
                            setState(() {});
                          });
                          return _searchProducts(textEditingValue.text);
                        },
                        onSelected: (Product selection) {
                          setState(() {
                            _nameCtrl.text = selection.productName;
                            if (selection.category != null && _categories.contains(selection.category)) {
                              _selectedCategory = selection.category;
                            } else {
                              _selectedCategory = _suggestCategoryFromName(selection.productName);
                            }
                            _priceCtrl.text = selection.price?.toStringAsFixed(2) ?? '0.00';
                            if (selection.netWeight != null) _parseNetWeight(selection.netWeight!);

                            if (selection.manufacturedDate != null) {
                              _selectedDopDate = selection.manufacturedDate;
                              _dopCtrl.text = DateFormat('MMMM d, yyyy').format(_selectedDopDate!);
                            } else {
                              _selectedDopDate = DateTime.now();
                              _dopCtrl.text = DateFormat('MMMM d, yyyy').format(_selectedDopDate!);
                            }
                            _updateExpirationDateFromCategory(forceUpdate: true);

                            if (_nameCtrl.text.isNotEmpty) _isNameInvalid = false;
                            if (_selectedCategory != null) _isCategoryInvalid = false;
                            final price = double.tryParse(_priceCtrl.text) ?? 0.0;
                            if (price > 0.0) _isPriceInvalid = false;
                          });
                        },
                        fieldViewBuilder: (context, fieldTextEditingController, fieldFocusNode, onFieldSubmitted) {
                          return textField(
                            fieldTextEditingController, labelText: 'Item Name',
                            focusNode: fieldFocusNode, borderSide: nameBorderSide,
                          );
                        },
                        optionsViewBuilder: (context, onSelected, options) {
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4.0, color: inputFillColor,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: inputBorderColor)),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 250),
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(4.0), shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final Product option = options.elementAt(index);
                                    return InkWell(
                                      onTap: () => onSelected(option),
                                      child: ListTile(
                                        title: Text(option.productName, style: TextStyle(color: inputTextColor)),
                                        subtitle: option.brand != null && option.brand!.isNotEmpty
                                            ? Text(option.brand!, style: TextStyle(color: labelTextColor))
                                            : null,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField2<String>(
              value: _selectedCategory, isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Category',
                labelStyle: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 14, color: labelTextColor),
                filled: true, fillColor: inputFillColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: categoryBorderSide),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: categoryBorderSide),
              ),
              items: _categories.map((c) => DropdownMenuItem<String>(
                        value: c, child: Text(c, style: TextStyle(fontFamily: 'Roboto', fontSize: 16, color: inputTextColor))))
                  .toList(),
              onChanged: (val) => setState(() {
                _selectedCategory = val;
                if (val != null) _isCategoryInvalid = false;
                _updateExpirationDateFromCategory();
              }),
              dropdownStyleData: DropdownStyleData(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 24),
            textField(
              _expCtrl, labelText: 'Date of Expiration', hintText: 'October 9, 2025',
              readOnly: true, borderSide: expDateBorderSide,
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context, initialDate: _selectedExpDate ?? DateTime.now(),
                  firstDate: DateTime(2000), lastDate: DateTime(2100),
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(primary: headerGreen, onPrimary: Colors.white, onSurface: inputTextColor),
                      textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: headerGreen)),
                    ),
                    child: child!,
                  ),
                );
                if (pickedDate != null) {
                  setState(() {
                    _selectedExpDate = pickedDate;
                    _expCtrl.text = DateFormat('MMMM d, yyyy').format(pickedDate);
                    _shelfLifeValueCtrl.clear();
                    _selectedShelfLifeUnit = 'Days';
                  });
                }
              },
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () {
                setState(() {
                  _showShelfLifeCalculator = !_showShelfLifeCalculator;
                  if (_showShelfLifeCalculator) {
                    _calculateExpirationDate(forceUpdate: true);
                  } else {
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
              textField(
                _dopCtrl, labelText: 'Production Date',
                readOnly: true,
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDopDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(primary: headerGreen, onPrimary: Colors.white, onSurface: inputTextColor),
                        textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: headerGreen)),
                      ),
                      child: child!,
                    ),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _selectedDopDate = pickedDate;
                      _dopCtrl.text = DateFormat('MMMM d, yyyy').format(pickedDate);
                      _calculateExpirationDate(forceUpdate: true);
                    });
                  }
                },
              ),
              const SizedBox(height: 14),
              textField(
                _shelfLifeValueCtrl, labelText: 'Shelf Life Duration',
                keyboardType: TextInputType.number,
                onTap: () {
                  setState(() {
                    _expCtrl.text = '';
                    _selectedExpDate = null;
                  });
                },
                onChanged: (value) {
                  _calculateExpirationDate(forceUpdate: true);
                },
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton2<String>(
                      value: _selectedShelfLifeUnit,
                      items: _shelfLifeUnits.map((String value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(value, style: TextStyle(color: inputTextColor, fontSize: 16))))
                          .toList(),
                      onChanged: (String? newValue) {
                        if (newValue == null || newValue == _selectedShelfLifeUnit) return;
                        setState(() {
                          _selectedShelfLifeUnit = newValue;
                          _calculateExpirationDate(forceUpdate: true);
                        });
                      },
                      iconStyleData: IconStyleData(icon: Icon(Icons.unfold_more, color: Colors.grey[600], size: 20)),
                      buttonStyleData: const ButtonStyleData(padding: EdgeInsets.zero, height: 40),
                      dropdownStyleData: DropdownStyleData(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: textField(_priceCtrl, labelText: 'Item Price', prefixText: '₱ ',
                      focusNode: _priceFocusNode,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      borderSide: priceBorderSide)),
                const SizedBox(width: 12),
                Expanded(child: _quantityField()),
              ],
            ),
            const SizedBox(height: 24),
            textField(
              _netWeightCtrl, labelText: 'Net Weight', onSubmitted: (_) => _formatNetWeight(),
              errorText: _netWeightErrorText,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton2<String>(
                    value: _selectedUnit,
                    items: _units.map((String value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, style: TextStyle(color: inputTextColor, fontSize: 16))))
                        .toList(),
                    onChanged: (String? newValue) {
                      if (newValue == null || newValue == _selectedUnit) return;
                      setState(() => _netWeightErrorText = null);
                      final fromUnit = _selectedUnit;
                      final toUnit = newValue;
                      final numValue = double.tryParse(_netWeightCtrl.text.trim());
                      setState(() => _selectedUnit = toUnit);
                      if (numValue == null) return;
                      final convertedValue = _convertNetWeight(numValue.toDouble(), fromUnit, toUnit);
                      if (convertedValue != null) {
                        _netWeightCtrl.text = NumberFormat("0.###").format(convertedValue);
                      } else {
                        setState(() => _netWeightErrorText = "Cannot convert from $fromUnit to $toUnit.");
                      }
                    },
                    iconStyleData: IconStyleData(icon: Icon(Icons.unfold_more, color: Colors.grey[600], size: 20)),
                    buttonStyleData: const ButtonStyleData(padding: EdgeInsets.zero, height: 40),
                    dropdownStyleData: DropdownStyleData(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            textField(_notesCtrl, labelText: 'Notes', hintText: 'No notes for this item.',
                maxLines: 3, focusNode: _notesFocusNode),
          ],
        ),
      ),
      bottomNavigationBar: IgnorePointer(
        child: SizedBox(
          height: 180 + MediaQuery.of(context).padding.bottom,
          child: Image.asset(
            'assets/footer1e27d32-trans.png',
            width: double.infinity, fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
