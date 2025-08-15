import 'package:flutter/material.dart';

void main() => runApp(const ShelfControlApp());

class ShelfControlApp extends StatelessWidget {
  const ShelfControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shelf Control',
      debugShowCheckedModeBanner: false,
      home: const OverviewScreen(),
      theme: ThemeData(useMaterial3: false, fontFamily: 'Roboto'),
    );
  }
}

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  final Color headerGreen = const Color(0xFF2E7D32);
  final Color softCream = const Color(0xFFFFFBE6);

  String _selectedHousehold = 'Household 1';
  final List<String> _households = [
    'Household 1',
    'Household 2',
    'Household 3',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softCream,
      // Top green header bar with hamburger + icons (no actions wired)
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AppBar(
          elevation: 0,
          backgroundColor: headerGreen,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {},
          ),
          titleSpacing: 0,
          title: const SizedBox.shrink(),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Row(
                children: [
                  Icon(Icons.notifications_none_rounded, color: Colors.white),
                  SizedBox(width: 16),
                  Icon(Icons.groups, color: Colors.white),
                  SizedBox(width: 8),
                ],
              ),
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "Overview" title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Overview',
                    style: TextStyle(
                      color: headerGreen,
                      fontFamily: 'Inter',
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: headerGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedHousehold,
                        iconEnabledColor: Colors.white,
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: Color(0xFFFF0000)),
                        items: _households
                            .map(
                              (h) => DropdownMenuItem<String>(
                                value: h,
                                child: Text(
                                  h,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _selectedHousehold = v);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Grid of 6 tiles
              GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.12,
                children: [
                  _StatTile(
                    icon: Icons.delete_outline,
                    label: 'No data available yet!',
                  ),
                  _StatTile(
                    icon: Icons.bar_chart,
                    label: 'No data available yet!',
                  ),
                  _StatTile(
                    icon: Icons.shopping_cart_outlined,
                    label: 'No data available yet!',
                  ),
                  _StatTile(
                    icon: Icons.stacked_bar_chart_rounded,
                    label: 'No data available yet!',
                  ),
                  _StatTile(
                    icon: Icons.access_time,
                    label: 'No data available yet!',
                  ),
                  _TipTile(headerGreen: headerGreen),
                ],
              ),

              const SizedBox(height: 16),

              // Pantry Overview card with login note
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pantry Overview',
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'No data available yet!',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Register/Login to access this feature',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Center add button
      floatingActionButton: RawMaterialButton(
        onPressed: () {},
        elevation: 4,
        fillColor: Colors.white,
        shape: const CircleBorder(),
        constraints: const BoxConstraints.tightFor(
          width: 70, // circle width
          height: 70, // circle height
        ),
        child: Icon(Icons.add, size: 36, color: headerGreen),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Bottom nav bar (green) with notch
      bottomNavigationBar: BottomAppBar(
        color: headerGreen,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        child: SizedBox(
          height: 68,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _BottomItem(icon: Icons.home, label: 'Home'),
              _BottomItem(icon: Icons.kitchen_outlined, label: 'Pantry'),
              const SizedBox(width: 56), // space for FAB
              _BottomItem(
                icon: Icons.shopping_cart_outlined,
                label: 'Shopping List',
              ),
              _BottomItem(icon: Icons.lightbulb_outline, label: 'Tips'),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 44, color: Colors.black87),
            const SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipTile extends StatelessWidget {
  final Color headerGreen;
  const _TipTile({required this.headerGreen});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.lightbulb_outline, size: 44, color: Colors.black87),
          const SizedBox(height: 10),
          Text(
            'Put new groceries behind\nolder ones — use the old\nstuff first.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade900,
              fontSize: 13.5,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BottomItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
