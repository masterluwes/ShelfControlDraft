import 'dart:async'; // Import for Timer
import 'package:flutter/material.dart';
import 'package:shelf_control/services/open_food_facts_service.dart';
import 'package:shelf_control/models/pantry_item_model.dart'; // Import the new model
import 'package:logger/logger.dart'; // Import the logger package
import 'package:mobile_scanner/mobile_scanner.dart'; // Import the new scanner package
import 'package:shelf_control/services/firestore_service.dart'; // Import FirestoreService
import 'package:provider/provider.dart'; // Import provider

class ScanItemScreen extends StatefulWidget {
  final bool isGuest;
  const ScanItemScreen({super.key, this.isGuest = false});

  @override
  State<ScanItemScreen> createState() => _ScanItemScreenState();
}

class _ScanItemScreenState extends State<ScanItemScreen> {
  bool _isLoading = false;
  bool _isProcessingBarcode = false; // New flag to prevent re-entry
  final OpenFoodFactsService _openFoodFactsService = OpenFoodFactsService();
  final Logger _logger = Logger(); // Initialize logger
  late MobileScannerController _scannerController; // Declare controller
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  bool _isSheetExpanded = false;

  final List<PantryItemModel> _scannedItems = [];
  int _currentItemIndex = 0;

  // Controllers for editable fields in the bottom sheet
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _netWeightController = TextEditingController(); // New controller for net weight
  String _selectedCategory = 'Uncategorized'; // Default category

  // Shelf-life related fields
  bool _useManufacturedAndShelfLife = false;
  String _selectedShelfLifeUnit = 'days'; // 'days', 'weeks', 'months'
  final TextEditingController _shelfLifeController = TextEditingController();
  DateTime? _manufacturedDate;
  DateTime? _expirationDate;

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
    final currentSize = _sheetController.size;
    final wasExpanded = _isSheetExpanded;
    // Use the hardcoded minChildSize value from the DraggableScrollableSheet
    const double minSheetSize = 0.12;
    final isNowExpanded = currentSize > minSheetSize + 0.01; // A small buffer

    if (wasExpanded && !isNowExpanded) {
      // Sheet is collapsing
      setState(() {
        _isSheetExpanded = false;
      });
      // If the sheet is fully collapsed, restart the scanner
      if (currentSize <= minSheetSize + 0.01) { // Check if it's at or very near min size
        _scannerController.start();
        _logger.d('Scanner restarted due to sheet collapse.');
      }
    } else if (!wasExpanded && isNowExpanded) {
      // Sheet is expanding
      setState(() {
        _isSheetExpanded = true;
      });
      // Stop scanner when sheet expands
      _scannerController.stop();
      _logger.d('Scanner stopped due to sheet expansion.');
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _quantityController.dispose();
    _netWeightController.dispose(); // Dispose net weight controller
    _shelfLifeController.dispose(); // Dispose shelf life controller
    _scannerController.dispose(); // Dispose the scanner controller
    _sheetController.removeListener(_onSheetScrolled);
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _processBarcode(String barcodeScanRes, FirestoreService firestoreService) async {
    if (!mounted || _isProcessingBarcode) return; // Prevent multiple scans or re-entry

    setState(() {
      _isLoading = true;
      _isProcessingBarcode = true; // Set flag to true
    });

    // Stop scanner immediately after a successful scan
    _scannerController.stop();
    _logger.d('Scanner stopped after barcode detection.');

    await _fetchProductDetails(barcodeScanRes, firestoreService);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isProcessingBarcode = false; // Reset flag
      });
    }
  }

  Future<void> _fetchProductDetails(String barcode, FirestoreService firestoreService) async {
    final product = await _openFoodFactsService.fetchProductByBarcode(barcode);
    if (!mounted) return;

    if (product != null) {
      if (firestoreService.selectedHouseholdId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final newItem = PantryItemModel(
        householdId: widget.isGuest ? 'guest_household' : firestoreService.selectedHouseholdId!, // Use a dummy ID for guests
        name: product['product_name'] ?? 'Unknown Product',
        category: _selectedCategory,
        imageUrl: product['image_front_url'],
        qty: 1,
        barcode: barcode,
        quantityUnit: product['quantity'],
        nutritionFacts: product['nutriments'] is Map ? Map<String, dynamic>.from(product['nutriments']) : null,
        // Re-adding shelf-life and date fields
        shelfLifeDays: null, // Will be set by user in sheet
        shelfLifeWeeks: null,
        shelfLifeMonths: null,
        manufacturedDate: null,
        expirationDate: null,
        netWeight: null, // Will be set by user in sheet
      );

      setState(() {
        _scannedItems.add(newItem);
        _currentItemIndex = _scannedItems.length - 1;
        _updateControllersForItem(_currentItemIndex);
      });

      // Expand the sheet after a successful scan, ensuring it happens after the build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_sheetController.isAttached) {
          _sheetController.animateTo(
            0.9,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          _logger.d('DraggableScrollableSheet animated to 0.9 (expanded).');
        } else {
          _logger.d('DraggableScrollableSheet not attached, cannot animate.');
        }
      });

    } else {
      // If product not found, restart scanner
      _scannerController.start();
      _logger.d('Scanner restarted after product not found.');
    }
  }

  void _updateControllersForItem(int index) {
    if (index < 0 || index >= _scannedItems.length) return;
    final item = _scannedItems[index];
    _productNameController.text = item.name;
    _quantityController.text = item.qty.toString();
    _netWeightController.text = item.netWeight ?? ''; // Update net weight controller
    _selectedCategory = item.category;

    // Update shelf-life and date fields
    _useManufacturedAndShelfLife = item.manufacturedDate != null || item.expirationDate != null || item.shelfLifeDays != null || item.shelfLifeWeeks != null || item.shelfLifeMonths != null;
    if (item.shelfLifeDays != null) {
      _selectedShelfLifeUnit = 'days';
      _shelfLifeController.text = item.shelfLifeDays.toString();
    } else if (item.shelfLifeWeeks != null) {
      _selectedShelfLifeUnit = 'weeks';
      _shelfLifeController.text = item.shelfLifeWeeks.toString();
    } else if (item.shelfLifeMonths != null) {
      _selectedShelfLifeUnit = 'months';
      _shelfLifeController.text = item.shelfLifeMonths.toString();
    } else {
      _shelfLifeController.clear();
    }
    _manufacturedDate = item.manufacturedDate;
    _expirationDate = item.expirationDate;
  }

  Future<void> _saveAllItems(FirestoreService firestoreService) async {
    if (_scannedItems.isEmpty) {
      return;
    }

    if (widget.isGuest) {
      List<PantryItemModel> guestPantry = await firestoreService.loadGuestPantryItems();
      guestPantry.addAll(_scannedItems);
      await firestoreService.saveGuestPantryItems(guestPantry);
    } else {
      for (final item in _scannedItems) {
        await firestoreService.addPantryItem(item);
      }
    }

    if (mounted) {
      Navigator.pop(context); // Pop after saving all items
    }
  }

  void _clearCurrentItemControllers() {
    _productNameController.clear();
    _quantityController.clear();
    _netWeightController.clear();
    _shelfLifeController.clear();
    setState(() {
      _selectedCategory = 'Uncategorized';
      _useManufacturedAndShelfLife = false;
      _selectedShelfLifeUnit = 'days';
      _manufacturedDate = null;
      _expirationDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan a Barcode',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2E7D32), // Keep green header
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      // extendBodyBehindAppBar: true, // Removed to keep green header
      body: Stack(
        children: [
          // Camera View
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              if (_isProcessingBarcode) return; // Prevent processing if already busy

              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? barcodeScanRes = barcodes.first.rawValue;
                if (barcodeScanRes != null && barcodeScanRes.isNotEmpty) {
                  _logger.d('Scanned barcode: $barcodeScanRes');
                  _processBarcode(barcodeScanRes, firestoreService);
                }
              }
            },
          ),

          // Overlay
          ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Color.fromARGB(128, 0, 0, 0),
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
          Positioned.fill(
            top: kToolbarHeight + MediaQuery.of(context).padding.top, // Position below AppBar
            child: DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.12, // Adjusted to accommodate the top bar and prevent overflow
              minChildSize: 0.12,    // Adjusted to accommodate the top bar and prevent overflow
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
                          _sheetController.animateTo(0.12, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
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
                                  _sheetController.animateTo(0.12, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
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
                                    _clearCurrentItemControllers();
                                    _scannerController.start();
                                    _sheetController.animateTo(0.12, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.check, color: Colors.white),
                                  onPressed: () => _saveAllItems(firestoreService),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Pagination Dots
                    if (_scannedItems.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_scannedItems.length, (index) {
                            return Container(
                              width: 8.0,
                              height: 8.0,
                              margin: const EdgeInsets.symmetric(horizontal: 4.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentItemIndex == index ? const Color(0xFF2E7D32) : Colors.grey,
                              ),
                            );
                          }),
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
                                      TextFormField(
                                        controller: _netWeightController,
                                        decoration: InputDecoration(
                                          labelText: 'Net Weight',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        onChanged: (value) => _scannedItems[_currentItemIndex].netWeight = value,
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
                                      // Shelf-life and Dates
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: _useManufacturedAndShelfLife,
                                            onChanged: (bool? newValue) {
                                              setState(() {
                                                _useManufacturedAndShelfLife = newValue!;
                                              });
                                            },
                                            activeColor: const Color(0xFF2E7D32),
                                          ),
                                          const Text('Use Manufactured Date & Shelf-life'),
                                        ],
                                      ),
                                      if (_useManufacturedAndShelfLife) ...[
                                        Row(
                                          children: [
                                            Radio<String>(
                                              value: 'days',
                                              groupValue: _selectedShelfLifeUnit,
                                              onChanged: (String? value) {
                                                setState(() {
                                                  _selectedShelfLifeUnit = value!;
                                                });
                                              },
                                              activeColor: const Color(0xFF2E7D32),
                                            ),
                                            const Text('Shelf-life days'),
                                            Radio<String>(
                                              value: 'weeks',
                                              groupValue: _selectedShelfLifeUnit,
                                              onChanged: (String? value) {
                                                setState(() {
                                                  _selectedShelfLifeUnit = value!;
                                                });
                                              },
                                              activeColor: const Color(0xFF2E7D32),
                                            ),
                                            const Text('Week'),
                                            Radio<String>(
                                              value: 'months',
                                              groupValue: _selectedShelfLifeUnit,
                                              onChanged: (String? value) {
                                                setState(() {
                                                  _selectedShelfLifeUnit = value!;
                                                });
                                              },
                                              activeColor: const Color(0xFF2E7D32),
                                            ),
                                            const Text('Month'),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: InkWell(
                                                onTap: () async {
                                                  DateTime? pickedDate = await showDatePicker(
                                                    context: context,
                                                    initialDate: _manufacturedDate ?? DateTime.now(),
                                                    firstDate: DateTime(2000),
                                                    lastDate: DateTime.now(),
                                                    builder: (context, child) {
                                                      return Theme(
                                                        data: Theme.of(context).copyWith(
                                                          colorScheme: const ColorScheme.light(
                                                            primary: Color(0xFF2E7D32), // Header background color
                                                            onPrimary: Colors.white, // Header text color
                                                            onSurface: Colors.black, // Body text color
                                                          ),
                                                          textButtonTheme: TextButtonThemeData(
                                                            style: TextButton.styleFrom(
                                                              foregroundColor: const Color(0xFF2E7D32), // Button text color
                                                            ),
                                                          ),
                                                        ),
                                                        child: child!,
                                                      );
                                                    },
                                                  );
                                                  if (pickedDate != null) {
                                                    setState(() {
                                                      _manufacturedDate = pickedDate;
                                                      _scannedItems[_currentItemIndex].manufacturedDate = pickedDate;
                                                    });
                                                  }
                                                },
                                                child: InputDecorator(
                                                  decoration: InputDecoration(
                                                    labelText: 'Manufactured Date',
                                                    border: OutlineInputBorder(
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    focusedBorder: OutlineInputBorder(
                                                      borderSide: const BorderSide(color: Color(0xFF2E7D32)),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    suffixIcon: const Icon(Icons.calendar_today),
                                                  ),
                                                  child: Text(
                                                    _manufacturedDate == null
                                                        ? 'Select Date'
                                                        : '${_manufacturedDate!.toLocal()}'.split(' ')[0],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: TextFormField(
                                                controller: _shelfLifeController,
                                                keyboardType: TextInputType.number,
                                                decoration: InputDecoration(
                                                  labelText: 'Shelf-life',
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderSide: const BorderSide(color: Color(0xFF2E7D32)),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                                onChanged: (value) {
                                                  int? shelfLifeValue = int.tryParse(value);
                                                  if (shelfLifeValue != null) {
                                                    setState(() {
                                                      if (_selectedShelfLifeUnit == 'days') {
                                                        _scannedItems[_currentItemIndex].shelfLifeDays = shelfLifeValue;
                                                        _scannedItems[_currentItemIndex].shelfLifeWeeks = null;
                                                        _scannedItems[_currentItemIndex].shelfLifeMonths = null;
                                                      } else if (_selectedShelfLifeUnit == 'weeks') {
                                                        _scannedItems[_currentItemIndex].shelfLifeWeeks = shelfLifeValue;
                                                        _scannedItems[_currentItemIndex].shelfLifeDays = null;
                                                        _scannedItems[_currentItemIndex].shelfLifeMonths = null;
                                                      } else if (_selectedShelfLifeUnit == 'months') {
                                                        _scannedItems[_currentItemIndex].shelfLifeMonths = shelfLifeValue;
                                                        _scannedItems[_currentItemIndex].shelfLifeDays = null;
                                                        _scannedItems[_currentItemIndex].shelfLifeWeeks = null;
                                                      }
                                                    });
                                                  }
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        InkWell(
                                          onTap: () async {
                                            DateTime? pickedDate = await showDatePicker(
                                              context: context,
                                              initialDate: _expirationDate ?? DateTime.now(),
                                              firstDate: DateTime.now(),
                                              lastDate: DateTime(2100),
                                              builder: (context, child) {
                                                return Theme(
                                                  data: Theme.of(context).copyWith(
                                                    colorScheme: const ColorScheme.light(
                                                      primary: Color(0xFF2E7D32), // Header background color
                                                      onPrimary: Colors.white, // Header text color
                                                      onSurface: Colors.black, // Body text color
                                                    ),
                                                    textButtonTheme: TextButtonThemeData(
                                                      style: TextButton.styleFrom(
                                                        foregroundColor: const Color(0xFF2E7D32), // Button text color
                                                      ),
                                                    ),
                                                  ),
                                                  child: child!,
                                                );
                                              },
                                            );
                                            if (pickedDate != null) {
                                              setState(() {
                                                _expirationDate = pickedDate;
                                                _scannedItems[_currentItemIndex].expirationDate = pickedDate;
                                              });
                                            }
                                          },
                                          child: InputDecorator(
                                            decoration: InputDecoration(
                                              labelText: 'Expiration Date',
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: const BorderSide(color: Color(0xFF2E7D32)),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              suffixIcon: const Icon(Icons.calendar_today),
                                            ),
                                            child: Text(
                                              _expirationDate == null
                                                  ? 'Select Date'
                                                  : '${_expirationDate!.toLocal()}'.split(' ')[0],
                                            ),
                                          ),
                                        ),
                                      ],
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
          ), // Closing DraggableScrollableSheet
        ), // Closing Positioned.fill
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
