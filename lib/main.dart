import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shelf_control/screens/create_account_page.dart';
import 'package:shelf_control/screens/login_page.dart';
import 'package:shelf_control/screens/guest_page.dart';
import 'package:shelf_control/screens/splash_screen.dart';
import 'package:shelf_control/screens/welcome_page.dart';
import 'package:shelf_control/screens/feature_preview_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart'; // Required for kReleaseMode

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    DevicePreview(
      enabled: false, // Enable DevicePreview only in debug mode !kReleaseMode
      builder: (context) => const ShelfControlApp(),
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
      ),
      // Use DevicePreview's builder for locale and builder
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      home: const SplashScreen(),
      routes: {
        '/create-account': (context) => const CreateAccountPage(),
        '/login': (context) => const LoginPage(),
        '/guest': (context) => const GuestPage(),
        '/feature-preview': (context) => const FeaturePreviewScreen(),
      },
    );
  }
}
