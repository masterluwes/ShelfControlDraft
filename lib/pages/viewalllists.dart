import 'package:flutter/material.dart';
import 'package:guests_main/pages/listitemspage.dart';

class Viewalllist extends StatefulWidget {
  const Viewalllist({super.key});

  @override
  State<Viewalllist> createState() => _ViewAllListsPageState();
}

class _ViewAllListsPageState extends State<Viewalllist> {
  final Color headerGreen = const Color(0xFF2E7D32);
  final Color softCream = const Color(0xFFFFFBE6);
  final Color sep = const Color.fromARGB(255, 230, 230, 230);

  final _lists = <ListMeta>[
    ListMeta(
      title: 'Weekly Grocery',
      created: DateTime(2025, 8, 28),
      itemsCount: 10,
      icon: Icons.shopping_cart_outlined,
    ),
    ListMeta(
      title: "Sunday's Best",
      created: DateTime(2025, 7, 5),
      itemsCount: 69,
      icon: Icons.storefront_outlined,
    ),
  ];

  String _formatCreated(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  // ===== Common result handler from ListItemsPage =====
  void _handleListPageResult(dynamic result) {
    if (!mounted) return;
    if (result is Map && result['deleted'] == true) {
      final String? title = result['listTitle'] as String?;
      if (title != null) {
        setState(() {
          _lists.removeWhere((m) => m.title == title);
        });
      }
    } else if (result is bool && result == true) {
      // Backward-compat: do nothing.
    }
  }

  // ===== Icon picker =====
  Future<IconData?> _pickIcon(BuildContext context, IconData current) async {
    final choices = <IconData>[
      Icons.list_alt_outlined,
      Icons.shopping_cart_outlined,
      Icons.storefront_outlined,
      Icons.local_mall_outlined,
      Icons.fastfood_outlined,
      Icons.lunch_dining_outlined,
      Icons.local_grocery_store_outlined,
      Icons.kitchen_outlined,
      Icons.inventory_2_outlined,
      Icons.event_note_outlined,
      Icons.receipt_long_outlined,
      Icons.assignment_outlined,
      Icons.food_bank_outlined,
      Icons.set_meal_outlined,
      Icons.ramen_dining_outlined,
    ];

    return showModalBottomSheet<IconData>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: false,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose an icon',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 320,
                  child: GridView.builder(
                    itemCount: choices.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                        ),
                    itemBuilder: (context, i) {
                      final ic = choices[i];
                      final selected =
                          ic.codePoint == current.codePoint &&
                          ic.fontFamily == current.fontFamily;
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.of(sheetCtx).pop(ic),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? headerGreen
                                  : Colors.grey.shade300,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              ic,
                              size: 26,
                              color: selected
                                  ? headerGreen
                                  : Colors.grey.shade800,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===== CREATE LIST pop-up =====
  Future<void> _showCreateListDialog() async {
    final parentContext = context;
    final nameCtrl = TextEditingController();
    IconData chosenIcon = Icons.list_alt_outlined;

    await showDialog<void>(
      context: parentContext,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final enabled = nameCtrl.text.trim().isNotEmpty;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: Text(
                'Create List',
                style: TextStyle(
                  color: headerGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEEEEE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            chosenIcon,
                            size: 30,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final pick = await _pickIcon(dialogCtx, chosenIcon);
                            if (pick != null) setLocal(() => chosenIcon = pick);
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Change Icon'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: headerGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      autofocus: true,
                      onChanged: (_) => setLocal(() {}),
                      decoration: InputDecoration(
                        hintText: 'Enter list name',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: sep),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogCtx, rootNavigator: true).pop(),
                  child: Text('Cancel', style: TextStyle(color: headerGreen)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: enabled
                        ? headerGreen
                        : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: enabled
                      ? () async {
                          final name = nameCtrl.text.trim();
                          if (!mounted) return;

                          final newMeta = ListMeta(
                            title: name,
                            created: DateTime.now(),
                            itemsCount: 0,
                            icon: chosenIcon,
                          );
                          setState(() => _lists.insert(0, newMeta));

                          Navigator.of(dialogCtx, rootNavigator: true).pop();

                          final result = await Navigator.of(parentContext).push(
                            MaterialPageRoute(
                              builder: (_) => ListItemsPage(listTitle: name),
                            ),
                          );

                          if (mounted) _handleListPageResult(result);
                        }
                      : null,
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softCream,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: headerGreen,
            padding: const EdgeInsets.fromLTRB(8, 48, 8, 14),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Your List',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: sep),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              children: [
                ..._lists.asMap().entries.map((entry) {
                  final m = entry.value;
                  return _ListCard(
                    meta: m,
                    createdText: 'Created ${_formatCreated(m.created)}',
                    sep: sep,
                    onTap: () {
                      _openEditListDialog(m);
                    },
                    onChevronTap: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ListItemsPage(listTitle: m.title),
                        ),
                      );
                      _handleListPageResult(result);
                    },
                  );
                }),
                const SizedBox(height: 6),
                _CreateListRow(sep: sep, onTap: _showCreateListDialog),
              ],
            ),
          ),
        ],
      ),
      // NOTE: Floating action button removed (no generator)
    );
  }

  // ===== Edit dialog used when tapping a card =====
  Future<void> _openEditListDialog(ListMeta meta) async {
    final nameCtrl = TextEditingController(text: meta.title);
    IconData tempIcon = meta.icon;

    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: Text(
                'Edit List',
                style: TextStyle(
                  color: headerGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEEEEE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            tempIcon,
                            size: 30,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final pick = await _pickIcon(dialogCtx, tempIcon);
                            if (pick != null) setLocal(() => tempIcon = pick);
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Change Icon'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: headerGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        hintText: 'Enter list name',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: sep),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Date created',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: TextEditingController(
                        text: _formatCreated(meta.created),
                      ),
                      readOnly: true,
                      enabled: false,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: sep),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Total items in pantry list',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: sep),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${meta.itemsCount} Items',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(dialogCtx, rootNavigator: true).pop(),
                  child: Text('Cancel', style: TextStyle(color: headerGreen)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: headerGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final newName = nameCtrl.text.trim();
                    setState(() {
                      if (newName.isNotEmpty) meta.title = newName;
                      meta.icon = tempIcon;
                    });
                    Navigator.of(dialogCtx, rootNavigator: true).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ===== Model =====
class ListMeta {
  String title;
  final DateTime created;
  int itemsCount;
  IconData icon;
  ListMeta({
    required this.title,
    required this.created,
    required this.itemsCount,
    required this.icon,
  });
}

// ===== Card widgets =====
class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.meta,
    required this.createdText,
    required this.sep,
    required this.onTap,
    required this.onChevronTap,
  });

  final ListMeta meta;
  final String createdText;
  final Color sep;
  final VoidCallback onTap;
  final VoidCallback onChevronTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: sep),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(meta.icon, size: 26, color: Colors.grey.shade800),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meta.title,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        createdText,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade700,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${meta.itemsCount} Items',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: onChevronTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateListRow extends StatelessWidget {
  const _CreateListRow({required this.sep, required this.onTap});

  final Color sep;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: sep, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline_rounded),
                SizedBox(width: 10),
                Text(
                  'Create List',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
