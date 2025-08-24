import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shelf_control/screens/create_account_page.dart';
import 'package:shelf_control/screens/login_page.dart';
import 'package:shelf_control/screens/guest_page.dart';
import 'package:shelf_control/screens/welcome_page.dart';
import 'package:shelf_control/screens/feature_preview_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ShelfControlApp());
}

class ShelfControlApp extends StatelessWidget {
  const ShelfControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShelfControl',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator(); // Or a splash screen
          }
          if (snapshot.hasData) {
            return const FeaturePreviewScreen(); // User is logged in
          }
          return WelcomePage(); // User is not logged in
        },
      ),
      routes: {
        '/create-account': (context) => const CreateAccountPage(),
        '/login': (context) => const LoginPage(),
        '/guest': (context) => const GuestPage(),
        '/feature-preview': (context) => const FeaturePreviewScreen(),
      },
    );
  }
}
