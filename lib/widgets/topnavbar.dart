// lib/widgets/topnavbar.dart
import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:guests_main/pages/notificationguest.dart';
import 'package:guests_main/pages/householdgroupguest.dart';

class TopNavBar extends StatelessWidget implements PreferredSizeWidget {
  final Color headerGreen;
  final Color softCream;
  final String selectedHousehold;
  final List<String> households;
  final bool isNotifActive;
  final bool isGroupActive;
  final ValueChanged<String?> onHouseholdChanged;
  final VoidCallback onOpenMenu;

  const TopNavBar({
    super.key,
    required this.headerGreen,
    required this.softCream,
    required this.selectedHousehold,
    required this.households,
    required this.isNotifActive,
    required this.isGroupActive,
    required this.onHouseholdChanged,
    required this.onOpenMenu,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    // BEGIN extracted code (unchanged layout/values)
    return PreferredSize(
      PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: AppBar(
                elevation: 0,
                backgroundColor: headerGreen,
                centerTitle: false,
                leading: IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () { onOpenMenu();
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
                            setState(() => isNotifActive = true);
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationsPage(),
                              ),
                            );
                            if (mounted) setState(() => isNotifActive = false);
                          },
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 120),
                            transitionBuilder: (child, anim) =>
                                ScaleTransition(scale: anim, child: child),
                            child: Icon(
                              isNotifActive
                                  ? Icons.notifications
                                  : Icons.notifications_none_rounded,
                              key: ValueKey<bool>(isNotifActive),
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),

                        // Groups: momentary filled when tapped, reset after returning
                        IconButton(
                          splashRadius: 22,
                          onPressed: () async {
                            setState(() => isGroupActive = true);
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const Householdgroupguest(),
                              ),
                            );
                            if (mounted) setState(() => isGroupActive = false);
                          },
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 120),
                            transitionBuilder: (child, anim) =>
                                ScaleTransition(scale: anim, child: child),
                            child: Icon(
                              isGroupActive ? Icons.groups : Icons.groups_outlined,
                              key: ValueKey<bool>(isGroupActive),
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
    );
    // END extracted code
  }
}
