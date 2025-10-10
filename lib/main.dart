import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shelf_control/screens/create_account_page.dart';
import 'package:shelf_control/screens/login_page.dart';
import 'package:shelf_control/screens/guest_page.dart';
import 'package:shelf_control/screens/splash_screen.dart';
import 'package:shelf_control/screens/welcome_page.dart';
import 'package:shelf_control/screens/feature_preview_screen.dart';
import 'package:shelf_control/screens/dashboard_page.dart'; // Import DashboardPage
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shelf_control/services/firestore_service.dart'; // Import FirestoreService
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; // Import provider

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => FirestoreService(),
      child: const ShelfControlApp(),
    ),
  );
}

class ShelfControlApp extends StatefulWidget {
  const ShelfControlApp({super.key});

  @override
  State<ShelfControlApp> createState() => _ShelfControlAppState();
}

class _ShelfControlAppState extends State<ShelfControlApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Removed useInheritedMediaQuery as it might conflict with DevicePreview's own MediaQuery handling
      debugShowCheckedModeBanner: false,
      title: 'ShelfControl',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const SplashScreen(),
      routes: {
        '/create-account': (context) => const CreateAccountPage(),
        '/login': (context) => const LoginPage(),
        '/guest': (context) => const GuestPage(),
        '/feature-preview': (context) => const FeaturePreviewScreen(),
        '/dashboard': (context) => const DashboardPage(), // Add dashboard route
      },
    );
  }
}
