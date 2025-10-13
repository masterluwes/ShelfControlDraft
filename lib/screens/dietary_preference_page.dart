import 'package:flutter/material.dart';

class DietaryPreferencesPage extends StatefulWidget {
  const DietaryPreferencesPage({super.key});

  @override
  State<DietaryPreferencesPage> createState() => _DietaryPreferencesPageState();
}

class _DietaryPreferencesPageState extends State<DietaryPreferencesPage> {
  bool pescatarian = false;
  bool vegan = false;
  bool vegetarian = false;

  bool dairy = false;
  bool egg = false;
  bool fishSeafood = false;
  bool gluten = false;
  bool peanut = false;

  bool pork = false;
  bool chili = false;

  // Mock backend update function
  Future<void> _updateSetting(String key, bool value) async {
    debugPrint("Saving setting: $key -> $value");
    // TODO: Integrate with backend or local storage
  }

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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        "Dietary Preferences",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Center(
                      child: Text(
                        "Set your dietary preferences to make ShelfControl work best for you.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black87, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Dietary",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildSwitchTile(
                      title: "Pescatarian",
                      subtitle:
                          "No meat or poultry; seafood-based products are allowed.",
                      value: pescatarian,
                      onChanged: (val) {
                        setState(() => pescatarian = val);
                        _updateSetting("pescatarian", val);
                      },
                    ),
                    _buildSwitchTile(
                      title: "Vegan",
                      subtitle:
                          "No animal products (meat, seafood, dairy, eggs, honey, gelatin).",
                      value: vegan,
                      onChanged: (val) {
                        setState(() => vegan = val);
                        _updateSetting("vegan", val);
                      },
                    ),
                    _buildSwitchTile(
                      title: "Vegetarian",
                      subtitle: "No meat or seafood; dairy and eggs allowed.",
                      value: vegetarian,
                      onChanged: (val) {
                        setState(() => vegetarian = val);
                        _updateSetting("vegetarian", val);
                      },
                    ),

                    const Divider(height: 30, thickness: 1.5),
                    const Text(
                      "Allergies",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildSwitchTile(
                      title: "Dairy",
                      subtitle:
                          "Avoid milk and milk-based products (cheese, yogurt, butter, whey, casein).",
                      value: dairy,
                      onChanged: (val) {
                        setState(() => dairy = val);
                        _updateSetting("dairy", val);
                      },
                    ),
                    _buildSwitchTile(
                      title: "Egg",
                      subtitle:
                          "Avoid eggs and egg-based ingredients (albumen, mayo).",
                      value: egg,
                      onChanged: (val) {
                        setState(() => egg = val);
                        _updateSetting("egg", val);
                      },
                    ),
                    _buildSwitchTile(
                      title: "Fish/Seafood",
                      subtitle:
                          "Avoid fish-based products (fish sauce, anchovy paste).",
                      value: fishSeafood,
                      onChanged: (val) {
                        setState(() => fishSeafood = val);
                        _updateSetting("fishSeafood", val);
                      },
                    ),
                    _buildSwitchTile(
                      title: "Gluten",
                      subtitle: "Avoid products with wheat, barley, or rye.",
                      value: gluten,
                      onChanged: (val) {
                        setState(() => gluten = val);
                        _updateSetting("gluten", val);
                      },
                    ),
                    _buildSwitchTile(
                      title: "Peanut",
                      subtitle:
                          "Avoid all peanuts and peanut-derived ingredients/oils.",
                      value: peanut,
                      onChanged: (val) {
                        setState(() => peanut = val);
                        _updateSetting("peanut", val);
                      },
                    ),

                    const Divider(height: 30, thickness: 1.5),
                    const Text(
                      "Ingredient-specific",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildSwitchTile(
                      title: "Pork",
                      subtitle: "Exclude pork and pork-derived ingredients.",
                      value: pork,
                      onChanged: (val) {
                        setState(() => pork = val);
                        _updateSetting("pork", val);
                      },
                    ),
                    _buildSwitchTile(
                      title: "Chili",
                      subtitle: "No chili peppers or chili-based heat.",
                      value: chili,
                      onChanged: (val) {
                        setState(() => chili = val);
                        _updateSetting("chili", val);
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBE6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: SwitchListTile(
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.2,
                ),
              ),
            ),
            value: value,
            activeThumbColor: const Color(0xFF2E7D32),
            activeTrackColor: const Color(0xFF81C784),
            onChanged: onChanged,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}
