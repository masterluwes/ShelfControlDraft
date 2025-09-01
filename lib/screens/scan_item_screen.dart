import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:shelf_control/services/open_food_facts_service.dart';
import 'package:shelf_control/models/pantry_item_model.dart'; // Import the new model
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore operations
import 'package:logger/logger.dart'; // Import the logger package
import 'package:mobile_scanner/mobile_scanner.dart'; // Import the new scanner package

class ScanItemScreen extends StatefulWidget {
  const ScanItemScreen({super.key});

  @override
  State<ScanItemScreen> createState() => _ScanItemScreenState();
}

class _ScanItemScreenState extends State<ScanItemScreen> {
  String _barcode = 'Unknown';
  bool _isLoading = false;
  Map<String, dynamic>? _productData;
  final OpenFoodFactsService _openFoodFactsService = OpenFoodFactsService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger(); // Initialize logger
  late MobileScannerController _scannerController; // Declare controller

  // Controllers for editable fields in the bottom sheet
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  String _selectedCategory = 'Uncategorized'; // Default category

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _brandController.dispose();
    _quantityController.dispose();
    _scannerController.dispose(); // Dispose the scanner controller
    super.dispose();
  }

  Future<void> _processBarcode(String barcodeScanRes) async {
    if (!mounted) return;

    setState(() {
      _barcode = barcodeScanRes;
      _isLoading = true;
      _productData = null; // Clear previous product data
    });

    if (_barcode != '-1') {
      await _fetchProductDetails(_barcode);
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchProductDetails(String barcode) async {
    final product = await _openFoodFactsService.fetchProductByBarcode(barcode);
    if (!mounted) return; // Guard against context use after async gap

    setState(() {
      _productData = product;
      _isLoading = false;
    });

    if (_productData != null) {
      _productNameController.text = _productData!['product_name'] ?? '';
      _brandController.text = _productData!['brands'] ?? '';
      _quantityController.text = _productData!['quantity'] ?? '1';
      _showProductDetailsBottomSheet();
    } else {
      if (!mounted) return; // Guard against context use after async gap
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product not found or error fetching data.')),
      );
    }
  }

  Future<void> _savePantryItem(PantryItemModel item) async {
    try {
      await _firestore.collection('pantryItems').add(item.toFirestore());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added to pantry successfully!')),
        );
        Navigator.pop(context); // Close the bottom sheet and go back to the dashboard
      }
    } catch (e) {
      _logger.e('Error saving item to Firestore: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add product: $e')),
        );
      }
    }
  }

  void _showProductDetailsBottomSheet() {
    showMaterialModalBottomSheet(
      context: context,
      builder: (context) => SingleChildScrollView(
        controller: ModalScrollController.of(context),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Product Details',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              if (_productData?['image_front_url'] != null)
                Image.network(
                  _productData!['image_front_url'],
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 10),
              TextField(
                controller: _productNameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
              ),
              TextField(
                controller: _brandController,
                decoration: const InputDecoration(labelText: 'Brand'),
              ),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity'),
              ),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: <String>['Uncategorized', 'Beverages', 'Condiments', 'Herbs/Spices', 'Canned Goods', 'Dairy', 'Produce', 'Meat', 'Snacks']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final newItem = PantryItemModel(
                    name: _productNameController.text,
                    category: _selectedCategory,
                    imageUrl: _productData?['image_front_url'],
                    qty: int.tryParse(_quantityController.text) ?? 1,
                    barcode: _barcode,
                    brand: _brandController.text,
                    quantityUnit: _productData?['quantity'], // Use raw quantity from API for unit
                  );
                  _savePantryItem(newItem);
                },
                child: const Text('Add to Pantry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan a Barcode'),
        backgroundColor: const Color(0xFFFF9800), // Orange color from screenshot
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
              height: MediaQuery.of(context).size.height * 0.4, // 40% of screen height
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: MobileScanner(
                controller: _scannerController,
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    final String? barcodeScanRes = barcodes.first.rawValue;
                    if (barcodeScanRes != null && barcodeScanRes.isNotEmpty) {
                      _logger.d('Scanned barcode: $barcodeScanRes');
                      _processBarcode(barcodeScanRes);
                    }
                  }
                },
              ),
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (_productData != null && !_isLoading)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.white.withAlpha((0.8 * 255).round()),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Product Name: ${_productData!['product_name'] ?? 'N/A'}'),
                    Text('Brand: ${_productData!['brands'] ?? 'N/A'}'),
                    Text('Quantity: ${_productData!['quantity'] ?? 'N/A'}'),
                    ElevatedButton(
                      onPressed: () {
                        _showProductDetailsBottomSheet();
                      },
                      child: const Text('Edit & Add to Pantry'),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 16,
            left: 16,
            child: Text(
              'Barcodes scanned: ${_barcode == 'Unknown' ? '0' : '1'}', // Simple count for demonstration
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
