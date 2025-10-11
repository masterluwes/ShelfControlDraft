import 'package:flutter/material.dart';
import 'package:shelf_control/models/pantry_item_model.dart';
import 'package:intl/intl.dart';
import 'package:shelf_control/screens/editpantryitem.dart';

class PantryItemDetails extends StatefulWidget {
  final PantryItemModel item;

  const PantryItemDetails({super.key, required this.item});

  @override
  State<PantryItemDetails> createState() => _PantryItemDetailsState();
}

class _PantryItemDetailsState extends State<PantryItemDetails> {
  late PantryItemModel item;

  // --- COLORS (from design) ---
  final Color headerGreen = const Color(0xFF2E7D32);
  final Color softCream = const Color(0xFFFAF8ED);
  final Color lightGreenBg = const Color(0xFFE8F5E9);
  final Color fieldBgColor = const Color(0xFFEDEDED);
  final Color labelTextColor = const Color(0xFF666666);
  final Color inputTextColor = const Color(0xFF222222);

  @override
  void initState() {
    super.initState();
    item = widget.item;
  }

  @override
  Widget build(BuildContext context) {
    final daysUntilExpiry =
        item.expirationDate?.difference(DateTime.now()).inDays ?? -999;

    return Scaffold(
      backgroundColor: softCream,
      appBar: AppBar(
        backgroundColor: headerGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white, size: 24),
            onPressed: () async {
              final PantryItemModel? result = await Navigator.push<PantryItemModel>(
                context,
                MaterialPageRoute(
                  builder: (context) => EditPantryItem(item: item),
                ),
              );

              if (result != null) {
                setState(() {
                  item = result;
                });
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pantry Item Details',
                      style: TextStyle(
                          color: headerGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 26)),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 5,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                            ? Image.network(
                                item.imageUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(
                                        child: Icon(Icons.image_not_supported, color: Colors.grey)),
                              )
                            : Center(
                                child: Icon(Icons.camera_alt_outlined, color: Colors.grey.shade400, size: 40),
                              ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(item.name,
                                style: TextStyle(
                                    color: inputTextColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24)),
                            const SizedBox(height: 4),
                            Text('Category: ${item.category}',
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildStatusCard(item.expirationDate),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildLabeledDetailField(
                          label: 'Item Price',
                          value: item.price?.toStringAsFixed(2) ?? 'Not specified',
                          prefixText: '₱ ',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildLabeledDetailField(
                          label: 'Net Weight',
                          value: item.netWeight ?? 'Not specified',
                          icon: Icons.shopping_bag_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildLabeledDetailField(
                          label: 'Added By',
                          value: item.addedBy ?? 'Unknown Member',
                          icon: Icons.person_outline,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildLabeledDetailField(
                          label: 'Added Method',
                          value: item.addedMethod ?? 'Manual Input',
                          icon: Icons.add_circle_outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text('Tips and Information',
                      style: TextStyle(
                          color: headerGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                  const SizedBox(height: 16),
                  _buildTipsTile(
                      icon: Icons.restaurant_menu_outlined,
                      title: 'Meal Plan Suggestions',
                      subtitle:
                          'This section provides meal ideas using ${item.name}.'),
                  _buildTipsTile(
                      icon: Icons.inventory_2_outlined,
                      title: 'Proper Storage',
                      subtitle: 'Learn how to store ${item.name}.'),
                  if (item.nutrition != null && item.nutrition!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildTipsTile(
                      icon: Icons.food_bank_outlined, // Using a generic food icon as nutrition_outlined is not available
                      title: 'Nutrition Information',
                      subtitle: item.nutrition!,
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildLabeledDetailField(
                      label: 'Notes',
                      value: item.notes ?? 'No notes added for item.',
                      isFullWidth: true),
                ],
              ),
            ),
            Image.asset(
              'assets/footer1e27d32-trans.png',
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildStatusCard(DateTime? date) {
    String expiresText = 'No expiry date';
    int daysUntilExpiry = -999;

    if (date != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final expiryDay = DateTime(date.year, date.month, date.day);
      daysUntilExpiry = expiryDay.difference(today).inDays;

      if (daysUntilExpiry < 0) {
        expiresText = 'Expired ${daysUntilExpiry.abs()} days ago';
      } else if (daysUntilExpiry == 0) {
        expiresText = 'Expires today';
      } else if (daysUntilExpiry == 1) {
        expiresText = 'Expires tomorrow';
      } else {
        expiresText = 'Expires in $daysUntilExpiry days';
      }
    }

    Color cardColor = lightGreenBg;
    Color borderColor = headerGreen.withOpacity(0.8);
    Color textColor = headerGreen;
    IconData iconData = Icons.check_circle;

    if (daysUntilExpiry <= 0) {
      cardColor = const Color(0xFFFFEBEE); 
      borderColor = const Color(0xFFFF3030); 
      textColor = const Color(0xFFD32F2F);   
      iconData = Icons.error;
    } else if (daysUntilExpiry <= 7) {
      cardColor = Colors.orange.shade100;
      borderColor = Colors.orange.shade800;
      textColor = Colors.orange.shade900;
      iconData = Icons.warning_amber;
    } else if (daysUntilExpiry <= 14) {
      cardColor = Colors.yellow.shade100;
      borderColor = Colors.yellow.shade800;
      textColor = Colors.yellow.shade900;
      iconData = Icons.warning_amber;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(iconData, color: textColor, size: 24),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory_2_outlined, color: Colors.grey.shade700, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Qty: ${item.qty}',
                  style: TextStyle(
                    color: inputTextColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(expiresText,
                  style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              const SizedBox(height: 2),
              if (date != null)
                Text(DateFormat('MMMM dd, yyyy').format(date),
                    style: TextStyle(color: labelTextColor, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledDetailField(
      {required String label,
      required String value,
      IconData? icon,
      String? prefixText,
      bool isFullWidth = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: headerGreen, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          width: isFullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
              color: fieldBgColor, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.grey.shade700, size: 20),
                const SizedBox(width: 8)
              ],
              if (prefixText != null)
                Text(prefixText,
                    style: TextStyle(
                        color: inputTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
              Expanded(
                child: Text(value,
                    style: TextStyle(color: inputTextColor, fontSize: 15)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipsTile(
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 5)
          ]),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: headerGreen, size: 28),
        title: Text(title,
            style: TextStyle(
                color: inputTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        subtitle: Text(subtitle,
            style: TextStyle(color: labelTextColor, fontSize: 14)),
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            color: Colors.grey.shade500, size: 18),
        onTap: () {},
      ),
    );
  }
}
