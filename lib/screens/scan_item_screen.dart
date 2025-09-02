import 'package:flutter/material.dart';
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
  bool _isLoading = false;
  final OpenFoodFactsService _openFoodFactsService = OpenFoodFactsService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger(); // Initialize logger
  late MobileScannerController _scannerController; // Declare controller
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  bool _isSheetExpanded = false;

  final List<PantryItemModel> _scannedItems = [];
  int _currentItemIndex = 0;

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
    _sheetController.addListener(_onSheetScrolled);
  }

  void _onSheetScrolled() {
    if (!mounted) return;
    final isExpanded = _sheetController.size > 0.2;
    if (_isSheetExpanded != isExpanded) {
      setState(() {
        _isSheetExpanded = isExpanded;
      });
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _brandController.dispose();
    _quantityController.dispose();
    _scannerController.dispose(); // Dispose the scanner controller
    _sheetController.removeListener(_onSheetScrolled);
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _processBarcode(String barcodeScanRes) async {
    if (!mounted) return;
    if (_isLoading) return; // Prevent multiple scans

    setState(() {
      _isLoading = true;
    });

    await _fetchProductDetails(barcodeScanRes);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchProductDetails(String barcode) async {
    final product = await _openFoodFactsService.fetchProductByBarcode(barcode);
    if (!mounted) return;

    if (product != null) {
      final newItem = PantryItemModel(
        name: product['product_name'] ?? 'Unknown Product',
        category: _selectedCategory,
        imageUrl: product['image_front_url'],
        qty: 1,
        barcode: barcode,
        brand: product['brands'] ?? 'Unknown Brand',
        quantityUnit: product['quantity'],
        nutritionFacts: product['nutriments'] is Map ? Map<String, dynamic>.from(product['nutriments']) : null,
      );

      setState(() {
        _scannedItems.add(newItem);
        _currentItemIndex = _scannedItems.length - 1;
        _updateControllersForItem(_currentItemIndex);
        _scannerController.stop();
      });

      // Expand the sheet after a successful scan
      _sheetController.animateTo(
        0.9,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product not found or error fetching data.')),
      );
    }
  }

  void _updateControllersForItem(int index) {
    if (index < 0 || index >= _scannedItems.length) return;
    final item = _scannedItems[index];
    _productNameController.text = item.name;
    _brandController.text = item.brand ?? '';
    _quantityController.text = item.qty.toString();
    _selectedCategory = item.category;
  }

  Future<void> _saveAllItems() async {
    if (_scannedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items to save.')),
      );
      return;
    }

    try {
      final batch = _firestore.batch();
      for (var item in _scannedItems) {
        final docRef = _firestore.collection('pantryItems').doc();
        batch.set(docRef, item.toFirestore());
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_scannedItems.length} items added to pantry successfully!')),
        );
        setState(() {
          _scannedItems.clear();
          _currentItemIndex = 0;
        });
        Navigator.pop(context); // Go back to the dashboard
      }
    } catch (e) {
      _logger.e('Error saving items to Firestore: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add products: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan a Barcode',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Camera View
          MobileScanner(
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

          // Overlay
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              const Color.fromARGB(128, 0, 0, 0),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.height * 0.3,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Barcode Count
          Positioned(
            top: kToolbarHeight + MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: Text(
              'Barcodes scanned: ${_scannedItems.length}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),

          // Bottom Sheet
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.1,
            minChildSize: 0.1,
            maxChildSize: 0.9,
            expand: true,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    // Custom Top Bar
                    GestureDetector(
                      onTap: () {
                        if (_isSheetExpanded) {
                          _sheetController.animateTo(0.1, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                        } else {
                          _sheetController.animateTo(0.9, duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
                        }
                      },
                      child: Container(
                        height: 50,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2E7D32), // Theme color
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(_isSheetExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up, color: Colors.white),
                              onPressed: () {
                                if (_isSheetExpanded) {
                                  _sheetController.animateTo(0.1, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                                } else {
                                  _sheetController.animateTo(0.9, duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
                                }
                              },
                            ),
                            Text(
                              _scannedItems.isNotEmpty ? 'Item ${_currentItemIndex + 1} of ${_scannedItems.length}' : 'Scan an item',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.add, color: Colors.white),
                                  onPressed: () {
                                    setState(() {
                                      _scannerController.start();
                                    });
                                    _sheetController.animateTo(0.1, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.check, color: Colors.white),
                                  onPressed: _saveAllItems,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Product Details Content
                    Expanded(
                      child: _scannedItems.isEmpty
                          ? const Center(child: Text('No items scanned yet.'))
                          : PageView.builder(
                              itemCount: _scannedItems.length,
                              controller: PageController(initialPage: _currentItemIndex),
                              onPageChanged: (index) {
                                setState(() {
                                  _currentItemIndex = index;
                                  _updateControllersForItem(index);
                                });
                              },
                              itemBuilder: (context, index) {
                                final item = _scannedItems[index];
                                return SingleChildScrollView(
                                  controller: scrollController,
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Product Details',
                                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: const Color(0xFF2E7D32)),
                                      ),
                                      const SizedBox(height: 10),
                                      if (item.imageUrl != null)
                                        Image.network(
                                          item.imageUrl!,
                                          height: 100,
                                          width: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 100),
                                        ),
                                      const SizedBox(height: 10),
                                      TextFormField(
                                        controller: _productNameController,
                                        decoration: InputDecoration(
                                          labelText: 'Product Name',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        onChanged: (value) => _scannedItems[_currentItemIndex].name = value,
                                      ),
                                      const SizedBox(height: 10),
                                      TextFormField(
                                        controller: _brandController,
                                        decoration: InputDecoration(
                                          labelText: 'Brand',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        onChanged: (value) => _scannedItems[_currentItemIndex].brand = value,
                                      ),
                                      const SizedBox(height: 10),
                                      TextFormField(
                                        controller: _quantityController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: 'Quantity',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        onChanged: (value) => _scannedItems[_currentItemIndex].qty = int.tryParse(value) ?? 1,
                                      ),
                                      const SizedBox(height: 10),
                                      DropdownButtonFormField<String>(
                                        value: _selectedCategory,
                                        decoration: InputDecoration(
                                          labelText: 'Category',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
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
                                            _scannedItems[_currentItemIndex].category = newValue;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 20),
                                      if (item.nutritionFacts != null)
                                        ExpansionTile(
                                          title: const Text('Nutrition Facts'),
                                          children: item.nutritionFacts!
                                              .entries
                                              .map((entry) => ListTile(
                                                    title: Text(entry.key.replaceAll('_', ' ').capitalize()),
                                                    trailing: Text(entry.value.toString()),
                                                  ))
                                              .toList(),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
