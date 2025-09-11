import 'package:flutter/material.dart';

/// ---------- Centralized styles (file-scope so every widget can use them) ----------
const Color headerGreen = Color(0xFF2E7D32);
const Color softCream = Color(0xFFFFFBE6);
const Color mutedGreen = Color(0xFF6D845F);

const TextStyle titleStyle = TextStyle(
  fontSize: 33,
  fontWeight: FontWeight.bold,
  color: headerGreen,
  fontFamily: 'Inter',
);

const TextStyle dateStyle = TextStyle(fontSize: 14, color: mutedGreen);

const TextStyle headingStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w700,
  color: Colors.black87,
  height: 1.4,
);

const TextStyle subheadingStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
  color: Colors.black87,
  height: 1.45,
);

const TextStyle bodyStyle = TextStyle(
  fontSize: 14,
  height: 1.5,
  color: Colors.black87,
);

const TextStyle bulletTextStyle = TextStyle(
  fontSize: 14,
  height: 1.5,
  color: Colors.black87,
);

const TextStyle smallBold = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w600,
  color: Colors.black87,
);

/// ---------- Page ----------
class UserGuidePage extends StatefulWidget {
  const UserGuidePage({super.key});

  @override
  State<UserGuidePage> createState() => _UserGuidePageState();
}

class _UserGuidePageState extends State<UserGuidePage> {
  // Track open tiles (allow multiple)
  final Set<int> _open = {}; // “Getting Started” open by default

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softCream,
      body: SafeArea(
        child: Column(
          children: [
            // Back row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back, color: headerGreen),
                        SizedBox(width: 4),
                        Text(
                          'Back',
                          style: TextStyle(
                            color: headerGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Text('User Guide', style: titleStyle)),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        'Last Updated September 2025',
                        style: dateStyle,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Accordion tiles
                    _AccordionTile(
                      index: 0,
                      title: 'Getting Started',
                      isOpen: _open.contains(0),
                      onToggle: _toggle,
                      child: const _GettingStartedCard(),
                    ),
                    _AccordionTile(
                      index: 1,
                      title: 'Key Features',
                      isOpen: _open.contains(1),
                      onToggle: _toggle,
                      child: const _DetailedListCard(
                        intro:
                            'ShelfControl empowers households to manage food smarter, waste less, and plan better. Here’s what you’ll find at the heart of the app:',
                        items: [
                          {
                            'title': 'Analytics Dashboard',
                            'body':
                                'Track item usage, expiry trends, and waste reduction over time. Visual insights help you make informed decisions and celebrate progress.',
                          },
                          {
                            'title': 'Pantry Inventory',
                            'body':
                                'Easily add, update, and organize pantry items. Categorize by type (e.g., canned goods, grains, snacks), set expiry dates, and monitor stock levels in real time.',
                          },
                          {
                            'title': 'Shopping List',
                            'body':
                                'Automatically generate smart grocery lists tailored to what’s missing in your pantry, your budget preferences, and your healthy eating goals.',
                          },
                          {
                            'title': 'Meal Planner',
                            'body':
                                'Plan meals for the week using what you already have. ShelfControl suggests recipes that match your inventory and prioritize items nearing expiry.',
                          },
                        ],
                      ),
                    ),
                    _AccordionTile(
                      index: 2,
                      title: 'Advanced Features',
                      isOpen: _open.contains(2),
                      onToggle: _toggle,
                      child: const _DetailedListCard(
                        intro:
                            'For users who want more control, automation, and collaboration, ShelfControl offers these powerful tools:',
                        items: [
                          {
                            'title': 'Product Scanning',
                            'body':
                                'Quickly add items using barcode scanning or image recognition. Ideal for busy households and bulk restocking.',
                          },
                          {
                            'title': 'Dynamic Grocery Planner',
                            'body':
                                'Automatically builds your grocery list based on selected meals, pantry status, and consumption habits. It adapts in real time—no more guesswork or duplicate purchases.',
                          },
                          {
                            'title': 'Smart Tips Suggestions',
                            'body':
                                'Get contextual tips for each item—how to store it, when to consume it, and creative ways to use it. Perfect for reducing waste and discovering new recipes.',
                          },
                          {
                            'title': 'Expiry-Aware Reminders',
                            'body':
                                'Receive timely alerts when items are nearing expiration. Customize thresholds (e.g., 3 days before expiry) and prioritize high-risk categories like dairy or produce.',
                          },
                          {
                            'title': 'Secure Multi-Sharing Feature',
                            'body':
                                'Invite family members or housemates to manage the pantry together. Assign roles (Admin, Member, Viewer) and sync updates across devices securely.',
                          },
                        ],
                      ),
                    ),

                    // Settings and Customization tile
                    _AccordionTile(
                      index: 3,
                      title: 'Settings and Customization',
                      isOpen: _open.contains(3),
                      onToggle: _toggle,
                      child: const _SettingsCustomizationCardUnified(),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggle(int i) {
    setState(() {
      if (_open.contains(i)) {
        _open.remove(i);
      } else {
        _open.add(i);
      }
    });
  }
}

/// ---------- Widgets ----------

class _AccordionTile extends StatelessWidget {
  const _AccordionTile({
    required this.index,
    required this.title,
    required this.isOpen,
    required this.onToggle,
    required this.child,
  });

  final int index;
  final String title;
  final bool isOpen;
  final void Function(int) onToggle;
  final Widget child;

  static const headerGreenLocal = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final bgColor = isOpen ? headerGreenLocal : Colors.white;
    final textColor = isOpen ? Colors.white : headerGreenLocal;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // Header bar
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onToggle(index),
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(Icons.keyboard_arrow_down, color: textColor),
                  ),
                ],
              ),
            ),
          ),
          // Body card
          AnimatedCrossFade(
            crossFadeState: isOpen
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
            firstChild: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: child,
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _GettingStartedCard extends StatelessWidget {
  const _GettingStartedCard();

  static const headerGreenLocal = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            style: bodyStyle,
            children: [
              TextSpan(text: 'Welcome to '),
              TextSpan(
                text: 'ShelfControl',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(
                text:
                    '! We’re thrilled to help you manage your pantry, plan your meals and contribute in reducing food waste. Let’s get you set up.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "When you open ShelfControl for the first time, you’ll see multiple options:",
          style: bodyStyle,
        ),
        const SizedBox(height: 10),

        // Example: using the widget variant for body so we can italicize features
        _bullet(
          title: 'Sign Up',
          body:
              'Create a free account to save your pantry data, create a household pantry with your family or roommates, and sync across devices. You just need a valid email address and a password.',
        ),
        _bullet(
          title: 'Log In',
          body:
              'If you already have an account, enter your email and password to access your information.',
        ),
        _bullet(
          title: 'Continue as Guest',
          // use bodyWidget so we can italicize specific feature names
          bodyWidget: RichText(
            text: TextSpan(
              style: bodyStyle,
              children: const [
                TextSpan(
                  text:
                      'Explore the app without signing up. Note that your data won’t be saved or synced, and several features like the ',
                ),
                TextSpan(
                  text: 'Expiry Reminders',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                TextSpan(text: ' and '),
                TextSpan(
                  text: 'Multi-Sharing Feature',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                TextSpan(text: ' will be unavailable.'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// _bullet accepts either a plain [body] string OR a [bodyWidget] for rich content.
  static Widget _bullet({
    required String title,
    String? body,
    Widget? bodyWidget,
  }) {
    assert(
      (body != null) ^ (bodyWidget != null),
      'Provide exactly one of body or bodyWidget',
    );

    if (bodyWidget != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Icon(Icons.circle, size: 6, color: headerGreenLocal),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  bodyWidget,
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // simple title + body string
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Icon(Icons.circle, size: 6, color: headerGreenLocal),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: bodyStyle,
                  children: [
                    TextSpan(
                      text: '$title: ',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: body),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}

class _DetailedListCard extends StatelessWidget {
  const _DetailedListCard({this.intro, required this.items});
  final String? intro;
  final List<Map<String, String>> items;

  static const headerGreenLocal = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (intro != null) ...[
          Text(intro!, style: bodyStyle),
          const SizedBox(height: 12),
        ],
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(Icons.circle, size: 6, color: headerGreenLocal),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: bodyStyle,
                      children: [
                        TextSpan(
                          text: "${item['title']}: ",
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: item['body']),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({required this.lines});
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(
                    Icons.circle,
                    size: 6,
                    color: _GettingStartedCard.headerGreenLocal,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(line, style: bodyStyle)),
              ],
            ),
          ),
      ],
    );
  }
}

/// ---------- New: Settings & Customization Card (Unified styles) ----------

class _SettingsCustomizationCardUnified extends StatelessWidget {
  const _SettingsCustomizationCardUnified();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Settings and Customization', style: headingStyle),
        const SizedBox(height: 8),
        const Text(
          "ShelfControl gives users full control over their pantry experience—from notification timing to account preferences. Here's how to personalize your setup for smarter food management.",
          style: bodyStyle,
        ),
        const SizedBox(height: 12),

        // Profile Settings
        const Text('Profile Settings', style: headingStyle),
        const SizedBox(height: 6),
        const Text(
          'Manage your account details and privacy preferences with ease.',
          style: bodyStyle,
        ),
        const SizedBox(height: 8),
        const Text('Actions:', style: smallBold),
        const SizedBox(height: 6),
        _bulletLine('Tap Save Changes to update your profile.'),
        _bulletLine(
          'Tap Delete Account to permanently remove your data (confirmation required).',
        ),

        const SizedBox(height: 12),

        // Notification Settings
        const Text('Notification Settings', style: headingStyle),
        const SizedBox(height: 6),
        const Text(
          'Stay informed without being overwhelmed. Customize what alerts you receive and when.',
          style: bodyStyle,
        ),
        const SizedBox(height: 8),
        const Text('Additional Controls:', style: smallBold),
        const SizedBox(height: 6),
        _bulletLine(
          'Number of Days for “At Risk” Items: Set how many days before expiry you want to be alerted (e.g., 6 days).',
        ),
        _bulletLine(
          'Notification Time: Choose the time of day to receive alerts (e.g., 7:00 AM).',
        ),

        const SizedBox(height: 8),

        // Multi-User Access (full content)
        const Text('Multi-User Access', style: headingStyle),
        const SizedBox(height: 6),
        const Text(
          'Collaborative Pantry Management for Every Household\n\n'
          'ShelfControl supports shared food management across multiple users, making it ideal for families, roommates, or caregiving setups. Whether you\'re managing one household or several, this feature ensures everyone stays informed and organized.',
          style: bodyStyle,
        ),
        const SizedBox(height: 12),

        // Household Groups
        const Text('Household Groups', style: subheadingStyle),
        const SizedBox(height: 6),
        const Text(
          'Create and manage distinct household groups with unique member sets. Each group maintains its own pantry, shopping list, and meal planner—no overlap unless intentionally shared.',
          style: bodyStyle,
        ),
        const SizedBox(height: 8),

        // Member Roles and Permissions
        const Text('Member Roles and Permissions', style: subheadingStyle),
        const SizedBox(height: 6),
        const Text(
          'Assign roles to control access and responsibilities.',
          style: bodyStyle,
        ),
        const SizedBox(height: 8),
        _bulletLine('Admins and Members are clearly labeled in the UI.'),

        const SizedBox(height: 12),

        // Member Management Interface
        const Text('Member Management Interface', style: subheadingStyle),
        const SizedBox(height: 6),
        const Text(
          'From the Household Manage Page, admins can:',
          style: bodyStyle,
        ),
        const SizedBox(height: 8),
        _bulletLine('View all members with profile icons and names.'),
        _bulletLine('Remove or restrict access with one tap.'),
        _bulletLine(
          'Highlight active households (- for selected, - for alternate).',
        ),
        _bulletLine('Monitor changes and sync updates across all devices.'),

        const SizedBox(height: 12),

        // Real-Time Syncing
        const Text('Real-Time Syncing', style: subheadingStyle),
        const SizedBox(height: 6),
        const Text(
          "All changes—whether adding an item, updating expiry, or planning meals—are instantly reflected across all members' devices. This ensures:",
          style: bodyStyle,
        ),
        const SizedBox(height: 8),
        _bulletLine('No duplicate purchases.'),
        _bulletLine('No missed expiry alerts.'),
        _bulletLine('Seamless coordination for shared shopping and cooking.'),

        const SizedBox(height: 12),

        // Privacy and Security
        const Text('Privacy and Security', style: subheadingStyle),
        const SizedBox(height: 6),
        _bulletLine('Only invited users with valid Party Codes can join.'),
        _bulletLine('Admins control who stays in the group.'),
        _bulletLine('All data is encrypted and stored securely.'),
        _bulletLine(
          'Users can Leave Pantry or Delete Pantry with confirmation prompts.',
        ),
      ],
    );
  }

  static Widget _bulletLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: headerGreen),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: bulletTextStyle)),
        ],
      ),
    );
  }
}
