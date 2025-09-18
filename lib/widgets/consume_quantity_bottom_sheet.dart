import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:provider/provider.dart';
import 'package:shelf_control/models/pantry_item_model.dart';
import 'package:shelf_control/services/firestore_service.dart';

class ConsumeQuantityBottomSheet extends StatefulWidget {
  final List<PantryItemModel> items;

  const ConsumeQuantityBottomSheet({super.key, required this.items});

  @override
  State<ConsumeQuantityBottomSheet> createState() => _ConsumeQuantityBottomSheetState();
}

class _ConsumeQuantityBottomSheetState extends State<ConsumeQuantityBottomSheet> {
  // Palette to match your UI
  final Color headerGreen = const Color(0xFF2E7D32);
  final Color softCream = const Color(0xFFFFFBE6);
  final Color rowAlt = const Color(0xFFF7EFD3);
  final Color sep = const Color(0xFFE9E1C7);

  // Map to store the quantity to consume for each item
  late Map<String, int> _quantitiesToConsume;

  @override
  void initState() {
    super.initState();
    _quantitiesToConsume = {
      for (var item in widget.items) item.id!: 0, // Initialize with 0 consumed
    };
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: softCream, // Use softCream for the background
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Consume Selected Items',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: headerGreen), // Use headerGreen for title
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.3, // Constrain height to 30% of screen height
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.items.length,
                itemBuilder: (context, index) {
                  final item = widget.items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: headerGreen), // Use headerGreen
                              ),
                              Text('Available: ${item.qty}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        NumberPicker(
                          value: _quantitiesToConsume[item.id]!,
                          minValue: 0,
                          maxValue: item.qty,
                          step: 1,
                          haptics: true,
                          onChanged: (value) {
                            setState(() {
                              _quantitiesToConsume[item.id!] = value;
                            });
                          },
                          axis: Axis.horizontal,
                          itemWidth: 40,
                          itemHeight: 30,
                          textStyle: const TextStyle(fontSize: 14, color: Colors.black54),
                          selectedTextStyle: TextStyle(fontSize: 18, color: headerGreen, fontWeight: FontWeight.bold), // Use headerGreen
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: sep), // Use sep for border
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the bottom sheet
                  },
                  style: TextButton.styleFrom(foregroundColor: headerGreen), // Use headerGreen
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    for (var item in widget.items) {
                      final quantityToConsume = _quantitiesToConsume[item.id!];
                      if (quantityToConsume != null && quantityToConsume > 0) {
                        await firestoreService.recordConsumedItem(item, quantityToConsume);
                      }
                    }
                    Navigator.of(context).pop(); // Close the bottom sheet
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: headerGreen), // Use headerGreen
                  child: const Text('Confirm Consume', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
