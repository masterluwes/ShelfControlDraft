// history_screen.dart
import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
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
    return Scaffold(body: Center(child: Text('History content here')));
  }
}
