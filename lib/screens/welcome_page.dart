import 'package:flutter/material.dart';
import 'package:shelf_control/screens/login_page.dart';
import 'package:shelf_control/screens/guest_page.dart';
import 'package:shelf_control/screens/create_account_page.dart'; // Added import
import 'package:firebase_auth/firebase_auth.dart'; // Added import
 
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});
  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> welcomeData = [
    {
      'title': 'Welcome to ShelfControl!',
      'subtitle':
          'Your smart pantry assistant is here to help you make the most of every meal.',
      'image': 'assets/welcome1.png',
    },
    {
      'title': 'Hi there!',
      'subtitle':
          "Thanks for joining ShelfControl! Let's take smart teps toward smart food consumption and waste reduction.",
      'image': 'assets/welcome2.png',
    },
    {
      'title': "Glad you're here!",
      'subtitle':
          "ShelfControl makes pantry management easy with expire alerts, tips, and waste data. Let's get started!",
      'image': 'assets/welcome3.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBE6),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: welcomeData.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) => WelcomeContent(
                title: welcomeData[index]['title']!,
                subtitle: welcomeData[index]['subtitle']!,
                image: welcomeData[index]['image']!,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              welcomeData.length,
              (index) => buildDot(index: index),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const CreateAccountPage()),
                    );
                  },
                  child: const Text(
                    'Create Account',
                    style: TextStyle(
                      color: Color(0xFF2E7D32), // Forest Green
                      decoration: TextDecoration.underline,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const GuestPage()),
                    );
                  },
                  child: const Text(
                    'Continue as Guest',
                    style: TextStyle(
                      color: Color(0xFF2E7D32), // Forest Green
                      decoration: TextDecoration.underline,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  AnimatedContainer buildDot({required int index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentPage == index ? 20 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? const Color(0xFF2E7D32) : Colors.grey,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class WelcomeContent extends StatelessWidget {
  final String title, subtitle, image;
  const WelcomeContent({
    super.key,
    required this.title,
    required this.subtitle,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(image, height: 250),
          const SizedBox(height: 30),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Color(0xFF347928),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 16,
              color: Color(0xFF6D845F),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
