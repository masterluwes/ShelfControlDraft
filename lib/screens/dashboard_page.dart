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
import 'package:shelf_control/screens/feedback.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelf_control/screens/pantryinventory.dart';
import 'package:shelf_control/models/pantry_item_model.dart';
import 'package:shelf_control/screens/addpantryitem.dart';
import 'package:shelf_control/screens/household_page.dart';
import 'package:shelf_control/screens/shoppinglist.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shelf_control/screens/scan_item_screen.dart';
import 'package:shelf_control/screens/history_screen.dart';
import 'package:shelf_control/services/firestore_service.dart';
import 'package:shelf_control/models/household_model.dart';
import 'package:shelf_control/models/shopping_history_item_model.dart';
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';
import 'package:shelf_control/screens/waste_tracker_page.dart';
import 'package:shelf_control/screens/create_account_page.dart';
import 'package:shelf_control/screens/mealsuggest.dart';
import 'package:shelf_control/screens/dietary_preference_page.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DashboardPage extends StatefulWidget {
  final int initialIndex;
  final bool isGuest;
  const DashboardPage({super.key, this.initialIndex = 0, this.isGuest = false});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  int _unreadNotificationsCount = 0;
  bool _isSnoozed = false;
  bool _isMealSuggestActive = false;
  late PackageInfo _packageInfo = PackageInfo(appName: 'Unknown', packageName: 'Unknown', version: 'Unknown', buildNumber: 'Unknown'); // Initialize with default values

  late FirestoreService _firestoreService;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _initPackageInfo();

    _pages = [
      DashboardHome(isGuest: widget.isGuest),
      Pantryinventory(isGuest: widget.isGuest),
      Shoppinglist(isGuest: widget.isGuest),
      const TipsPage(),
      NotificationPage(
        onStatusChanged: (unreadCount, isSnoozed) {
          if (mounted) {
            setState(() {
              _unreadNotificationsCount = unreadCount;
              _isSnoozed = isSnoozed;
            });
          }
        },
      ),
    ];

    if (!widget.isGuest) {
      _firestoreService = Provider.of<FirestoreService>(context, listen: false);
      _currentUser = FirebaseAuth.instance.currentUser;
      _listenForNotifications();
    }
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = info;
      });
    }
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

  void _updateBodyWidget(int index) {
    setState(() {
      _selectedIndex = index;
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
          if (widget.isGuest) ...[
            IconButton(
              icon: const Icon(Icons.person_add, color: Colors.white),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateAccountPage()),
                );
              },
            ),
          ] else ...[
            IconButton(
              splashRadius: 22,
              tooltip: 'Suggest a Meal',
              onPressed: () async {
                setState(() => _isMealSuggestActive = true);
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MealSuggest()),
                );
                if (!mounted) return;
                setState(() => _isMealSuggestActive = false);
              },
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  _isMealSuggestActive
                      ? Icons.local_dining
                      : Icons.local_dining_outlined,
                  key: ValueKey<bool>(_isMealSuggestActive),
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  onPressed: () {
                    _updateBodyWidget(4); // Switch to NotificationPage tab
                  },
                ),
                if (_unreadNotificationsCount > 0 && !_isSnoozed)
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
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF2E7D32),
        shape: const CircularNotchedRectangle(),
        notchMargin: 10.0,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navBarItem(Icons.home, Icons.home_outlined, "Home", 0),
              _navBarItem(Icons.kitchen, Icons.kitchen_outlined, "Pantry", 1),
              const SizedBox(width: 49),
              _navBarItem(Icons.shopping_cart, Icons.shopping_cart_outlined, "Shopping", 2),
              _navBarItem(Icons.lightbulb, Icons.lightbulb_outline, "Tips", 3),
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
        elevation: 8.0,
        shape: const CircleBorder(),
        children: [
          SpeedDialChild(
            child: const Icon(Icons.camera_alt, color: Color(0xFF2E7D32)),
            backgroundColor: Colors.white,
            label: 'Add by Camera',
            onTap: () async {
              if (!mounted) return;
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
                  for (var item in scannedItems) {
                    await firestoreService.addPantryItem(item);
                  }
                }
                if (!mounted) return;
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
            onTap: () {
              final firestoreService = Provider.of<FirestoreService>(context, listen: false);
              final householdId = widget.isGuest ? FirebaseAuth.instance.currentUser?.uid : firestoreService.selectedHouseholdId;

              if (!widget.isGuest && householdId == null) {
                // Optionally, you could show a dialog or other non-snackbar feedback here
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddPantryItem(
                    isGuest: widget.isGuest,
                    householdId: householdId!,
                    onAddItem: (PantryItemModel newItem) async {
                      final fs = Provider.of<FirestoreService>(context, listen: false);
                      if (widget.isGuest) {
                        List<PantryItemModel> currentGuestPantry = await fs.loadGuestPantryItems();
                        currentGuestPantry.add(newItem);
                        await fs.saveGuestPantryItems(currentGuestPantry);
                      } else {
                        await fs.addPantryItem(newItem);
                      }
                    },
                    onBack: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => DashboardPage(initialIndex: 1, isGuest: widget.isGuest)),
                        (route) => false,
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _navBarItem(IconData activeIcon, IconData inactiveIcon, String label, int index) {
    final isActive = _selectedIndex == index;
    return InkWell(
      onTap: () => _updateBodyWidget(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isActive ? activeIcon : inactiveIcon, color: Colors.white, size: 28),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
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
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            if (!widget.isGuest) ...[
              _drawerItem(Icons.person, "Profile", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage()))),
              _drawerItem(Icons.notifications, "Notification Settings", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationSettingsPage()))),
              _drawerItem(Icons.history, "History", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()))),
              _drawerItem(Icons.delete, "Waste Tracker", () => Navigator.push(context, MaterialPageRoute(builder: (context) => WasteTrackerPage()))),
              _drawerItem(Icons.info, "User Guide", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UserGuidePage()))),
              _drawerItem(Icons.feedback, "Feedback", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FeedbackPage()))),
              _drawerItem(Icons.description, "Terms and Conditions", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsAndConditionsScreen()))),
              _drawerItem(Icons.privacy_tip, "Privacy Policy", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()))),
            ] else ...[
              _drawerItem(Icons.person_add, "Create Account", () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const CreateAccountPage()))),
              _drawerItem(Icons.info, "User Guide", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UserGuidePage()))),
              _drawerItem(Icons.feedback, "Feedback", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FeedbackPage()))),
              _drawerItem(Icons.description, "Terms and Conditions", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsAndConditionsScreen()))),
              _drawerItem(Icons.privacy_tip, "Privacy Policy", () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()))),
            ],
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                if (widget.isGuest) {
                  final firestoreService = Provider.of<FirestoreService>(context, listen: false);
                  await firestoreService.clearGuestData();
                  if (!mounted) return;
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const WelcomePage()),
                    (Route<dynamic> route) => false,
                  );
                } else {
                  final firestoreService = Provider.of<FirestoreService>(context, listen: false);
                  await AuthService(firestoreService).signOut();
                  if (!mounted) return;
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const WelcomePage()),
                    (Route<dynamic> route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, shape: const StadiumBorder()),
              child: Text(widget.isGuest ? "Exit Guest Mode" : "Log Out", style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.center,
              child: Text(
                'Version: ${_packageInfo.version}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
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
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              if (widget.isGuest)
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(6)),
                  child: const Center(child: Text("Local Pantry", style: TextStyle(color: Colors.white, fontSize: 14))),
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
                      Household? selectedHousehold = households.firstWhereOrNull((h) => h.id == firestoreService.selectedHouseholdId);
                      if (selectedHousehold == null && households.isNotEmpty) {
                        selectedHousehold = households.firstWhere((h) => h.isPersonal, orElse: () => households.first);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          firestoreService.selectedHouseholdId = selectedHousehold!.id;
                        });
                      }
                      return Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 8), // Adjusted padding
                        decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(6)),
                        child: DropdownButton<String>(
                          value: selectedHousehold?.id,
                          items: households.map((h) => DropdownMenuItem(value: h.id, child: Text(h.name, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              firestoreService.selectedHouseholdId = value;
                            }
                          },
                          dropdownColor: const Color(0xFF2E7D32),
                          underline: Container(),
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          iconEnabledColor: Colors.white,
                          isExpanded: true, // Ensure it takes available width
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
                if (!widget.isGuest && firestoreService.selectedHouseholdId != null) ...[
                  Consumer<FirestoreService>(
                    builder: (context, fs, child) {
                      final householdId = fs.selectedHouseholdId;
                      if (householdId == null) {
                        return _buildNoDataDashboard();
                      }
                      return StreamBuilder<List<PantryItemModel>>(
                        stream: fs.getPantryItemsForHousehold(householdId),
                        builder: (context, pantrySnapshot) {
                          if (pantrySnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (pantrySnapshot.hasError) {
                            return Text('Error loading pantry items: ${pantrySnapshot.error}');
                          }
                          final items = pantrySnapshot.data ?? [];
                          if (items.isEmpty) {
                            return _buildNoDataDashboard();
                          }
                          return FutureBuilder<Map<String, dynamic>>(
                            future: fs.getWeeklyWasteAndConsumptionSummary(householdId),
                            builder: (context, summarySnapshot) {
                              if (summarySnapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (summarySnapshot.hasError) {
                                return Text('Error loading summary: ${summarySnapshot.error}');
                              }
                              final weeklySummary = summarySnapshot.data ?? {};

                              return StreamBuilder<List<ShoppingHistoryItemModel>>(
                                stream: fs.getShoppingHistoryForHousehold(householdId),
                                builder: (context, historySnapshot) {
                                  if (historySnapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  if (historySnapshot.hasError) {
                                    return Text('Error loading history: ${historySnapshot.error}');
                                  }
                                  final allHistoryItems = historySnapshot.data ?? [];
                                  return _buildDataDashboard(items, weeklySummary, allHistoryItems);
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ]
                else if (widget.isGuest)
                  FutureBuilder<List<PantryItemModel>>(
                    future: firestoreService.loadGuestPantryItems(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final items = snapshot.data ?? [];
                      final activeItems = items.where((item) => item.status != 'Deleted' && item.status != 'Consumed').toList();
                      if (activeItems.isEmpty) {
                      return _buildNoDataDashboard();
                    }
                    return FutureBuilder<Widget>(
                      future: Future.value(_buildPantryOverview(activeItems)),
                      builder: (context, pantryOverviewSnapshot) {
                        if (pantryOverviewSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (pantryOverviewSnapshot.hasError) {
                          return Text('Error building pantry overview: ${pantryOverviewSnapshot.error}');
                        }
                        return pantryOverviewSnapshot.data ?? Container();
                      },
                    );
                  },
                )
                else
                  _buildNoDataDashboard(),
                const SizedBox(height: 16),
                // Quick Consume is now integrated into the Expiring Soon card
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataDashboard(List<PantryItemModel> items, Map<String, dynamic> weeklySummary, List<ShoppingHistoryItemModel> allHistoryItems) {
    final currentMoment = DateTime.now();
    final sevenDaysAgo = currentMoment.subtract(const Duration(days: 7));

    final totalConsumedQuantity = weeklySummary['totalConsumedQuantity'] as int;
    final totalWastedQuantity = weeklySummary['totalWastedQuantity'] as int;
    final expiredWastedQuantity = weeklySummary['expiredWastedQuantity'] as int;
    final totalOutflowQuantity = weeklySummary['totalOutflowQuantity'] as int;


    final wasteCount = totalWastedQuantity; // Number of items wasted this week
    final usageCount = totalConsumedQuantity; // Usage is now directly from the summary

    const restockThreshold = 1;
    final lowStockCount = items.where((i) => i.qty <= restockThreshold && i.status != 'Deleted' && i.status != 'Consumed').length;

    final totalConsumedQtyAllTime = allHistoryItems.where((i) => i.actionType == 'Consumed').fold<int>(0, (sum, item) => sum + item.quantity);
    final totalWastedQtyAllTime = allHistoryItems.where((i) => i.actionType == 'Wasted' || i.actionType == 'Expired Waste').fold<int>(0, (sum, item) => sum + item.quantity);
    final totalOutflowQtyAllTime = totalConsumedQtyAllTime + totalWastedQtyAllTime;
    final consumptionRatePct = totalOutflowQtyAllTime == 0 ? 0 : ((totalConsumedQtyAllTime / totalOutflowQtyAllTime) * 100).round();

    final expiringSoonItems = items.where((i) =>
        i.expirationDate != null &&
        i.expirationDate!.isAfter(currentMoment) &&
        i.expirationDate!.difference(currentMoment).inDays <= 7 &&
        i.status != 'Deleted' && i.status != 'Consumed'
    ).toList();
    final expiringSoonCount = expiringSoonItems.length;

    final String suggestionText = () {
      if (expiredWastedQuantity > 0) return "You have $expiredWastedQuantity items expired this week. Try to use items before their expiry date.";
      if (totalWastedQuantity > 0) return "Waste is high this week — try smaller purchases or prioritize near-expiry items.";
      if (lowStockCount > 0) return "You have $lowStockCount low-stock items — consider restocking essentials.";
      if (expiringSoonCount > 0) return "$expiringSoonCount items expiring soon — plan meals to use them first.";
      return "Great job keeping waste low! Rotate stock: use older items before new ones.";
    }();

    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _metricCard(icon: Icons.delete, label: "Waste", value: "$wasteCount", sublabel: "items wasted this week"),
            _metricCard(icon: Icons.bar_chart, label: "Usage", value: "$usageCount", sublabel: "items consumed this week"),
            _metricCard(icon: Icons.shopping_cart, label: "Restock", value: "$lowStockCount", sublabel: "low-stock items (≤1)"),
            _metricCard(icon: Icons.insights, label: "Consumption Rate", value: "$consumptionRatePct%", sublabel: "consumed vs wasted (all-time)"),
            _metricCard(
              icon: Icons.access_alarm,
              label: "Expiring Soon",
              value: "$expiringSoonCount",
              sublabel: "within 7 days"
            ),
            _tipCard(icon: Icons.lightbulb, tipText: suggestionText),
          ],
        ),
        const SizedBox(height: 16),
        _buildPantryOverview(items),
      ],
    );
  }

  Widget _buildNoDataDashboard() {
    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          physics: const NeverScrollableScrollPhysics(),
          children: [
          _metricCard(icon: Icons.delete, label: "Waste", value: "—", sublabel: "No data available yet!"),
          _metricCard(icon: Icons.bar_chart, label: "Usage", value: "—", sublabel: "No data available yet!"),
          _metricCard(icon: Icons.shopping_cart, label: "Restock", value: "—", sublabel: "No data available yet!"),
          _metricCard(icon: Icons.insights, label: "Consumption Rate", value: "—", sublabel: "No data available yet!"),
          _metricCard(icon: Icons.access_alarm, label: "Expiring Soon", value: "—", sublabel: "No data available yet!"),
          _tipCard(icon: Icons.lightbulb, tipText: "No data available yet!"),
          ],
        ),
        const SizedBox(height: 16),
        _buildPantryOverview([]),
      ],
    );
  }

  Widget _metricCard({required IconData icon, required String label, required String value, String? sublabel}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
          if (sublabel != null) ...[
            const SizedBox(height: 2),
            Text(sublabel, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ],
      ),
    );
  }

  Widget _smallMetricCard({required IconData icon, required String label, required String value, String? sublabel}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(8), // Smaller padding
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20), // Smaller icon
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), // Smaller value font
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10)), // Smaller label font
          if (sublabel != null) ...[
            const SizedBox(height: 1),
            Text(sublabel, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, color: Colors.black54)), // Smaller sublabel font
          ],
        ],
      ),
    );
  }

  Widget _tipCard({required IconData icon, required String tipText}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 28),
          const SizedBox(height: 8),
          const Text("Suggestion", style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Flexible(child: Text(tipText, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildPantryOverview(List<PantryItemModel> items) {
    final activeItems = items.where((item) => item.status != 'Deleted' && item.status != 'Consumed').toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Pantry Overview", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (activeItems.isEmpty)
            const Text("No data available yet! - Start by clicking the + icon", style: TextStyle(fontSize: 12))
          else
            Text("Total items: ${activeItems.length}", style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

}
