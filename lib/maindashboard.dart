import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:guests_main/pages/notificationguest.dart';
import 'package:guests_main/pages/pantryinventory.dart';
import 'package:guests_main/pages/shoppinglist.dart';
import 'package:guests_main/pages/tipsandsuggest.dart';
import 'package:guests_main/pages/householdgroupguest.dart';

void main() => runApp(const ShelfControlApp());

class ShelfControlApp extends StatelessWidget {
  const ShelfControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shelf Control',
      debugShowCheckedModeBanner: false,
      home: const MainDashboard(),
      theme: ThemeData(useMaterial3: false, fontFamily: 'Roboto'),
    );
  }
}

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  final Color headerGreen = const Color(0xFF2E7D32);
  final Color softCream = const Color(0xFFFFFBE6);

  String _selectedHousehold = 'Household 1';
  final List<String> _households = const [
    'Household 1',
    'Household 2',
    'Household 3',
  ];

  int _currentIndex = 0;

  // Momentary fill flags for icons
  bool _isNotifActive = false;
  bool _isGroupActive = false;

  @override
  Widget build(BuildContext context) {
    // Tiles for "Home"
    final tiles = <Widget>[
      const _StatTile(
        icon: Icons.delete_outline,
        label: 'No data available yet!',
      ),
      const _StatTile(icon: Icons.bar_chart, label: 'No data available yet!'),
      const _StatTile(
        icon: Icons.shopping_cart_outlined,
        label: 'No data available yet!',
      ),
      const _StatTile(
        icon: Icons.stacked_bar_chart_rounded,
        label: 'No data available yet!',
      ),
      const _StatTile(icon: Icons.access_time, label: 'No data available yet!'),
      _TipTile(headerGreen: headerGreen),
    ];

    // Per-tab bodies
    final pages = <Widget>[
      _homeBody(context, tiles),
      const Pantryinventory(),
      const Shoppinglist(),
      const Tipsandsuggest(),
    ];

    return Scaffold(
      backgroundColor: softCream,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AppBar(
          elevation: 0,
          backgroundColor: headerGreen,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              // TODO: open a drawer/menu if you add one
            },
          ),
          titleSpacing: 0,
          title: const SizedBox.shrink(),

          // Top-right actions
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Row(
                children: [
                  // Notifications: navigate + momentary filled icon
                  IconButton(
                    splashRadius: 22,
                    onPressed: () async {
                      setState(() => _isNotifActive = true);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsPage(),
                        ),
                      );
                      if (mounted) setState(() => _isNotifActive = false);
                    },
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 120),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        _isNotifActive
                            ? Icons.notifications
                            : Icons.notifications_none_rounded,
                        key: ValueKey<bool>(_isNotifActive),
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Groups: momentary filled when tapped, reset after returning
                  IconButton(
                    splashRadius: 22,
                    onPressed: () async {
                      setState(() => _isGroupActive = true);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const Householdgroupguest(),
                        ),
                      );
                      if (mounted) setState(() => _isGroupActive = false);
                    },
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 120),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        _isGroupActive ? Icons.groups : Icons.groups_outlined,
                        key: ValueKey<bool>(_isGroupActive),
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ],
        ),
      ),

      body: SafeArea(child: pages[_currentIndex]),

      // Center add button
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: RawMaterialButton(
          onPressed: () {},
          elevation: 5,
          fillColor: Colors.white,
          shape: const CircleBorder(),
          constraints: const BoxConstraints.tightFor(width: 80, height: 80),
          child: Icon(Icons.add, size: 36, color: headerGreen),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // Bottom nav bar with notch
      bottomNavigationBar: BottomAppBar(
        color: headerGreen,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        clipBehavior: Clip.hardEdge, // keep splash inside the bar
        child: SizedBox(
          height: 68,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _BottomItem(
                isActive: _currentIndex == 0,
                activeIcon: Icons.home_filled,
                inactiveIcon: Icons.home_outlined,
                label: 'Home',
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _BottomItem(
                isActive: _currentIndex == 1,
                activeIcon: Icons.kitchen,
                inactiveIcon: Icons.kitchen_outlined,
                label: 'Pantry',
                onTap: () => setState(
                  () => _currentIndex == 1 ? _currentIndex : _currentIndex = 1,
                ),
              ),
              const SizedBox(width: 56), // space for FAB
              _BottomItem(
                isActive: _currentIndex == 2,
                activeIcon: Icons.shopping_cart,
                inactiveIcon: Icons.shopping_cart_outlined,
                label: 'Shopping List',
                onTap: () => setState(() => _currentIndex = 2),
              ),
              _BottomItem(
                isActive: _currentIndex == 3,
                activeIcon: Icons.lightbulb,
                inactiveIcon: Icons.lightbulb_outline,
                label: 'Tips',
                onTap: () => setState(() => _currentIndex = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Home body content
  Widget _homeBody(BuildContext context, List<Widget> tiles) {
    final headerGreen = this.headerGreen;

    return LayoutBuilder(
      builder: (context, constraints) {
        const gridCols = 2;
        const gridSpacing = 16.0;
        const titleDropdownHeight = 40.0; // approx height of the row
        const titleBottomGap = 16.0;
        const bottomCardHeight = 140.0;
        const blockSidePadding = EdgeInsets.fromLTRB(16, 12, 16, 12);
        const blockMaxWidth = 900.0;

        final rows = (tiles.length / gridCols).ceil();
        final available = constraints.maxHeight;

        double tileExtentToFit(double targetBlockHeight) {
          final gridHeight =
              targetBlockHeight -
              titleDropdownHeight -
              titleBottomGap -
              bottomCardHeight -
              titleBottomGap;
          final raw = (gridHeight - gridSpacing * (rows - 1)) / rows;
          return raw;
        }

        double tileExtent = 140.0;

        double blockHeight() =>
            titleDropdownHeight +
            titleBottomGap +
            (rows * tileExtent + gridSpacing * (rows - 1)) +
            titleBottomGap +
            bottomCardHeight;

        if (blockHeight() > available) {
          tileExtent = tileExtentToFit(available);
        }

        tileExtent = tileExtent.clamp(110.0, 180.0);

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: blockMaxWidth),
            child: Padding(
              padding: blockSidePadding,
              child: Column(
                mainAxisSize:
                    MainAxisSize.min, // enables true vertical centering
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + dropdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Overview',
                        style: TextStyle(
                          color: headerGreen,
                          fontFamily: 'Inter',
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                      Container(
                        width: 169,
                        margin: const EdgeInsets.only(right: 1),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: headerGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton2<String>(
                            value: _selectedHousehold,
                            items: _households
                                .map(
                                  (h) => DropdownMenuItem<String>(
                                    value: h,
                                    child: Text(
                                      h,
                                      style: const TextStyle(
                                        fontFamily: 'Roboto',
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedHousehold = v);
                              }
                            },
                            dropdownStyleData: DropdownStyleData(
                              width: 170,
                              isOverButton: false,
                              offset: const Offset(-8, -1),
                              decoration: BoxDecoration(
                                color: headerGreen,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            buttonStyleData: const ButtonStyleData(
                              height: 40,
                              width: 169,
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              elevation: 0,
                            ),
                            iconStyleData: const IconStyleData(
                              iconEnabledColor: Colors.white,
                            ),
                            menuItemStyleData: const MenuItemStyleData(
                              height: 40,
                              padding: EdgeInsets.symmetric(horizontal: 18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: titleBottomGap),

                  // Grid
                  SizedBox(
                    height: rows * tileExtent + gridSpacing * (rows - 1),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: tiles.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: gridCols,
                        mainAxisSpacing: gridSpacing,
                        crossAxisSpacing: gridSpacing,
                        mainAxisExtent: tileExtent,
                      ),
                      itemBuilder: (context, index) => tiles[index],
                    ),
                  ),

                  const SizedBox(height: titleBottomGap),

                  // Bottom card
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      minHeight: 120,
                      maxHeight: 150,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Pantry Overview',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 30),
                        Center(
                          child: Text(
                            'No data available yet!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF222222),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 2),
                        Center(
                          child: Text(
                            'Register/Login to access this feature',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF222222),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
  final bool isActive;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final VoidCallback onTap;

  const _BottomItem({
    required this.isActive,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = Colors.white;
    final Color inactiveColor = Colors.white70;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  isActive ? activeIcon : inactiveIcon,
                  key: ValueKey<bool>(isActive),
                  color: isActive ? activeColor : inactiveColor,
                  size: isActive ? 26 : 24,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: TextStyle(
                  color: isActive ? activeColor : inactiveColor,
                  fontSize: isActive ? 12.5 : 11.5,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: isActive ? 0.2 : 0.0,
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
