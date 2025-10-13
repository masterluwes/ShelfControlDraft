import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shelf_control/models/pantry_item_model.dart';
import 'package:shelf_control/models/product_model.dart'; 
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:async';
import 'package:shelf_control/services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:shelf_control/screens/recipe_suggestions_page.dart';

class EditPantryItem extends StatefulWidget {
  final PantryItemModel item;

  const EditPantryItem({super.key, required this.item});

  @override
  State<EditPantryItem> createState() => _EditPantryItemState();
}

class _EditPantryItemState extends State<EditPantryItem> {
  // --- UI Colors ---
  final Color headerGreen = const Color(0xFF2E7D32);
  final Color softCream = const Color(0xFFFAF8ED);
  final Color inputFillColor = const Color(0xFFFDFDFC);
  final Color inputBorderColor = const Color(0xFFB8B8B8);
  final Color labelTextColor = const Color(0xFF666666);
  final Color inputTextColor = const Color(0xFF222222);
  final Color errorColor = const Color.fromARGB(255, 253, 52, 38);
  final Color deleteButtonRed = const Color(0xFFF44336);

  // --- State ---
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _netWeightCtrl;
  late TextEditingController _expCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _quantityCtrl;
  late int _quantity;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;
  String? _imageUrlFromItem;
  String? _selectedCategory;

  // --- Net Weight State ---
  String _selectedUnit = 'g'; // Default unit
  final List<String> _units = ['lbs', 'kg', 'g', 'L', 'mL'];
  String? _netWeightErrorText;

  bool _isNameInvalid = false;
  bool _isCategoryInvalid = false;
  bool _isExpDateInvalid = false;

  Timer? _debounce; // For autocomplete debouncing

  final List<String> _categories = <String>[
    'Bakery', 'Beverages', 'Canned Goods', 'Condiments', 'Dairy', 'Dry Goods', 'Snacks', 'Other',
  ];

  // Define default shelf lives for categories in days based on research
  final Map<String, int> _categoryShelfLives = {
    'Bakery': 7, // 1 week
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
    'Bakery': {
      'bread': 7,
      'cake': 7,
      'pastries': 7,
      'buns': 7,
      'muffin': 7,
      'donut': 3,
      'pandesal': 7,
      'ensaymada': 7,
      'mamon': 7,
    },
    'Dairy': {
      'fresh milk': 7, 'powdered milk': 270, 'cheese': 60, 'yogurt': 21, 'butter': 90, 'eggs': 30,
    },
    'Beverages': {
      'fresh juice': 7, 'uht milk': 270, 'coffee': 365, 'tea': 730, 'soda': 180, 'water': 730,
    },
    'Condiments': {
      'vinegar': 730, 'soy sauce': 365, 'ketchup': 365, 'mustard': 365, 'dressing': 180, 'spices': 730, 'powder': 730, 'salt': 1825,
    },
    'Dry Goods': {
      'rice': 730, 'pasta': 730, 'flour': 180, 'cereal': 180, 'oil': 365, 'beans': 730, 'sugar': 1825,
    },
    'Snacks': {
      'chips': 90, 'crackers': 180, 'cookies': 180, 'chocolates': 270, 'biscuits': 180, 'packed fudge bars': 180,
    }
  };

  @override
  void initState() {
    super.initState();
    _initializeStateFromItem();
  }

  void _initializeStateFromItem() {
    _nameCtrl = TextEditingController(text: widget.item.name);
    _priceCtrl = TextEditingController(text: widget.item.price?.toStringAsFixed(2) ?? '0.00');
    _netWeightCtrl = TextEditingController();
    _parseNetWeight(widget.item.netWeight ?? '');
    _expCtrl = TextEditingController(
        text: widget.item.expirationDate != null
            ? DateFormat('MMMM d, yyyy').format(widget.item.expirationDate!)
            : '');
    _notesCtrl = TextEditingController(text: widget.item.notes ?? '');
    _quantity = widget.item.qty;
    _quantityCtrl = TextEditingController(text: _quantity.toString());
    _selectedCategory = widget.item.category;
    _imageUrlFromItem = widget.item.imageUrl;

    _nameCtrl.addListener(() { if (_isNameInvalid && _nameCtrl.text.isNotEmpty) setState(() => _isNameInvalid = false); });
    _expCtrl.addListener(() { if (_isExpDateInvalid && _expCtrl.text.isNotEmpty) setState(() => _isExpDateInvalid = false); });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _netWeightCtrl.dispose();
    _expCtrl.dispose();
    _notesCtrl.dispose();
    _quantityCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
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
        if (_units.contains(normalizedUnit)) {
          setState(() => _selectedUnit = normalizedUnit);
        }
      }
    } else {
      _netWeightCtrl.text = netWeight;
    }
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

  String? _suggestCategoryFromName(String itemName) {
    itemName = itemName.toLowerCase();
    final Map<String, List<String>> categoryKeywords = {
      'Bakery': ['bread', 'cake', 'pastries', 'baking needs', 'buns', 'muffin', 'donut', 'pandesal', 'ensaymada', 'mamon'],
      'Dairy': ['milk', 'yogurt', 'cheese', 'butter', 'margarine', 'spread', 'cream', 'eggs', 'evaporada', 'condensada'],
      'Beverages': ['coffee', 'tea', 'juice', 'soda', 'water', 'chocolate drink', 'malt', 'drink', 'softdrink', 'powdered drink'],
      'Canned Goods': ['canned', 'beans', 'soup', 'tuna', 'sardines', 'corned beef', 'meat loaf', 'luncheon meat', 'fruit cocktail'],
      'Dry Goods': ['rice', 'pasta', 'flour', 'cereal', 'grains', 'seeds', 'oil', 'legumes', 'beans', 'soup mix', 'broth', 'noodles', 'sago', 'oats', 'oatmeal', 'sugar'],
      'Snacks': ['chips', 'crackers', 'cookies', 'nuts', 'candies', 'chocolates', 'biscuits', 'dips', 'wafer', 'bar', 'pastillas', 'polvoron', 'packed fudge bars'],
      'Condiments': ['vinegar', 'soy sauce', 'ketchup', 'mustard', 'dressing', 'sauce', 'spices', 'powder', 'salt', 'bbq', 'seasoning', 'garlic bits', 'bagoong', 'chili', 'patis', 'fish sauce'],
      'Other': [],
    };

    for (final categoryEntry in categoryKeywords.entries) {
      final category = categoryEntry.key;
      final keywords = categoryEntry.value;
      for (final keyword in keywords) {
        if (itemName.contains(keyword)) return category;
      }
    }
    return 'Other';
  }

  void _updateExpirationDateFromCategory({bool forceUpdate = false}) {
    if ((_expCtrl.text.isEmpty || forceUpdate) && _selectedCategory != null && widget.item.manufacturedDate != null) {
      int? shelfLife = _categoryShelfLives[_selectedCategory];
      String itemName = _nameCtrl.text.toLowerCase();

      if (_subcategoryShelfLives.containsKey(_selectedCategory)) {
        final subcategoryMap = _subcategoryShelfLives[_selectedCategory]!;
        for (final subcategoryEntry in subcategoryMap.entries) {
          if (itemName.contains(subcategoryEntry.key)) {
            shelfLife = subcategoryEntry.value;
            break;
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

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 85);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _imageUrlFromItem = null;
      });
    }
  }

  Future<String?> _uploadImageToFirebase() async {
    if (_selectedImage == null) return _imageUrlFromItem;
    setState(() => _isUploadingImage = true);

    try {
      final String fileName = 'pantry_items/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = FirebaseStorage.instance.ref().child(fileName);
      await ref.putFile(_selectedImage!);
      final String downloadUrl = await ref.getDownloadURL();
      setState(() => _isUploadingImage = false);
      return downloadUrl;
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      return null;
    }
  }

  Future<void> _saveItem() async {
    setState(() {
      _isNameInvalid = _nameCtrl.text.isEmpty;
      _isCategoryInvalid = _selectedCategory == null;
      _isExpDateInvalid = _expCtrl.text.isEmpty;
    });

    if (_isNameInvalid || _isCategoryInvalid || _isExpDateInvalid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields.')));
      return;
    }

    final String? finalImageUrl = await _uploadImageToFirebase();
    if (_selectedImage != null && finalImageUrl == null) return;

    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final updatedItem = PantryItemModel(
      id: widget.item.id,
      householdId: widget.item.householdId,
      name: _nameCtrl.text,
      category: _selectedCategory!,
      price: double.tryParse(_priceCtrl.text) ?? 0.0,
      imageUrl: finalImageUrl,
      qty: _quantity,
      netWeight: _netWeightCtrl.text.trim().isEmpty ? null : '${_netWeightCtrl.text.trim()} $_selectedUnit',
      notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
      expirationDate: DateFormat('MMMM d, yyyy').parse(_expCtrl.text),
      manufacturedDate: widget.item.manufacturedDate,
      storageLocation: widget.item.storageLocation,
    );

    await firestoreService.updatePantryItem(updatedItem);
    if (!mounted) return;
    _showSuccessDialog(updatedItem);
  }

  Future<void> _deleteItemFromDatabase() async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    if (widget.item.id != null) {
      await firestoreService.deletePantryItem(widget.item.id!);
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(context: context, builder: (ctx) =>
    SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Take Photo'),
              onTap: () { Navigator.of(ctx).pop(); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Choose from Gallery'),
              onTap: () { Navigator.of(ctx).pop(); _pickImage(ImageSource.gallery); },
            ),
            if (_selectedImage != null || _imageUrlFromItem != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Image'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() { _selectedImage = null; _imageUrlFromItem = null; });
                },
              ),
          ],
        ),
      ));
  }

  void _showSaveOrDiscardConfirmationDialog() {
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
              Text('Unsaved Changes', style: TextStyle(color: inputTextColor, fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Inter')),
              const SizedBox(height: 8),
              Text('Do you want to save your edits or discard them?', style: TextStyle(color: labelTextColor, fontSize: 16, fontFamily: 'Inter'), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(backgroundColor: const Color(0xFF9E9E9E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () { Navigator.of(dialogContext).pop(); Navigator.of(context).pop(); },
                      child: const Text('Discard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(backgroundColor: headerGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () { Navigator.of(dialogContext).pop(); _saveItem(); },
                      child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog() {
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
              Text('Delete Item', style: TextStyle(color: inputTextColor, fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Inter')),
              const SizedBox(height: 8),
              Text('Are you sure you want to permanently delete this item?', style: TextStyle(color: labelTextColor, fontSize: 16, fontFamily: 'Inter'), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(backgroundColor: const Color(0xFF9E9E9E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('No', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(backgroundColor: deleteButtonRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () async {
                        Navigator.of(dialogContext).pop();
                        await _deleteItemFromDatabase();
                        if (mounted) _showItemDeletedDialog();
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

  void _showSuccessDialog(PantryItemModel updatedItem) {
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
              Text('Success!', style: TextStyle(color: headerGreen, fontSize: 24, fontWeight: FontWeight.w800, fontFamily: 'Inter')),
              const SizedBox(height: 8),
              Text('Pantry item updated!', style: TextStyle(color: inputTextColor, fontSize: 16, fontFamily: 'Inter'), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(backgroundColor: headerGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () { Navigator.of(dialogContext).pop(); Navigator.of(context).pop(updatedItem); },
                  child: const Text('Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Inter')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showItemDeletedDialog() {
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
              Icon(Icons.cancel_outlined, color: deleteButtonRed, size: 60),
              const SizedBox(height: 16),
              Text('Deleted!', style: TextStyle(color: deleteButtonRed, fontSize: 24, fontWeight: FontWeight.w800, fontFamily: 'Inter')),
              const SizedBox(height: 8),
              Text('Pantry item has been deleted.', style: TextStyle(color: inputTextColor, fontSize: 16, fontFamily: 'Inter'), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(backgroundColor: deleteButtonRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () { Navigator.of(dialogContext).pop(); Navigator.of(context).popUntil((route) => route.isFirst); },
                  child: const Text('Continue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Inter')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget textField(TextEditingController ctrl, {required String labelText, bool readOnly = false, VoidCallback? onTap, BorderSide? borderSide, TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters, Widget? suffixIcon, String? errorText, void Function(String)? onChanged}) {
    return TextField(
      controller: ctrl,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: labelText,
        suffixIcon: suffixIcon,
        errorText: errorText,
        labelStyle: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 14, color: labelTextColor),
        filled: true,
        fillColor: inputFillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: borderSide ?? BorderSide(color: inputBorderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: borderSide ?? BorderSide(color: inputBorderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: (borderSide ?? BorderSide(color: inputBorderColor)).copyWith(color: headerGreen, width: 2.0)),
      ),
    );
  }

  Widget _quantityField() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Quantity',
        labelStyle: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 14, color: labelTextColor),
        filled: true, fillColor: inputFillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: inputBorderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: inputBorderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: Icon(Icons.remove, color: headerGreen), onPressed: () { if (_quantity > 1) setState(() { _quantity--; _quantityCtrl.text = _quantity.toString(); }); }),
          SizedBox(
            width: 40,
            child: TextField(
              controller: _quantityCtrl, textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
              onChanged: (value) {
                final newQuantity = int.tryParse(value);
                if (newQuantity != null && newQuantity > 0) _quantity = newQuantity;
              },
            ),
          ),
          IconButton(icon: Icon(Icons.add, color: headerGreen), onPressed: () => setState(() { _quantity++; _quantityCtrl.text = _quantity.toString(); })),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nameBorderSide = _isNameInvalid ? BorderSide(color: errorColor, width: 1.5) : null;
    final categoryBorderSide = _isCategoryInvalid ? BorderSide(color: errorColor, width: 1.5) : BorderSide(color: inputBorderColor);
    final expDateBorderSide = _isExpDateInvalid ? BorderSide(color: errorColor, width: 1.5) : null;

    Widget imageWidget;
    if (_selectedImage != null) {
      imageWidget = Image.file(_selectedImage!, fit: BoxFit.cover, width: 100, height: 100);
    } else if (_imageUrlFromItem != null && _imageUrlFromItem!.isNotEmpty) {
      imageWidget = Image.network(_imageUrlFromItem!, fit: BoxFit.cover, width: 100, height: 100);
    } else {
      imageWidget = const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt, color: Colors.grey, size: 30), SizedBox(height: 4), Text('Add Photo', style: TextStyle(color: Colors.grey, fontSize: 10))]));
    }
    
    return Scaffold(
      backgroundColor: softCream,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: headerGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: _showSaveOrDiscardConfirmationDialog,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IconButton(
              icon: _isUploadingImage ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save, color: Colors.white, size: 28),
              onPressed: _isUploadingImage ? null : _saveItem,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 180 + MediaQuery.of(context).padding.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Pantry Item', style: TextStyle(color: headerGreen, fontWeight: FontWeight.w800, fontSize: 28)),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _showImagePickerOptions,
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(12), border: Border.all(color: (_selectedImage != null || (_imageUrlFromItem != null && _imageUrlFromItem!.isNotEmpty)) ? headerGreen : Colors.grey, width: 2)),
                    child: ClipRRect(borderRadius: BorderRadius.circular(10), child: imageWidget),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      textField(_nameCtrl, labelText: 'Item Name', borderSide: nameBorderSide, onChanged: (value) {
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce = Timer(const Duration(milliseconds: 500), () {
                          final suggestedCategory = _suggestCategoryFromName(value);
                          if (suggestedCategory != _selectedCategory) {
                            setState(() {
                              _selectedCategory = suggestedCategory;
                              _updateExpirationDateFromCategory();
                            });
                          }
                        });
                      }),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField2<String>(
              value: _selectedCategory, isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Category', labelStyle: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 14, color: labelTextColor),
                filled: true, fillColor: inputFillColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: categoryBorderSide),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: categoryBorderSide),
              ),
              items: _categories.map((c) => DropdownMenuItem<String>(value: c, child: Text(c, style: TextStyle(fontSize: 16, color: inputTextColor)))).toList(),
              onChanged: (val) => setState(() {
                _selectedCategory = val;
                if (val != null) _isCategoryInvalid = false;
                _updateExpirationDateFromCategory();
              }),
            ),
            const SizedBox(height: 20),
            textField(_expCtrl, labelText: 'Date of Expiration', readOnly: true, borderSide: expDateBorderSide,
              onTap: () async {
                final pickedDate = await showDatePicker(context: context, initialDate: widget.item.expirationDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                if (pickedDate != null) {
                  setState(() => _expCtrl.text = DateFormat('MMMM d, yyyy').format(pickedDate));
                }
              },
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: textField(_priceCtrl, labelText: 'Item Price', keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                const SizedBox(width: 12),
                Expanded(child: _quantityField()),
              ],
            ),
            const SizedBox(height: 20),
             textField(
              _netWeightCtrl, 
              labelText: 'Net Weight', 
              errorText: _netWeightErrorText,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton2<String>(
                    value: _selectedUnit,
                    items: _units.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value, style: TextStyle(color: inputTextColor, fontSize: 16)))).toList(),
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
            const SizedBox(height: 20),
            textField(_notesCtrl, labelText: 'Notes'),
            const SizedBox(height: 30),
            Center(
              child: TextButton(
                onPressed: _showDeleteConfirmationDialog,
                child: Text("Delete Item", style: TextStyle(color: deleteButtonRed, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: IgnorePointer(
        child: SizedBox(
          height: 180 + MediaQuery.of(context).padding.bottom,
          child: Image.asset(
            'assets/footer1e27d32-trans.png',
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
