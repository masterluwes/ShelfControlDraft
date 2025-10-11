import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shelf_control/models/pantry_item_model.dart';
import 'package:shelf_control/screens/addpantryitem.dart';
import 'package:shelf_control/services/firestore_service.dart';

class AddPantryItemWrapper extends StatelessWidget {
  const AddPantryItemWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    void handleAddItem(PantryItemModel item) {
      if (firestoreService.selectedHouseholdId != null) {
        final newItem = item.copyWith(householdId: firestoreService.selectedHouseholdId);
        firestoreService.addPantryItem(newItem);
      }
    }

    void handleBack() {
      Navigator.of(context).pop();
    }

    return AddPantryItem(
      onAddItem: handleAddItem,
      onBack: handleBack,
    );
  }
}