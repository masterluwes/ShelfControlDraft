import 'dart:io';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shelf_control/models/pantry_item_model.dart';

class AddPantryItem extends StatefulWidget {
  final Function(PantryItemModel) onAddItem;
  final VoidCallback onBack;
  const AddPantryItem({
    super.key,
    required this.onAddItem,
    required this.onBack,
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
  // ⭐️ Red button color for the Delete Item button
  final Color deleteButtonRed = const Color(0xFFF44336);

  // Controllers for all fields
  late TextEditingController _nameCtrl;
  late TextEditingController _brandCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _netWeightCtrl;
  late TextEditingController _expCtrl;
  late TextEditingController _notesCtrl;
  int _quantity = 1;

  final FocusNode _notesFocusNode = FocusNode();
  final FocusNode _priceFocusNode = FocusNode();

  // Image picker state
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;

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

  String _selectedUnit = 'lbs';
  final List<String> _units = ['lbs', 'kg', 'g', 'L', 'mL'];

  bool _isNameInvalid = false;
  bool _isCategoryInvalid = false;
  bool _isExpDateInvalid = false;
  bool _isPriceInvalid = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _brandCtrl = TextEditingController();
    _priceCtrl = TextEditingController(text: '0.00');
    _netWeightCtrl = TextEditingController(text: '0.0');
    _expCtrl = TextEditingController();
    _notesCtrl = TextEditingController();

    _nameCtrl.addListener(() {
      if (_isNameInvalid && _nameCtrl.text.isNotEmpty) {
        setState(() => _isNameInvalid = false);
      } else {
        setState(() {});
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

    _notesFocusNode.addListener(_onNotesFocusChange);
    _priceFocusNode.addListener(_formatPrice);
  }

  void _onNotesFocusChange() {
    if (_notesFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 300), () {
        Scrollable.ensureVisible(
          _notesFocusNode.context!,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: 0.05,
        );
      });
    }
  }

  // Function to format the price to two decimal places
  void _formatPrice() {
    // This runs when you tap away from the price field
    if (!_priceFocusNode.hasFocus) {
      final String currentText = _priceCtrl.text;
      final double? value = double.tryParse(currentText);

      if (value != null) {
        // This line ensures two decimal places
        _priceCtrl.text = value.toStringAsFixed(2);
      } else {
        _priceCtrl.text = '0.00';
      }
    }
  }

  void _formatNetWeight() {
    final currentValue = _netWeightCtrl.text.trim();
    if (currentValue.isNotEmpty) {
      final numValue = double.tryParse(currentValue);
      if (numValue != null) {
        if (_shouldUseDecimalFormat()) {
          if (!currentValue.contains('.')) {
            _netWeightCtrl.text = '$currentValue.0';
          }
        } else {
          if (currentValue.endsWith('.0')) {
            _netWeightCtrl.text = currentValue.replaceAll('.0', '');
          } else if (!currentValue.contains('.')) {
            _netWeightCtrl.text = currentValue;
          }
        }
      }
    }
  }

  bool _shouldUseDecimalFormat() {
    return _selectedUnit == 'lbs' || _selectedUnit == 'kg';
  }

  @override
  void dispose() {
    _notesFocusNode.removeListener(_onNotesFocusChange);
    _notesFocusNode.dispose();

    _priceFocusNode.removeListener(_formatPrice);
    _priceFocusNode.dispose();

    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _priceCtrl.dispose();
    _netWeightCtrl.dispose();
    _expCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  void _showImagePickerOptions() {
    final optionTextStyle = TextStyle(
      fontFamily: 'Roboto',
      color: inputTextColor,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: Text('Take Photo', style: optionTextStyle),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: Text('Choose from Gallery', style: optionTextStyle),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text('Remove Image', style: optionTextStyle),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _selectedImage = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _uploadImageToFirebase() async {
    if (_selectedImage == null) return null;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final String fileName =
          'pantry_items/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = FirebaseStorage.instance.ref().child(fileName);

      final UploadTask uploadTask = ref.putFile(_selectedImage!);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _isUploadingImage = false;
      });

      return downloadUrl;
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      if (!mounted) return null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      return null;
    }
  }

  // 💥 FIX: Modified _addItem to show the styled success dialog, centered, and without an OK button
  Future<void> _addItem() async {
    final price = double.tryParse(_priceCtrl.text) ?? 0.0;
    setState(() {
      _isNameInvalid = _nameCtrl.text.isEmpty;
      _isCategoryInvalid = _selectedCategory == null;
      _isExpDateInvalid = _expCtrl.text.isEmpty;
      _isPriceInvalid = price <= 0.0;
    });

    if (_isNameInvalid ||
        _isCategoryInvalid ||
        _isExpDateInvalid ||
        _isPriceInvalid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields marked in red.'),
        ),
      );
      return;
    }

    String? imageUrl = await _uploadImageToFirebase();
    if (imageUrl == null && _selectedImage != null) {
      return;
    }

    final newItem = PantryItemModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text,
      category: _selectedCategory!,
      imageUrl: imageUrl ?? 'https://via.placeholder.com/150',
      qty: _quantity,
      expiresText: _expCtrl.text,
      expirationDate: DateFormat('MMMM d, yyyy').parse(_expCtrl.text),
    );

    // 1. Add item using the callback
    widget.onAddItem(newItem);

    // 2. Show the styled success dialog
    await showDialog(
      context: context,
      barrierDismissible: true, // Allow dismissal by tapping outside/back button
      builder: (BuildContext context) {
        // Use a 2-second timer to automatically close the dialog
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
        
        return AlertDialog(
          // Set actions to an empty list to remove the default buttons
          actions: const [],
          // Set the shape
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Column(
            // Center the content horizontally
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 20), 
              Text(
                'Success!',
                textAlign: TextAlign.center, // Ensure text is centered
                style: TextStyle(
                  color: headerGreen, // Main green color
                  fontWeight: FontWeight.bold, 
                  fontSize: 24, // Distinct size
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Pantry item added!',
                textAlign: TextAlign.center, // Ensure text is centered
                style: TextStyle(
                  color: Colors.black, // Default color
                  fontWeight: FontWeight.normal, 
                  fontSize: 16, // Smaller size
                ),
              ),
            ],
          ),
        );
      },
    );

    // 3. After the dialog is dismissed (either by the timer or user interaction), 
    // navigate back to the previous screen.
    if (mounted) {
      widget.onBack();
    }
  }

  // --- MODIFIED: Returns a nullable double to signal conversion success/failure ---
  double? _convertNetWeight(double value, String from, String to) {
    if (from == to) return value;

    // Define unit categories to prevent converting weight to volume, etc.
    const weightUnits = ['g', 'kg', 'lbs'];
    const volumeUnits = ['mL', 'L'];

    final bool isWeightConversion =
        weightUnits.contains(from) && weightUnits.contains(to);
    final bool isVolumeConversion =
        volumeUnits.contains(from) && volumeUnits.contains(to);

    // If units are not compatible (e.g., kg to L), return null to signal failure.
    if (!isWeightConversion && !isVolumeConversion) {
      return null;
    }

    // --- Conversion factors ---
    const gPerKg = 1000.0;
    const gPerLbs = 453.592;
    const mlPerL = 1000.0;

    // Step 1: Convert the input value to a base unit (grams for weight, mL for volume)
    double valueInBaseUnit;
    switch (from) {
      case 'kg':
        valueInBaseUnit = value * gPerKg;
        break;
      case 'lbs':
        valueInBaseUnit = value * gPerLbs;
        break;
      case 'L':
        valueInBaseUnit = value * mlPerL;
        break;
      case 'g':
      case 'mL':
      default:
        valueInBaseUnit = value;
        break;
    }

    // Step 2: Convert from the base unit to the target unit
    double convertedValue;
    switch (to) {
      case 'kg':
        convertedValue = valueInBaseUnit / gPerKg;
        break;
      case 'lbs':
        convertedValue = valueInBaseUnit / gPerLbs;
        break;
      case 'L':
        convertedValue = valueInBaseUnit / mlPerL;
        break;
      case 'g':
      case 'mL':
      default:
        convertedValue = valueInBaseUnit;
        break;
    }

    return convertedValue;
  }
  
  // ⭐️ Function to show a confirmation dialog for discarding changes
  Future<void> _showDiscardConfirmationDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        // Automatically close the dialog after 3 seconds, consistent with other dialogs
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });

        return AlertDialog(
          actions: const [],
          // Ensures consistent shape
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Column(
            mainAxisSize: MainAxisSize.min, 
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 20),
              Text(
                'Changes Discarded!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  // Uses red errorColor for discard/cancellation notice
                  color: errorColor, 
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Edits to pantry item discarded.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );

    // After the dialog is dismissed, navigate back.
    if (mounted) {
      widget.onBack();
    }
  }


  // 🔄 MODIFIED: Replaces _showCancelConfirmationDialog
  void _showSaveOrDiscardConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must press one of the options
      builder: (BuildContext context) {
        return AlertDialog(
          // Shape and background color match the image
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.white,
          // contentPadding adjusted to match the compact look in the image
          contentPadding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
          
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                'Unsaved Changes',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: headerGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Do you want to save or discard your edits?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: inputTextColor,
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // DISCARD button (Grey, Solid background)
                  SizedBox(
                    width: 90,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        // Grey color (matches 'No' button in original UI)
                        backgroundColor: const Color(0xFF9E9E9E), 
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(); // Close confirmation dialog
                        _showDiscardConfirmationDialog(); // Show discard message and navigate back
                      },
                      child: const Text(
                        'Discard',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // SAVE button (Green, Solid background)
                  SizedBox(
                    width: 90,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        // Green color (matches 'Yes' button in original UI)
                        backgroundColor: const Color(0xFF4CAF50), 
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(); // Close confirmation dialog
                        // Re-trigger the save function
                        _addItem();
                      },
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          color: Colors.white, 
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: const [], // Remove default actions
        );
      },
    );
  }

  // ⭐️ Function to display the "Deleted!" success dialog
  Future<void> _showDeletedDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: true, 
      builder: (BuildContext context) {
        // Automatically close the dialog after 3 seconds, mimicking the success dialog
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });

        return AlertDialog(
          actions: const [],
          // Shape consistent with the UI image
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Column(
            mainAxisSize: MainAxisSize.min, 
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 20),
              Text(
                'Deleted!', // Title text as per UI image
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: headerGreen, // Green color as per UI image
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Pantry item deleted!', // Subtext as per UI image
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      },
    );

    // After the dialog is dismissed, navigate back (assuming deletion finishes the flow).
    if (mounted) {
      widget.onBack();
    }
  }

  // ⭐️ Function to display the delete confirmation dialog (Based on UI image)
  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must press Yes/No
      builder: (BuildContext context) {
        return AlertDialog(
          // Shape and background color match the image
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.white,
          // contentPadding matches the visual look in the image
          contentPadding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
          
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                'Delete Pantry Item', // Title from UI image
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: headerGreen, // Green color from UI image
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Are you sure you want to delete this item?', // Question from UI image
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: inputTextColor,
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // YES button (Green, Solid background)
                  SizedBox(
                    width: 90,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50), // Green from UI image
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(); // Close confirmation dialog
                        _showDeletedDialog(); // Show the final deleted dialog
                      },
                      child: const Text(
                        'Yes',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  // NO button (Grey, Solid background)
                  SizedBox(
                    width: 90,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF9E9E9E), // Gray from UI image
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(); // Close confirmation dialog, stay on the page
                      },
                      child: const Text(
                        'No',
                        style: TextStyle(
                          color: Colors.white, // White text to match the image
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: const [], // Remove default actions
        );
      },
    );
  }

  Widget textField(
    TextEditingController ctrl, {
    required String labelText,
    String? prefixText,
    String hintText = '',
    bool readOnly = false,
    int maxLines = 1,
    FocusNode? focusNode,
    VoidCallback? onTap,
    VoidCallback? onSubmitted,
    TextInputType keyboardType = TextInputType.text,
    Widget? prefixIcon,
    Widget? suffixIcon,
    BorderSide? borderSide,
  }) {
    final currentBorderSide = borderSide ?? BorderSide(color: inputBorderColor);

    return TextField(
      controller: ctrl,
      readOnly: readOnly,
      maxLines: maxLines,
      focusNode: focusNode,
      onTap: onTap,
      onSubmitted: onSubmitted != null ? (_) => onSubmitted() : null,
      style: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 16,
        color: inputTextColor,
        fontWeight: FontWeight.normal,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        prefixText: prefixText,
        labelStyle: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: labelTextColor,
        ),
        hintText: hintText,
        filled: true,
        fillColor: inputFillColor,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: currentBorderSide,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: currentBorderSide,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: currentBorderSide.copyWith(width: 2.0),
        ),
      ),
      keyboardType: keyboardType,
    );
  }

  Widget _quantityField() {
    final borderSide = BorderSide(color: headerGreen, width: 1.5);

    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Quantity',
        labelStyle: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: labelTextColor,
        ),
        filled: true,
        fillColor: inputFillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: borderSide,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: borderSide,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: borderSide.copyWith(width: 2.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.remove, color: headerGreen),
            onPressed: () {
              if (_quantity > 1) setState(() => _quantity--);
            },
          ),
          Text(
            '$_quantity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
              color: inputTextColor,
            ),
          ),
          IconButton(
            icon: Icon(Icons.add, color: headerGreen),
            onPressed: () => setState(() => _quantity++),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nameBorderSide = _isNameInvalid
        ? BorderSide(color: errorColor, width: 1.5)
        : _nameCtrl.text.isNotEmpty
            ? BorderSide(color: headerGreen, width: 1.5)
            : BorderSide(color: inputBorderColor);

    final categoryBorderSide = _isCategoryInvalid
        ? BorderSide(color: errorColor, width: 1.5)
        : _selectedCategory != null
            ? BorderSide(color: headerGreen, width: 1.5)
            : BorderSide(color: inputBorderColor);

    final expDateBorderSide = _isExpDateInvalid
        ? BorderSide(color: errorColor, width: 1.5)
        : _expCtrl.text.isNotEmpty
            ? BorderSide(color: headerGreen, width: 1.5)
            : BorderSide(color: inputBorderColor);

    final priceValue = double.tryParse(_priceCtrl.text) ?? 0.0;
    final priceBorderSide = _isPriceInvalid
        ? BorderSide(color: errorColor, width: 1.5)
        : priceValue > 0.0
            ? BorderSide(color: headerGreen, width: 1.5)
            : BorderSide(color: inputBorderColor);

    return Scaffold(
      backgroundColor: softCream,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: headerGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          // 🔄 MODIFIED: Call the save/discard confirmation dialog
          onPressed: _showSaveOrDiscardConfirmationDialog,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IconButton(
              icon: _isUploadingImage
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save, color: Colors.white, size: 28),
              onPressed: _isUploadingImage ? null : _addItem,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/footer1e27d32-trans.png',
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  // Reduced bottom padding slightly for the smaller button size
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 140), 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Pantry Item',
                        style: TextStyle(
                          color: headerGreen,
                          fontWeight: FontWeight.w800,
                          fontSize: 28,
                        ),
                      ),
                      const SizedBox(height: 24),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            GestureDetector(
                              onTap: _showImagePickerOptions,
                              child: Container(
                                width: 100,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0E0E0),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _selectedImage != null
                                        ? headerGreen
                                        : Colors.grey,
                                    width: 2,
                                  ),
                                ),
                                child: _selectedImage != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.cover,
                                          width: 100,
                                          height: 100,
                                        ),
                                      )
                                    : _isUploadingImage
                                        ? const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.green,
                                            ),
                                          )
                                        : const Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.camera_alt,
                                                  color: Colors.grey,
                                                  size: 30,
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  'Add Photo',
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  textField(
                                    _nameCtrl,
                                    labelText: 'Item Name',
                                    borderSide: nameBorderSide,
                                  ),
                                  const SizedBox(height: 14),
                                  textField(_brandCtrl, labelText: 'Brand'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField2<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          labelStyle: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: labelTextColor,
                          ),
                          filled: true,
                          fillColor: inputFillColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: categoryBorderSide,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: categoryBorderSide,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                        items: _categories
                            .map(
                              (c) => DropdownMenuItem<String>(
                                value: c,
                                child: Text(
                                  c,
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 16,
                                    color: inputTextColor,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => setState(() {
                          _selectedCategory = val;
                          if (val != null) _isCategoryInvalid = false;
                        }),
                        dropdownStyleData: DropdownStyleData(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      textField(
                        _expCtrl,
                        labelText: 'Date of Expiration',
                        hintText: 'October 5, 2025',
                        readOnly: true,
                        borderSide: expDateBorderSide,
                        prefixIcon: Icon(
                          Icons.calendar_today,
                          color: headerGreen,
                          size: 20,
                        ),
                        // --- MODIFIED: The onTap function now includes a themed builder ---
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary:
                                        headerGreen, // Main color for header and selected day
                                    onPrimary: Colors
                                        .white, // Text color on top of the main color
                                    onSurface:
                                        inputTextColor, // Color for the days of the month
                                  ),
                                  textButtonTheme: TextButtonThemeData(
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          headerGreen, // Color for "OK" and "Cancel" buttons
                                    ),
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (pickedDate != null) {
                            setState(
                              () => _expCtrl.text = DateFormat(
                                'MMMM d, yyyy',
                              ).format(pickedDate),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: textField(
                              _priceCtrl,
                              labelText: 'Item Price',
                              prefixText: '₱ ',
                              focusNode: _priceFocusNode,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              borderSide: priceBorderSide,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: _quantityField()),
                        ],
                      ),
                      const SizedBox(height: 20),
                      textField(
                        _netWeightCtrl,
                        labelText: 'Net Weight',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onSubmitted: _formatNetWeight,
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton2<String>(
                              value: _selectedUnit,
                              items: _units
                                  .map(
                                    (String value) => DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        style: TextStyle(
                                          color: inputTextColor,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              // --- MODIFIED: Handles failed conversions by showing a message ---
                              onChanged: (String? newValue) {
                                if (newValue == null ||
                                    newValue == _selectedUnit) return;

                                final fromUnit = _selectedUnit;
                                final toUnit = newValue;
                                final currentText = _netWeightCtrl.text.trim();
                                final numValue = double.tryParse(currentText);

                                // Update the selected unit in the dropdown immediately
                                setState(() {
                                  _selectedUnit = toUnit;
                                });

                                if (numValue == null) return;

                                // Attempt the conversion
                                final convertedValue = _convertNetWeight(
                                  numValue.toDouble(),
                                  fromUnit,
                                  toUnit,
                                );

                                if (convertedValue != null) {
                                  // --- SUCCESS: Conversion was valid ---
                                  final formatter = NumberFormat("0.###");
                                  _netWeightCtrl.text = formatter.format(
                                    convertedValue,
                                  );
                                } else {
                                  // --- FAILURE: Conversion was invalid ---
                                  // Show a snackbar message and leave the number unchanged.
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Cannot convert from $fromUnit to $toUnit.",
                                        style: const TextStyle(
                                          fontFamily: 'Roboto',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16.0,
                                        ),
                                      ),
                                      backgroundColor: Colors.orange[800],
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      // --- NEW: Added margin to control the width ---
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 16,
                                      ),
                                    ),
                                  );
                                }
                              },
                              iconStyleData: IconStyleData(
                                icon: Icon(
                                  Icons.unfold_more,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                              ),
                              buttonStyleData: const ButtonStyleData(
                                padding: EdgeInsets.zero,
                                height: 40,
                              ),
                              dropdownStyleData: DropdownStyleData(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      textField(
                        _notesCtrl,
                        labelText: 'Notes',
                        hintText: 'No notes for this item.',
                        maxLines: 3,
                        focusNode: _notesFocusNode,
                      ),
                      const SizedBox(height: 20),
                      // 🚀 MODIFIED: Delete Item Button (fixed width, centered, reduced height)
                      Center(
                        child: SizedBox(
                          // Fixed width to make it smaller and centered
                          width: 200, 
                          height: 38, // **REDUCED HEIGHT**
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: deleteButtonRed, // Bright red color
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _showDeleteConfirmationDialog,
                            child: const Text(
                              'Delete Item',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}