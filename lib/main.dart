import 'package:flutter/material.dart';
import 'package:shelfcontrol/pages/guest_page.dart';
import 'pages/welcome_page.dart';
import 'pages/create_account_page.dart';
import 'pages/login_page.dart';

void main() {
  runApp(const ShelfControlApp());
}

class ShelfControlApp extends StatelessWidget {
  const ShelfControlApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShelfControl',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto'),
      initialRoute: '/',
      routes: {
        '/': (context) => WelcomePage(),
        '/create-account': (context) => const CreateAccountPage(),
        '/login': (context) => const LoginPage(),
        '/guest': (context) => const GuestPage(),
      },
    );
  }
}
