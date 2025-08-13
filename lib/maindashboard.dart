import 'package:flutter/material.dart';

void main() => runApp(const ShelfControlApp());

class ShelfControlApp extends StatelessWidget {
  const ShelfControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shelf Control',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const OverviewPage(),
    );
  }
}

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  final Color green = const Color(0xFF2E7D32);
  final Color bg = const Color(0xFFFFFBE6);
  final Color cardFill = const Color(0xFFFFE6EA); // soft pink
  final Color soft = const Color(0xFFFFF1D6);     // soft peach
  int currentTab = 0;
  String selectedHousehold = 'Household 1';
  final households = const ['Household 1', 'Household 2', 'Household 3'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      extendBody: true, // allows FAB notch overlap
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(96),
        child: _TopBar(
          green: green,
          onMenu: () {},
          onBell: () {},
          onPeople: () {},
        ),
      ),
      body: Stack(
        children: [
          // subtle vertical lighter strip like your mock
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 4,
              color: Colors.white,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overview',
                    style: TextStyle(
                      color: green,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _HouseholdDropdown(
                    green: green,
                    value: selectedHousehold,
                    items: households,
                    onChanged: (v) => setState(() => selectedHousehold = v!),
                  ),
                  const SizedBox(height: 16),
                  _StatsGrid(cardFill: cardFill, green: green),
                  const SizedBox(height: 16),
                  _PantryOverviewCard(soft: soft),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        elevation: 6,
        shape: const CircleBorder(),
        onPressed: () {},
        backgroundColor: Colors.white,
        child: Icon(Icons.add, color: green, size: 32),
      ),
      bottomNavigationBar: _RoundedBottomBar(
        currentIndex: currentTab,
        onTap: (i) => setState(() => currentTab = i),
        green: green,
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.green,
    required this.onMenu,
    required this.onBell,
    required this.onPeople,
  });

  final Color green;
  final VoidCallback onMenu;
  final VoidCallback onBell;
  final VoidCallback onPeople;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: green,
      elevation: 2,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: Row(
            children: [
              _containRipple(
                child: IconButton(
                  onPressed: onMenu,
                  icon: const Icon(Icons.menu, color: Colors.white),
                  tooltip: 'Menu',
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  _containRipple(
                    child: IconButton(
                      onPressed: onBell,
                      icon: const Icon(Icons.notifications_none, color: Colors.white),
                      tooltip: 'Notifications',
                    ),
                  ),
                  _containRipple(
                    child: IconButton(
                      onPressed: onPeople,
                      icon: const Icon(Icons.group, color: Colors.white),
                      tooltip: 'Households',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Keeps the ink ripple strictly inside the button’s rectangular bounds
  /// (prevents it from bleeding outside the green bar).
  static Widget _containRipple({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Material(color: Colors.transparent, child: child),
    );
  }
}

class _HouseholdDropdown extends StatelessWidget {
  const _HouseholdDropdown({
    required this.green,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final Color green;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE1F0E4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: green, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            borderRadius: BorderRadius.circular(12),
            iconEnabledColor: green,
            style: TextStyle(
              color: Colors.green.shade900,
              fontWeight: FontWeight.w600,
            ),
            items: items
                .map((e) => DropdownMenuItem<String>(
                      value: e,
                      child: Text(e),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.cardFill, required this.green});

  final Color cardFill;
  final Color green;

  @override
  Widget build(BuildContext context) {
    final tiles = <_TileData>[
      _TileData(icon: Icons.delete_outline),
      _TileData(icon: Icons.bar_chart_outlined),
      _TileData(icon: Icons.shopping_cart_outlined),
      _TileData(icon: Icons.stacked_bar_chart_outlined),
      _TileData(icon: Icons.av_timer_outlined),
      _TileData(
        icon: Icons.lightbulb_outline,
        extraText:
            'Put new groceries behind older ones — use the old stuff first.',
      ),
    ];

    return GridView.builder(
      itemCount: tiles.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (_, i) => _StatCard(
        fill: cardFill,
        icon: tiles[i].icon,
        extraText: tiles[i].extraText,
      ),
    );
  }
}

class _TileData {
  final IconData icon;
  final String? extraText;
  const _TileData({required this.icon, this.extraText});
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.fill,
    required this.icon,
    this.extraText,
  });

  final Color fill;
  final IconData icon;
  final String? extraText;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 44, color: Colors.black87),
        const SizedBox(height: 10),
        const Text(
          'No data available yet!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (extraText != null) ...[
          const SizedBox(height: 8),
          Text(
            extraText!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 13,
              height: 1.2,
            ),
          ),
        ],
      ],
    );

    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: content,
        ),
      ),
    );
  }
}

class _PantryOverviewCard extends StatelessWidget {
  const _PantryOverviewCard({required this.soft});
  final Color soft;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Pantry Overview',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'No data available yet!\nRegister/Login to access this feature',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundedBottomBar extends StatelessWidget {
  const _RoundedBottomBar({
    required this.currentIndex,
    required this.onTap,
    required this.green,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color green;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      // Keeps ripple strictly inside the bar
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(22),
        topRight: Radius.circular(22),
      ),
      child: BottomAppBar(
        color: green,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BarItem(
              icon: Icons.home_filled,
              label: 'Home',
              selected: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _BarItem(
              icon: Icons.kitchen_outlined,
              label: 'Pantry',
              selected: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            const SizedBox(width: 56), // space for FAB
            _BarItem(
              icon: Icons.list_alt_outlined,
              label: 'Shopping List',
              selected: currentIndex == 2,
              onTap: () => onTap(2),
            ),
            _BarItem(
              icon: Icons.tips_and_updates_outlined,
              label: 'Tips',
              selected: currentIndex == 3,
              onTap: () => onTap(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  const _BarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Colors.white(selected ? 1 : 0.85);

    return Expanded(
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        containedInkWell:
            true, // ensures click animation stays inside the green bar
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}