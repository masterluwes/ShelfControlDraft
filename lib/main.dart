import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // Added for Firebase App Check
import 'package:shelf_control/screens/create_account_page.dart';
import 'package:shelf_control/screens/login_page.dart';
import 'package:shelf_control/screens/welcome_page.dart';
import 'package:shelf_control/screens/feature_preview_screen.dart';
import 'package:shelf_control/screens/dashboard_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelf_control/services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'package:shelf_control/services/notification_service.dart'; // Import the new service

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );

  // Initialize NotificationService
  final NotificationService notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (context) => FirestoreService(),
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
      home: const AuthWrapper(),
      routes: {
        '/create-account': (context) => const CreateAccountPage(),
        '/login': (context) => const LoginPage(),
        '/guest': (context) => const DashboardPage(isGuest: true),
        '/feature-preview': (context) => const FeaturePreviewScreen(),
        '/dashboard': (context) => const DashboardPage(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final User? user = snapshot.data;
          if (user == null) {
            return WelcomePage();
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
            return WelcomePage();
          }
          return const DashboardPage();
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
