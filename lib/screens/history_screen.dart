import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shelf_control/models/shopping_history_item_model.dart'; // Use new history model
import 'package:shelf_control/services/firestore_service.dart';
import 'package:intl/intl.dart'; // For date formatting

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Clean up old history items when the screen is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      if (firestoreService.selectedHouseholdId != null) {
        firestoreService.cleanUpShoppingHistoryItems(firestoreService.selectedHouseholdId!);
      }
    });
  }

  Future<void> _confirmClearHistory(BuildContext context, FirestoreService firestoreService) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear History'),
          content: const Text('Are you sure you want to permanently delete all consumed and deleted items from your history? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete All', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true && firestoreService.selectedHouseholdId != null) {
      await firestoreService.deleteAllShoppingHistoryItems(firestoreService.selectedHouseholdId!);
      if (!mounted) return;
      // No snackbar, just let the stream rebuild the UI
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBE6), // App theme background color
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32), // App theme app bar color
        title: const Text(
          'History',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.white),
            onPressed: () => _confirmClearHistory(context, firestoreService),
          ),
        ],
      ),
      body: firestoreService.selectedHouseholdId == null
          ? const Center(child: Text('Please select a household to view history.'))
          : StreamBuilder<List<ShoppingHistoryItemModel>>(
              stream: firestoreService.getShoppingHistoryForHousehold(firestoreService.selectedHouseholdId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final historyItems = snapshot.data ?? [];

                if (historyItems.isEmpty) {
                  return const Center(child: Text('No history items found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: historyItems.length,
                  itemBuilder: (context, index) {
                    final item = historyItems[index];
                    final formattedDate = DateFormat('MMM d, yyyy h:mm a').format(item.purchaseDate);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      color: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32), // App theme color
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Quantity: ${item.quantity}',
                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Purchased on: $formattedDate',
                              style: const TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                            if (item.category != null && item.category!.isNotEmpty)
                              Text(
                                'Category: ${item.category}',
                                style: const TextStyle(fontSize: 14, color: Colors.black54),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              'Action: ${item.actionType}', // Display action type
                              style: TextStyle(
                                fontSize: 14,
                                color: item.actionType == 'Deleted' ? Colors.red : Colors.green, // Color based on action
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
