import 'package:flutter/material.dart';
import 'package:shelf_control/screens/privacy_policy_screen.dart';
import 'package:shelf_control/screens/meal_planner_page.dart';
import 'package:shelf_control/screens/terms_and_conditions_screen.dart';
import 'package:shelf_control/screens/notification_settings_page.dart';
import 'package:shelf_control/screens/profile_page.dart';
import 'package:shelf_control/screens/tips_page.dart';
import 'package:shelf_control/screens/user_guide_page.dart';
import 'package:shelf_control/screens/notification_page.dart';
import 'package:shelf_control/services/auth_service.dart';
import 'package:shelf_control/screens/welcome_page.dart';
import 'package:shelf_control/screens/pantryinventory.dart'; // Import for Pantryinventory
import 'package:shelf_control/models/pantry_item_model.dart'; // Import for PantryItemModel
import 'package:shelf_control/screens/addpantryitem.dart';
import 'package:shelf_control/screens/household_page.dart';
import 'package:shelf_control/screens/shoppinglist.dart'; // Import for ShoppingListPage
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shelf_control/screens/scan_item_screen.dart'; // Import for ScanItemScreen
import 'package:shelf_control/services/firestore_service.dart'; // Import FirestoreService
import 'package:shelf_control/models/household_model.dart'; // Import Household model
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:collection/collection.dart'; // Import for firstWhereOrNull
import 'package:provider/provider.dart'; // Import provider

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Widget? _currentBodyWidget;
  bool _isOnNotificationPage = false;
  Widget? _lastPageBeforeNotifications;
  bool _hasUnreadNotifications = false;
  bool _isSnoozed = false;

  @override
  void initState() {
    super.initState();
    _currentBodyWidget = const DashboardHome();
    _listenForNotifications();
  }

  void _listenForNotifications() {
    // This is a placeholder for future notification backend integration.
  }

  void _showPage(Widget page) {
    setState(() {
      _currentBodyWidget = page;
    });
  }

  void _showPantryInventory(FirestoreService firestoreService) {
    _showPage(const Pantryinventory());
  }

  void _showAddPantryItem(FirestoreService firestoreService) {
    _showPage(const AddPantryItem());
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(
      context,
    ); // Get the FirestoreService instance

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBE6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.brunch_dining, color: Colors.white),
            tooltip: 'Meal Planner',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MealPlannerPage()),
              );
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () {
                  setState(() {
                    if (_isOnNotificationPage) {
                      _currentBodyWidget = _lastPageBeforeNotifications;
                      _isOnNotificationPage = false;
                    } else {
                      _lastPageBeforeNotifications = _currentBodyWidget;
                      _currentBodyWidget = NotificationPage(
                        onStatusChanged: (hasUnread, isSnoozed) {
                          setState(() {
                            _hasUnreadNotifications = hasUnread;
                            _isSnoozed = isSnoozed;
                          });
                        },
                      );
                      _isOnNotificationPage = true;
                      _hasUnreadNotifications = false;
                    }
                  });
                },
              ),
              if (_hasUnreadNotifications && !_isSnoozed)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.group, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HouseholdPage()),
              );
            },
          ),
        ],
      ),
      drawer: _buildSidePanel(context),
      body: _currentBodyWidget,
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF2E7D32),
        shape: const CircularNotchedRectangle(),
        notchMargin: 10.0,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navBarItem(
                Icons.home,
                Icons.home_outlined,
                "Home",
                () => _showPage(const DashboardHome()),
              ),
              _navBarItem(
                Icons.kitchen,
                Icons.kitchen_outlined,
                "Pantry",
                () => _showPantryInventory(firestoreService),
              ),
              const SizedBox(width: 49),
              _navBarItem(
                Icons.shopping_cart,
                Icons.shopping_cart_outlined,
                "Shopping",
                () => _showPage(const Shoppinglist()),
              ),
              _navBarItem(
                Icons.lightbulb,
                Icons.lightbulb_outline,
                "Tips",
                () => _showPage(const TipsPage()),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2E7D32),
        activeBackgroundColor: const Color(0xFF2E7D32),
        activeForegroundColor: Colors.white,
        buttonSize: const Size(85, 85),
        visible: true,
        closeManually: false,
        renderOverlay: false,
        curve: Curves.bounceIn,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        onOpen: () => debugPrint('OPENING DIAL'),
        onClose: () => debugPrint('DIAL CLOSED'),
        elevation: 8.0,
        shape: const CircleBorder(),
        children: [
          SpeedDialChild(
            child: const Icon(Icons.camera_alt, color: Color(0xFF2E7D32)),
            backgroundColor: Colors.white,
            label: 'Add by Camera',
            labelStyle: const TextStyle(fontSize: 18.0, color: Colors.black),
            onTap: () async {
              debugPrint('Add by Camera tapped! Navigating to ScanItemScreen.');
              final List<PantryItemModel>? scannedItems = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScanItemScreen()),
              );
              if (scannedItems != null && scannedItems.isNotEmpty) {
                // No longer adding to _pantryItems directly, as DashboardHome fetches its own data
                _showPantryInventory(
                  firestoreService,
                ); // Refresh pantry inventory to show new items
              }
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.edit, color: Color(0xFF2E7D32)),
            backgroundColor: Colors.white,
            label: 'Add Manually',
            labelStyle: const TextStyle(fontSize: 18.0, color: Colors.black),
            onTap: () => _showAddPantryItem(firestoreService),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _navBarItem(
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
    VoidCallback onTap,
  ) {
    final isActive =
        (_currentBodyWidget is DashboardHome && label == "Home") ||
        (_currentBodyWidget is Pantryinventory && label == "Pantry") ||
        (_currentBodyWidget is Shoppinglist && label == "Shopping") ||
        (_currentBodyWidget is TipsPage && label == "Tips");
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isActive ? activeIcon : inactiveIcon,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSidePanel(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF2E7D32),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          children: [
            const Text(
              "ShelfControl",
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            _drawerItem(Icons.person, "Profile", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            }),
            _drawerItem(Icons.notifications, "Notification Settings", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsPage(),
                ),
              );
            }),
            _drawerItem(Icons.delete, "Waste Tracker", () {}),
            _drawerItem(Icons.info, "User Guide", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserGuidePage()),
              );
            }),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Icons.feedback, color: Colors.white),
                  title: const Text(
                    "Feedback",
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    "We would love to hear from you.",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      minimumSize: const Size(double.infinity, 36),
                    ),
                    child: const Text(
                      "Email Us",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
            _drawerItem(Icons.description, "Terms and Conditions", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TermsAndConditionsScreen(),
                ),
              );
            }),
            _drawerItem(Icons.privacy_tip, "Privacy Policy", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            }),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                await AuthService().signOut();
                if (!mounted) return;
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const WelcomePage()),
                  (Route<dynamic> route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: const StadiumBorder(),
              ),
              child: const Text(
                "Log Out",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(
      context,
    ); // Get the FirestoreService instance

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  "Overview",
                  style: TextStyle(
                    fontSize: 24, // Reduced font size
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                  overflow: TextOverflow.ellipsis, // Add ellipsis for long text
                ),
              ),
              const SizedBox(
                width: 10,
              ), // Add some spacing between the text and dropdown
              Flexible(
                fit: FlexFit.tight,
                child: StreamBuilder<List<Household>>(
                  stream: firestoreService.getHouseholds(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    final households = snapshot.data ?? [];

                    if (households.isEmpty) {
                      return const Text('No Households');
                    }

                    // Sort households to put personal household first
                    households.sort((a, b) {
                      if (a.isPersonal) return -1;
                      if (b.isPersonal) return 1;
                      return a.name.compareTo(b.name);
                    });

                    // Find the currently selected household
                    Household? selectedHousehold = households.firstWhereOrNull(
                      (h) => h.id == firestoreService.selectedHouseholdId,
                    );

                    // If no household is selected, or the selected one is no longer valid,
                    // default to the personal household or the first available.
                    if (selectedHousehold == null && households.isNotEmpty) {
                      selectedHousehold = households.firstWhere(
                        (h) => h.isPersonal,
                        orElse: () => households.first,
                      );
                      firestoreService.selectedHouseholdId =
                          selectedHousehold.id;
                    }

                    return Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: DropdownButton<String>(
                        value: selectedHousehold?.id,
                        items: households
                            .map(
                              (h) => DropdownMenuItem(
                                value: h.id,
                                child: Text(
                                  h.isPersonal
                                      ? "${h.name} (Personal)"
                                      : h.name,
                                  overflow: TextOverflow
                                      .ellipsis, // Add ellipsis for long names
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            firestoreService.selectedHouseholdId = value;
                          }
                        },
                        dropdownColor: const Color(0xFF2E7D32),
                        underline: Container(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        iconEnabledColor: Colors.white,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildEmptyCard(icon: Icons.delete),
                    _buildEmptyCard(icon: Icons.bar_chart),
                    _buildEmptyCard(icon: Icons.shopping_cart),
                    _buildEmptyCard(icon: Icons.insights),
                    _buildEmptyCard(icon: Icons.access_alarm),
                    _buildTipCard(
                      icon: Icons.lightbulb_outline,
                      tipText:
                          "Put new groceries behind older ones – use the old stuff first.",
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<PantryItemModel>>(
                  stream: firestoreService.selectedHouseholdId == null
                      ? Stream.value([])
                      : firestoreService.getPantryItemsForHousehold(
                          firestoreService.selectedHouseholdId!,
                        ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    final items = snapshot.data ?? [];
                    return _buildPantryOverview(items);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildEmptyCard({required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Colors.black87),
            const SizedBox(height: 8),
            const Text(
              "No data available yet!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildTipCard({
    required IconData icon,
    required String tipText,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28, color: Colors.black87),
          const SizedBox(height: 8),
          Text(
            tipText,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  static Widget _buildPantryOverview(List<PantryItemModel> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Pantry Overview",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text(
              "No data available yet! - Start by clicking the + icon",
              style: TextStyle(fontSize: 12),
            )
          else
            Text(
              "Total items: ${items.length}",
              style: const TextStyle(fontSize: 12),
            ),
        ],
      ),
    );
  }
}
