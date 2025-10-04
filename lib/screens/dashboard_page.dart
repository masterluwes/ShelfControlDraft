import 'package:flutter/material.dart';
import 'package:shelf_control/screens/privacy_policy_screen.dart';
import 'package:shelf_control/screens/terms_and_conditions_screen.dart';
import 'package:shelf_control/screens/notification_settings_page.dart';
import 'package:shelf_control/screens/profile_page.dart';
import 'package:shelf_control/screens/tips_page.dart';
import 'package:shelf_control/screens/user_guide_page.dart';
import 'package:shelf_control/screens/notification_page.dart';
import 'package:shelf_control/services/auth_service.dart';
import 'package:shelf_control/screens/welcome_page.dart';
import 'package:shelf_control/screens/feedback.dart'; // Import FeedbackPage
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:shelf_control/screens/pantryinventory.dart'; // Import for Pantryinventory
import 'package:shelf_control/models/pantry_item_model.dart'; // Import for PantryItemModel
import 'package:shelf_control/screens/addpantryitem.dart';
import 'package:shelf_control/screens/household_page.dart';
import 'package:shelf_control/screens/shoppinglist.dart'; // Import for ShoppingListPage
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shelf_control/screens/scan_item_screen.dart'; // Import for ScanItemScreen
import 'package:shelf_control/screens/history_screen.dart'; // Import for HistoryScreen
import 'package:shelf_control/services/firestore_service.dart'; // Import FirestoreService
import 'package:shelf_control/models/household_model.dart'; // Import Household model
import 'package:collection/collection.dart'; // Import for firstWhereOrNull
import 'package:provider/provider.dart'; // Import provider
import 'package:shelf_control/screens/waste_tracker_page.dart';
import 'package:shelf_control/screens/create_account_page.dart'; // Import CreateAccountPage
import 'package:shelf_control/screens/welcome_page.dart'; // Import WelcomePage for guest exit

class DashboardPage extends StatefulWidget {
  final int initialIndex;
  final bool isGuest; // New parameter to indicate guest mode
  const DashboardPage({super.key, this.initialIndex = 0, this.isGuest = false});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  Widget? _currentBodyWidget;
  int _unreadNotificationsCount = 0; // Changed to int
  bool _isSnoozed = false;

  late FirestoreService _firestoreService;
  late User? _currentUser;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _updateBodyWidget(_selectedIndex);
    if (!widget.isGuest) {
      _firestoreService = Provider.of<FirestoreService>(context, listen: false);
      _currentUser = FirebaseAuth.instance.currentUser;
      _listenForNotifications();
    }
  }

  void _updateBodyWidget(int index) {
    setState(() {
      _selectedIndex = index;
      switch (index) {
        case 0:
          _currentBodyWidget = DashboardHome(isGuest: widget.isGuest);
          break;
        case 1:
          _currentBodyWidget = Pantryinventory(isGuest: widget.isGuest);
          break;
        case 2:
          _currentBodyWidget = Shoppinglist(isGuest: widget.isGuest);
          break;
        case 3:
          _currentBodyWidget = const TipsPage();
          break;
        case 4: // New index for NotificationPage
          _currentBodyWidget = NotificationPage(
            onStatusChanged: (unreadCount, isSnoozed) {
              setState(() {
                _unreadNotificationsCount = unreadCount;
                _isSnoozed = isSnoozed;
              });
            },
          );
          break;
        default:
          _currentBodyWidget = DashboardHome(isGuest: widget.isGuest);
      }
    });
  }

  void _listenForNotifications() {
    if (_currentUser == null) return;
    _firestoreService.getUnreadNotificationsCountStream(_currentUser!.uid).listen((count) {
      if (mounted) {
        setState(() {
          _unreadNotificationsCount = count;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text(
          widget.isGuest ? "Guest Mode" : "ShelfControl",
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (widget.isGuest)
            IconButton(
              icon: const Icon(Icons.person_add, color: Colors.white),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateAccountPage()),
                );
              },
            )
          else ...[
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  onPressed: () {
                    _updateBodyWidget(4); // Switch to NotificationPage
                  },
                ),
                if (_unreadNotificationsCount > 0 && !_isSnoozed) // Use count > 0
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
                0,
              ),
              _navBarItem(
                Icons.kitchen,
                Icons.kitchen_outlined,
                "Pantry",
                1,
              ),
              const SizedBox(width: 49),
              _navBarItem(
                Icons.shopping_cart,
                Icons.shopping_cart_outlined,
                "Shopping",
                2,
              ),
              _navBarItem(
                Icons.lightbulb,
                Icons.lightbulb_outline,
                "Tips",
                3,
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
              if (!mounted) return;
              debugPrint('Add by Camera tapped! Navigating to ScanItemScreen.');
              final List<PantryItemModel>? scannedItems = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScanItemScreen()),
              );
              if (scannedItems != null && scannedItems.isNotEmpty) {
                if (!mounted) return;
                final firestoreService = Provider.of<FirestoreService>(context, listen: false);
                if (widget.isGuest) {
                  List<PantryItemModel> currentGuestPantry = await firestoreService.loadGuestPantryItems();
                  currentGuestPantry.addAll(scannedItems);
                  await firestoreService.saveGuestPantryItems(currentGuestPantry);
                } else {
                  // For registered user, add to current household
                  for (var item in scannedItems) {
                    await firestoreService.addPantryItem(item);
                  }
                }
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => DashboardPage(initialIndex: 1, isGuest: widget.isGuest)),
                  (Route<dynamic> route) => false,
                );
              }
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.edit, color: Color(0xFF2E7D32)),
            backgroundColor: Colors.white,
            label: 'Add Manually',
            labelStyle: const TextStyle(fontSize: 18.0, color: Colors.black),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddPantryItem(isGuest: widget.isGuest)),
              );
            },
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
    int index,
  ) {
    final isActive = _selectedIndex == index;
    return InkWell(
      onTap: () => _updateBodyWidget(index),
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
            Text(
              widget.isGuest ? "Guest Mode" : "ShelfControl",
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            if (!widget.isGuest) ...[
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
              _drawerItem(Icons.history, "History", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryScreen()),
                );
              }),
              _drawerItem(Icons.delete, "Waste Tracker", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WasteTrackerPage(),
                  ),
                );
              }),
            ] else ...[
              _drawerItem(Icons.person_add, "Create Account", () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateAccountPage()),
                );
              }),
            ],
            _drawerItem(Icons.info, "User Guide", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserGuidePage()),
              );
            }),
            _drawerItem(Icons.feedback, "Feedback", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FeedbackPage()),
              );
            }),
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
                if (widget.isGuest) {
                  final firestoreService = Provider.of<FirestoreService>(context, listen: false);
                  await firestoreService.clearGuestData(); // Clear guest data on exit
                  if (!mounted) return;
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const WelcomePage()),
                    (Route<dynamic> route) => false,
                  );
                } else {
                  await AuthService().signOut();
                  if (!mounted) return;
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const WelcomePage()),
                    (Route<dynamic> route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: const StadiumBorder(),
              ),
              child: Text(
                widget.isGuest ? "Exit Guest Mode" : "Log Out",
                style: const TextStyle(color: Colors.white),
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
  final bool isGuest;
  const DashboardHome({super.key, this.isGuest = false});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.isGuest ? "Guest Overview" : "Overview",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              if (widget.isGuest)
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Text(
                      "Local Pantry",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                )
              else
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

                      households.sort((a, b) {
                        if (a.isPersonal) return -1;
                        if (b.isPersonal) return 1;
                        return a.name.compareTo(b.name);
                      });

                      Household? selectedHousehold = households.firstWhereOrNull(
                          (h) => h.id == firestoreService.selectedHouseholdId);

                      if (selectedHousehold == null && households.isNotEmpty) {
                        selectedHousehold = households.firstWhere(
                            (h) => h.isPersonal,
                            orElse: () => households.first);
                        firestoreService.selectedHouseholdId = selectedHousehold.id;
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
                                    h.name, // Removed "(Personal)" suffix
                                    overflow: TextOverflow.ellipsis,
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
                          style: const TextStyle(color: Colors.white, fontSize: 14),
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
                FutureBuilder<List<PantryItemModel>>(
                  future: widget.isGuest
                      ? firestoreService.loadGuestPantryItems()
                      : (firestoreService.selectedHouseholdId == null
                          ? Future.value([])
                          : firestoreService.getPantryItemsForHousehold(firestoreService.selectedHouseholdId!).first),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    final items = snapshot.data ?? [];
                    final activeItems = items.where((item) => item.status != 'Deleted' && item.status != 'Consumed').toList();
                    return _buildPantryOverview(activeItems);
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
