import 'package:flutter/material.dart';

class UserGuidePage extends StatelessWidget {
  const UserGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBE6),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back, color: Color(0xFF2E7D32)),
                        SizedBox(width: 4),
                        Text(
                          'Back',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        "User Guide",
                        style: TextStyle(
                          fontSize: 33,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Center(
                      child: Text(
                        "Last Updated June 2025",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6D845F),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // INTRODUCTION
                    _sectionTitle("INTRODUCTION"),
                    _sectionBody(
                      "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor "
                      "incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud "
                      "exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure "
                      "dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. "
                      "Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt "
                      "mollit anim id est laborum.\n\n"
                      "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor "
                      "incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud "
                      "exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
                    ),

                    const SizedBox(height: 20),

                    // DASHBOARD
                    _sectionTitle("DASHBOARD"),
                    _sectionBody(
                      "Dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt "
                      "in culpa qui officia deserunt mollit anim id est laborum.\n\n"
                      "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor "
                      "incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud.",
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2E7D32),
      ),
    );
  }

  static Widget _sectionBody(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        textAlign: TextAlign.justify,
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
          color: Colors.black87,
        ),
      ),
    );
  }
}