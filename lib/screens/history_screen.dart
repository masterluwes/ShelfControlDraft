import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shelf_control/services/firestore_service.dart';
import 'package:shelf_control/models/shopping_history_item_model.dart';
import 'package:intl/intl.dart';

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
      // UI will rebuild automatically from the stream
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final householdId = firestoreService.selectedHouseholdId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: const Color(0xFF2E7D32),
        actions: [
          if (householdId != null)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear All History',
              onPressed: () => _confirmClearHistory(context, firestoreService),
            ),
        ],
      ),
      body: householdId == null
          ? const Center(child: Text('Please select a household to see the history.'))
          : StreamBuilder<List<ShoppingHistoryItemModel>>(
              stream: firestoreService.getShoppingHistoryForHousehold(householdId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final historyItems = snapshot.data ?? [];
                if (historyItems.isEmpty) {
                  return const Center(
                    child: Text(
                      'No history yet.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: historyItems.length,
                  itemBuilder: (context, index) {
                    final item = historyItems[index];
                    final icon = item.actionType == 'Consumed'
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.remove_circle, color: Colors.red);
                    final date = DateFormat('MMM d, yyyy - hh:mm a').format(item.purchaseDate);

                    return ListTile(
                      leading: icon,
                      title: Text(item.productName),
                      subtitle: Text('Quantity: ${item.quantity} - $date'),
                      trailing: Text(
                        item.actionType.toUpperCase(),
                        style: TextStyle(
                          color: item.actionType == 'Consumed' ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
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
