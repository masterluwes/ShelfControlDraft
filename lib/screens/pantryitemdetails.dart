import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PantryItemModel {
  final String id;
  final String name;
  final String brand;
  final String category;
  final String imageUrl;
  final int qty;
  final DateTime expirationDate;
  final double price;
  final String netWeight;
  final String netWeightUnit;
  final String notes;

  PantryItemModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.imageUrl,
    required this.qty,
    required this.expirationDate,
    this.price = 0.0,
    this.netWeight = '0.0',
    this.netWeightUnit = 'lbs',
    this.notes = '',
  });
}

class PantryItemDetails extends StatefulWidget {
  final PantryItemModel item;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  const PantryItemDetails({
    super.key,
    required this.item,
    required this.onBack,
    required this.onEdit,
  });

  @override
  State<PantryItemDetails> createState() => _PantryItemDetailsState();
}

class _PantryItemDetailsState extends State<PantryItemDetails> {
  // --- UI Colors from Design (Copied from addpantryitem.dart) ---
  final Color headerGreen = const Color(0xFF2E7D32);
  final Color softCream = const Color(0xFFFAF8ED);
  final Color inputFillColor = const Color(0xFFFDFDFC);
  final Color labelTextColor = const Color(0xFF666666);
  final Color inputTextColor = const Color(0xFF222222);
  final Color statusCardGreen = const Color(0xFF4CAF50); // A slightly lighter green for the card

  late int _currentQuantity;

  @override
  void initState() {
    super.initState();
    _currentQuantity = widget.item.qty;
  }

  // Helper to calculate days until expiration
  String _getExpirationStatus(DateTime date) {
    final today = DateTime.now();
    final difference = date.difference(today).inDays;

    if (difference < 0) {
      return 'Expired ${difference.abs()} days ago';
    } else if (difference == 0) {
      return 'Expires today';
    } else {
      return 'Expires in $difference days';
    }
  }

  // Shared text field style wrapper, adapted for read-only display
  Widget _detailField({
    required String labelText,
    required String value,
    String? prefixText,
    String hintText = 'Not specified',
    Widget? prefixIcon,
  }) {
    // Determine the border color based on whether a real value is provided
    final hasValue = value.isNotEmpty && value != '0.00' && value != '0.0' && value != 'Not specified';
    final borderColor = hasValue ? headerGreen : Colors.grey.shade400;

    return InputDecorator(
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
        hintStyle: TextStyle(
          color: hasValue ? inputTextColor : Colors.grey.shade600,
          fontWeight: hasValue ? FontWeight.normal : FontWeight.w500,
        ),
        filled: true,
        fillColor: inputFillColor,
        prefixIcon: prefixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
      ),
      // Display the value directly inside the InputDecorator
      child: Text(
        value,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16,
          color: inputTextColor,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  // Status card widget (the green box)
  Widget _buildStatusCard() {
    final statusText = _getExpirationStatus(widget.item.expirationDate);
    final formattedDate = DateFormat('MMMM d, yyyy').format(widget.item.expirationDate);
    
    // Check if the item is expired or near expiration (e.g., < 7 days) to change color if needed
    final bool isNearExpiry = widget.item.expirationDate.difference(DateTime.now()).inDays < 7;
    final Color cardColor = isNearExpiry ? const Color.fromARGB(255, 255, 230, 192) : statusCardGreen;
    final Color textColor = isNearExpiry ? inputTextColor : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side: Status and Date
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle_outline, color: textColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                formattedDate,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          
          // Right side: Quantity control (read-only for details page)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3), // Light background for controls
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // Decrement button
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.remove, color: textColor),
                  onPressed: () {
                    // Update quantity state on press (simulating interaction)
                    if (_currentQuantity > 0) {
                      setState(() => _currentQuantity--);
                    }
                  },
                ),
                const SizedBox(width: 10),
                Text(
                  '$_currentQuantity',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 10),
                // Increment button
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.add, color: textColor),
                  onPressed: () {
                    // Update quantity state on press (simulating interaction)
                    setState(() => _currentQuantity++);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Interactive list tile for tips/suggestions
  Widget _buildTipsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: inputFillColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: iconColor, size: 30),
        title: Text(
          title,
          style: TextStyle(
            color: headerGreen,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: labelTextColor,
            fontSize: 14,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          color: Colors.grey.shade600,
          size: 18,
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Example values for Price and Net Weight formatting
    final formattedPrice = widget.item.price > 0.0 
        ? NumberFormat.currency(locale: 'en_PH', symbol: '₱').format(widget.item.price)
        : '0.00';
    
    final netWeightValue = widget.item.netWeight != '0.0' && widget.item.netWeight.isNotEmpty
        ? '${widget.item.netWeight} ${widget.item.netWeightUnit}'
        : '';
    
    final notesText = widget.item.notes.isNotEmpty 
        ? widget.item.notes 
        : 'No notes added for item.';

    return Scaffold(
      backgroundColor: softCream,
      appBar: AppBar(
        backgroundColor: headerGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: widget.onBack,
        ),
        title: Text(
          'Pantry Item Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white, size: 24),
            onPressed: widget.onEdit,
          ),
          const SizedBox(width: 8), // Padding on the right
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              // Placeholder for your footer image asset
              'assets/footer1e27d32-trans.png',
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Header (Image, Name, Brand, Category)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                              Center(child: Icon(Icons.image_not_supported, color: Colors.grey.shade400)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.name,
                            style: TextStyle(
                              color: inputTextColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                          Text(
                            widget.item.brand,
                            style: TextStyle(
                              color: labelTextColor,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Category: ${widget.item.category}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Status Card (Expiration and Quantity)
                _buildStatusCard(),
                const SizedBox(height: 24),

                // Price and Net Weight
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _detailField(
                        labelText: 'Item Price',
                        value: formattedPrice,
                        prefixIcon: Icon(Icons.money, color: headerGreen),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _detailField(
                        labelText: 'Net Weight',
                        value: netWeightValue,
                        prefixIcon: Icon(Icons.shopping_bag_outlined, color: headerGreen),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Tips and Information Header
                Text(
                  'Tips and Information',
                  style: TextStyle(
                    color: headerGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 16),

                // Meal Plan Suggestions Tile
                _buildTipsTile(
                  icon: Icons.restaurant,
                  title: 'Meal Plan Suggestions',
                  subtitle: 'This section provides meal ideas using ${widget.item.name}.',
                  iconColor: Colors.orange.shade600,
                  onTap: () {
                    // Handle navigation to Meal Plan Suggestions
                  },
                ),

                // Proper Storage Tile
                _buildTipsTile(
                  icon: Icons.storage,
                  title: 'Proper Storage',
                  subtitle: 'Learn how to store ${widget.item.name}.',
                  iconColor: Colors.blue.shade600,
                  onTap: () {
                    // Handle navigation to Proper Storage tips
                  },
                ),
                const SizedBox(height: 16),

                // Notes Header
                Text(
                  'Notes',
                  style: TextStyle(
                    color: headerGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 16),

                // Notes Field
                _detailField(
                  labelText: 'Notes',
                  value: notesText,
                  hintText: 'No notes added for item.',
                  prefixText: '', // Clear prefix for single line
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}