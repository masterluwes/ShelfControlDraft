import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  // Keep colors consistent with your main file
  static const Color _headerGreen = Color(0xFF2E7D32);
  static const Color _softCream = Color(0xFFFFFBE6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softCream,

      // AppBar same visual height as your main (64)
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: _NotifAppBar(),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              // Title
              Text(
                'Notifications',
                style: TextStyle(
                  color: _headerGreen,
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ),
              SizedBox(height: 8),

              // Subheader
              Text(
                'Today',
                style: TextStyle(
                  color: Color(0xFF222222),
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),

              // Notice tile
              _ReminderDisabledTile(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom top bar: green, with Back chevron + label on the left.
/// No notif/group icons, and no hamburger.
class _NotifAppBar extends StatelessWidget {
  const _NotifAppBar();

  static const Color _headerGreen = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: _headerGreen,
      centerTitle: false,
      automaticallyImplyLeading: false,
      titleSpacing: 0,

      // Back control
      leadingWidth: 110,
      leading: InkWell(
        onTap: () => Navigator.maybePop(context),
        borderRadius: BorderRadius.circular(24),
        child: const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Row(
            children: [
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

      // No actions (notif / groups)
      actions: const <Widget>[],
      title: const SizedBox.shrink(),
    );
  }
}

/// Gray notice row matching the mock:
/// "Expiry Reminders aren’t enabled. Register/Login to setup this feature."
class _ReminderDisabledTile extends StatelessWidget {
  const _ReminderDisabledTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bell icon in a small circle for visual weight
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFFBDBDBD),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),

          // Message with bold fragments
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  color: Color(0xFF222222),
                  height: 1.3,
                ),
                children: [
                  TextSpan(
                    text: 'Expiry Reminders',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: ' aren’t enabled.\n'),
                  TextSpan(
                    text: 'Register/Login',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: ' to setup this feature.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
