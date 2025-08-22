import 'package:flutter/material.dart';

class Householdgroupguest extends StatelessWidget {
  const Householdgroupguest({super.key});

  // Keep colors consistent with your main file
  static const Color _headerGreen = Color(0xFF2E7D32);
  static const Color _softCream = Color(0xFFFFFBE6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softCream,

      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: _GuestAppBar(),
      ),

      body: const SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'You need to Register/Login\nto access this feature.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _headerGreen,
                fontFamily: 'Inter',
                fontSize: 24,
                fontWeight: FontWeight.w900,
                height: 1.25,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom top bar: green, with Back chevron + label on the left.
/// Matches 64px height of the main app's AppBar.
class _GuestAppBar extends StatelessWidget {
  const _GuestAppBar();

  static const Color _headerGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: _headerGreen,
      centerTitle: false,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      // Create a custom "Back" control in the leading slot
      leadingWidth: 110, // room for icon + label
      leading: InkWell(
        onTap: () => Navigator.maybePop(context),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Row(
            children: const [
              Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              SizedBox(width: 4),
              Text(
                'Back',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
      // No actions (notif / groups) per requirement
      actions: const <Widget>[],
      title: const SizedBox.shrink(),
    );
  }
}
