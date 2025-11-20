import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // Added for Firebase App Check
import 'package:shelf_control/screens/create_account_page.dart';
import 'package:shelf_control/screens/login_page.dart';
import 'package:shelf_control/screens/welcome_page.dart';
import 'package:shelf_control/screens/feature_preview_screen.dart';
import 'package:shelf_control/screens/dashboard_page.dart';
import 'package:shelf_control/screens/guest_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelf_control/services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'package:shelf_control/services/notification_service.dart'; // Import the new service
import 'package:shelf_control/services/shopping_list_service.dart'; // Import ShoppingListService
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'package:shelf_control/services/guest_auth_service.dart'; // Import GuestAuthService

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // ✅ load from assets
    await dotenv.load(fileName: "assets/env/.env");
  } catch (e) {
    // Don’t crash the app if the file isn’t found; just log.
    debugPrint('dotenv load failed: $e');
  }
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );

  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FirestoreService()),
        // ShoppingListService depends on FirestoreService, so it should be created after it.
        // We use ProxyProvider to access FirestoreService.
        Provider<ShoppingListService>(
          create: (context) => ShoppingListService(
            firestoreService: Provider.of<FirestoreService>(context, listen: false),
          ),
        ),
      ],
      child: const ShelfControlApp(),
    ),
  );
}

class ShelfControlApp extends StatelessWidget {
  const ShelfControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ShelfControl',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        // Removed incorrect SnackBarThemeData margin property.
        // SnackBar positioning will be handled directly in each SnackBar instance.
      ),
      home: const AuthWrapper(), // Set AuthWrapper as the initial home to handle authentication flow
      routes: {
        '/create-account': (context) => const CreateAccountPage(),
        '/login': (context) => const LoginPage(),
        '/guest': (context) => const GuestPage(),
        '/feature-preview': (context) => const FeaturePreviewScreen(),
        '/dashboard': (context) => const DashboardPage(),
        '/welcome': (context) => const WelcomePage(), // Add welcome route
        '/auth-wrapper': (context) => const AuthWrapper(), // Add AuthWrapper route
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  late Future<User?> _initialAuthCheckFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialAuthCheckFuture = _checkInitialAuthState();
  }

  Future<User?> _checkInitialAuthState() async {
    // Attempt to get the current user immediately
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && !currentUser.isAnonymous) {
      // If an authenticated user exists, update last login and return
      Provider.of<FirestoreService>(context, listen: false).updateLastLoginAt(currentUser.uid);
      return currentUser;
    }
    // If no authenticated user, proceed with guest re-authentication check
    return GuestAuthService.reauthenticateGuest();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.isAnonymous) {
        // Update lastLoginAt when the app resumes and user is logged in
        Provider.of<FirestoreService>(context, listen: false)
            .updateLastLoginAt(user.uid);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _initialAuthCheckFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final User? user = snapshot.data;

          if (user != null && !user.isAnonymous) {
            // If an authenticated user is found, proceed to HouseholdSetupPage
            return const HouseholdSetupPage();
          } else if (user != null && user.isAnonymous) {
            // If guest re-authentication was successful, go to dashboard
            return const DashboardPage(isGuest: true);
          } else {
            // If no user (neither authenticated nor re-authenticated guest),
            // listen to authStateChanges for fresh login or initial guest creation
            return StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, authStateSnapshot) {
                if (authStateSnapshot.connectionState == ConnectionState.active) {
                  final User? authUser = authStateSnapshot.data;
                  if (authUser == null) {
                    return const WelcomePage();
                  }
                  if (!authUser.isAnonymous) {
                    Provider.of<FirestoreService>(context, listen: false)
                        .updateLastLoginAt(authUser.uid);
                  }
                  return const HouseholdSetupPage();
                }
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
            );
          }
        }
        // While initial authentication check is in progress
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

class HouseholdSetupPage extends StatefulWidget {
  const HouseholdSetupPage({super.key});

  @override
  State<HouseholdSetupPage> createState() => _HouseholdSetupPageState();
}

class _HouseholdSetupPageState extends State<HouseholdSetupPage> {
  late Future<void> _setupFuture;

  @override
  void initState() {
    super.initState();
    _setupFuture = _setupHousehold();
  }

  Future<void> _setupHousehold() async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await firestoreService.setInitialHousehold(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _setupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            // Handle error, maybe log it and show an error page or go to login
            return const WelcomePage();
          }
          final bool isGuestUser = FirebaseAuth.instance.currentUser?.isAnonymous ?? false;
          return DashboardPage(isGuest: isGuestUser);
        }
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
