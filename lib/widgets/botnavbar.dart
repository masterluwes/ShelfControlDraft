// lib/widgets/botnavbar.dart
import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final Color headerGreen;
  final int currentIndex;
  final ValueChanged<int> onIndexSelected;

  const BottomNavBar({super.key, required this.headerGreen, required this.currentIndex, required this.onIndexSelected});

  @override
  Widget build(BuildContext context) {
    // BEGIN extracted code (unchanged layout/values)
    BottomAppBar(
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
                    isActive: currentIndex == 0,
                    activeIcon: Icons.home_filled,
                    inactiveIcon: Icons.home_outlined,
                    label: 'Home',
                    onTap: () => setState(() => currentIndex = 0),
                  ),
                  _BottomItem(
                    isActive: currentIndex == 1,
                    activeIcon: Icons.kitchen,
                    inactiveIcon: Icons.kitchen_outlined,
                    label: 'Pantry',
                    onTap: () => setState(
                      () => currentIndex == 1 ? currentIndex : currentIndex = 1,
                    ),
                  ),
                  const SizedBox(width: 56), // space for FAB
                  _BottomItem(
                    isActive: currentIndex == 2,
                    activeIcon: Icons.shopping_cart,
                    inactiveIcon: Icons.shopping_cart_outlined,
                    label: 'Shopping List',
                    onTap: () => setState(() => currentIndex = 2),
                  ),
                  _BottomItem(
                    isActive: currentIndex == 3,
                    activeIcon: Icons.lightbulb,
                    inactiveIcon: Icons.lightbulb_outline,
                    label: 'Tips',
                    onTap: () => setState(() => currentIndex = 3),
                  ),
                ],
              ),
            ),
          ),
    // END extracted code
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
