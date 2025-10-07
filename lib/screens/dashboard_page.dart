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
import 'package:shelf_control/screens/pantryinventory.dart';
import 'package:shelf_control/models/pantry_item_model.dart';
import 'package:shelf_control/screens/addpantryitem.dart' as add_item;
import 'package:shelf_control/screens/household_page.dart';
import 'package:shelf_control/screens/shoppinglist.dart';
import 'package:shelf_control/screens/household_state.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shelf_control/screens/scan_item_screen.dart';
import 'package:shelf_control/screens/waste_tracker_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Widget? _currentBodyWidget;
  final List<PantryItemModel> _pantryItems = [
    PantryItemModel(
      id: 'oj1',
      name: 'Orange Juice (1L)',
      category: 'Beverages',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/0/0b/Orange_juice_1.jpg',
      qty: 1,
      expirationDate: DateTime.now().add(const Duration(days: 3)),
    ),
    PantryItemModel(
      id: 'ketch397',
      name: 'Ketchup (397g)',
      category: 'Condiments',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/9/9b/Tomato_ketchup.jpg',
      qty: 1,
      expirationDate: DateTime(2025, 6, 30),
    ),
    PantryItemModel(
      id: 'onion50',
      name: 'Onion Powder (50g)',
      category: 'Herbs/Spices',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/2/2a/Onion_Powder.jpg',
      qty: 1,
      expirationDate: DateTime(2025, 7, 3),
    ),
    PantryItemModel(
      id: 'soy300',
      name: 'Soy Sauce (300ml)',
      category: 'Condiments',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/1/13/Soy_sauce.jpg',
      qty: 1,
      expirationDate: DateTime(2025, 7, 15),
    ),
    PantryItemModel(
      id: 'sardines',
      name: 'Sardines',
      category: 'Canned Goods',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/2/27/Conserva_de_sardinas.jpg',
      qty: 2,
      expirationDate: DateTime(2025, 9, 19),
    ),
    PantryItemModel(
      id: 'coke500',
      name: 'Coca Cola (500ml)',
      category: 'Beverages',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/4/4f/Coca-Cola_bottle.jpg',
      qty: 1,
      expirationDate: DateTime(2026, 12, 19),
    ),
    PantryItemModel(
      id: 'oj2',
      name: 'Orange Juice (1L)',
      category: 'Beverages',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/0/0b/Orange_juice_1.jpg',
      qty: 1,
      expirationDate: DateTime.now().add(const Duration(days: 3)),
    ),
  ];

  bool _isOnNotificationPage = false;
  Widget? _lastPageBeforeNotifications;
  bool _hasUnreadNotifications = false;
  bool _isSnoozed = false;

  @override
  void initState() {
    super.initState();
    _currentBodyWidget = DashboardHome(pantryItems: _pantryItems);
    _listenForNotifications();
  }

  void _listenForNotifications() {
    //TODO: BACKEND HERE FOR NOTIFICATIONS
  }

  void _showPage(Widget page) {
    setState(() {
      _currentBodyWidget = page;
    });
  }

  void _showPantryInventory() {
    _showPage(
      Pantryinventory(
        items: _pantryItems,
        onEdit: _showEditPantryItem,
        onDelete: (item) {
          setState(() {
            _pantryItems.removeWhere((element) => element.id == item.id);
          });
        },
        onAddItems: (newItems) {
          setState(() {
            _pantryItems.addAll(newItems);
          });
          _showPantryInventory();
        },
      ),
    );
  }

  void _showAddPantryItem() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => add_item.AddPantryItem(
          onAddItem: (newItem) {
            setState(() {
              _pantryItems.add(newItem);
            });
            _showPantryInventory(); 
          },
          onBack: () => Navigator.pop(context), onSave: (updatedItem) {  },
        ),
      ),
    );
  }

  void _showEditPantryItem(PantryItemModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPantryItem(
          item: item,
          onBack: () => Navigator.pop(context),
          onSave: (updatedItem) {
            final index = _pantryItems.indexWhere(
              (element) => element.id == updatedItem.id,
            );
            if (index != -1) {
              setState(() {
                _pantryItems[index] = updatedItem;
              });
            }
            _showPantryInventory();
          },
        ),
      ),
    );
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
        actions: [
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
                () => _showPage(DashboardHome(pantryItems: _pantryItems)),
              ),
              _navBarItem(
                Icons.kitchen,
                Icons.kitchen_outlined,
                "Pantry",
                _showPantryInventory,
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
              final List<PantryItemModel>? scannedItems = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScanItemScreen()),
              );
              if (scannedItems != null && scannedItems.isNotEmpty) {
                setState(() {
                  _pantryItems.addAll(scannedItems);
                });
                _showPantryInventory();
              }
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.edit, color: Color(0xFF2E7D32)),
            backgroundColor: Colors.white,
            label: 'Add Manually',
            labelStyle: const TextStyle(fontSize: 18.0, color: Colors.black),
            onTap: _showAddPantryItem,
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
            _drawerItem(Icons.delete, "Waste Tracker", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WasteTrackerPage()),
              );
            }),
            _drawerItem(Icons.info, "User Guide", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserGuidePage()),
              );
            }),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ListTile(
                  leading: Icon(Icons.feedback, color: Colors.white),
                  title: Text(
                    "Feedback",
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
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

EditPantryItem({required PantryItemModel item, required void Function() onBack, required Null Function(dynamic updatedItem) onSave}) {
}

class DashboardHome extends StatelessWidget {
  final List<PantryItemModel> pantryItems;
  const DashboardHome({super.key, required this.pantryItems});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Overview",
                style: TextStyle(
                  fontSize: 33,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: AnimatedBuilder(
                  animation: HouseholdState(),
                  builder: (context, _) {
                    return DropdownButton<String>(
                      value: HouseholdState().selectedPantry,
                      items: HouseholdState()
                          .allPantries
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          HouseholdState().selectPantry(value);
                        }
                      },
                      dropdownColor: const Color(0xFF2E7D32),
                      underline: Container(),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      iconEnabledColor: Colors.white,
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
                _buildPantryOverview(pantryItems),
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