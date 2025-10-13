import 'package:flutter/material.dart';
import 'package:shelf_control/services/weather_service.dart';

class TipCardModel {
  final String title;
  final String subtitle;
  final String details;
  final IconData icon;
  const TipCardModel({
    required this.title,
    required this.subtitle,
    required this.details,
    required this.icon,
  });
}

class TipsRules {
  /// Returns item-specific tips based on category, item name, and weather level.
  static List<TipCardModel> adviceFor(
    String category,
    String itemName,
    WeatherLevel lvl,
  ) {
    final cat = category.trim().toLowerCase();
    final item = itemName.trim().toLowerCase();

    // ---- Dairy (example with strong RED/BLUE/GREEN guidance) ----
    if (cat == 'dairy') {
      if (lvl == WeatherLevel.red) {
        // Typhoon present (RED)
        return [
          const TipCardModel(
            title: 'Secure Cold Chain Now',
            subtitle: 'Keep milk & dairy safe during outages',
            details:
                'Freeze ice packs and jugs of water to extend fridge cold time. '
                'Move milk, cheese, and yogurt to the back of the fridge (coldest spot). '
                'Minimize door opening. If power goes out, keep doors closed—milk is safe if ≤4 °C.',
            icon: Icons.ac_unit,
          ),
          const TipCardModel(
            title: 'Plan Fast Consumption',
            subtitle: 'Use the most perishable dairy first',
            details:
                'Prioritize milk nearing expiry: cook into soups, pasta, pancakes. '
                'Grate and freeze hard cheeses in airtight bags if you won’t use them within 48 h.',
            icon: Icons.fastfood,
          ),
        ];
      } else if (lvl == WeatherLevel.blue) {
        // Storm approaching (BLUE)
        return [
          const TipCardModel(
            title: 'Pre-cool & Organize Fridge',
            subtitle: 'Get ready for possible outages',
            details:
                'Reduce fridge temp slightly (but avoid freezing). '
                'Group dairy items together and label open dates. '
                'Buy UHT milk backups; keep them in a cool, dry cabinet.',
            icon: Icons.kitchen,
          ),
          const TipCardModel(
            title: 'Moisture & Seal Check',
            subtitle: 'Protect quality during humid spells',
            details:
                'Wipe condensation; re-seal containers tightly. '
                'Store butter and cheese in airtight boxes to reduce odors and moisture pickup.',
            icon: Icons.inventory_2_outlined,
          ),
        ];
      } else {
        // GREEN
        return [
          const TipCardModel(
            title: 'Daily Dairy Care',
            subtitle: 'Keep milk fresh longer',
            details:
                'Store milk on a middle shelf, not the door. '
                'Return to the fridge immediately after pouring. '
                'Use opened milk within 3–5 days; follow FIFO on yogurt and cheese.',
            icon: Icons.local_drink,
          ),
        ];
      }
    }

    // ---- Beverages ----
    if (cat == 'beverages') {
      if (lvl == WeatherLevel.red) {
        return [
          const TipCardModel(
            title: 'Set Aside Potable Water',
            subtitle: 'Minimum 3–4 L per person per day',
            details:
                'Keep sealed bottles in a cool, dark place. '
                'Chill a few in the fridge now; freeze some to help keep fridge cold during outages.',
            icon: Icons.water_drop,
          ),
        ];
      } else if (lvl == WeatherLevel.blue) {
        return [
          const TipCardModel(
            title: 'Stock Shelf-Stable Drinks',
            subtitle: 'UHT milk, boxed juices, powdered drinks',
            details:
                'Prioritize resealable packaging. Store off the floor in a dry cabinet; rotate stock (FIFO).',
            icon: Icons.local_cafe,
          ),
        ];
      } else {
        return [
          const TipCardModel(
            title: 'Keep Caps Tight',
            subtitle: 'Quality care for coffee/tea/juices',
            details:
                'Store coffee/tea in airtight containers, away from heat and light. '
                'Refrigerate opened juices; finish within 3–5 days.',
            icon: Icons.coffee,
          ),
        ];
      }
    }

    // ---- Canned goods ----
    if (cat == 'canned goods') {
      if (lvl == WeatherLevel.red) {
        return [
          const TipCardModel(
            title: 'Ready-to-Eat Priority',
            subtitle: 'No-cook cans on top of the stack',
            details:
                'Place canned fish/beans/veggies where they’re easy to grab. '
                'Have a manual can opener. Check for dents/bulges—discard if compromised.',
            icon: Icons.inventory,
          ),
        ];
      } else if (lvl == WeatherLevel.blue) {
        return [
          const TipCardModel(
            title: 'Top-Up Essentials',
            subtitle: '3-day minimum supply',
            details:
                'Stock canned fish/beans/veggies and ready-to-eat snacks. '
                'Store in a cool, dry cabinet; avoid damp floors and walls.',
            icon: Icons.add_shopping_cart,
          ),
        ];
      } else {
        return [
          const TipCardModel(
            title: 'FIFO & Label',
            subtitle: 'Rotate and track open cans',
            details:
                'Use oldest first (FIFO). After opening, transfer leftovers to sealed containers and refrigerate.',
            icon: Icons.checklist_rtl,
          ),
        ];
      }
    }

    // ---- Dry goods ----
    if (cat == 'dry goods') {
      if (lvl == WeatherLevel.red) {
        return [
          const TipCardModel(
            title: 'Moisture Guard',
            subtitle: 'Protect flour, sugar, grains',
            details:
                'Keep in airtight containers; elevate from the floor. '
                'If humidity rises, add desiccant packs to bins.',
            icon: Icons.cloud_off,
          ),
        ];
      } else if (lvl == WeatherLevel.blue) {
        return [
          const TipCardModel(
            title: 'Refill Staples',
            subtitle: 'Rice, pasta, noodles',
            details:
                'Top up at least 3 days’ worth. Store sealed; keep away from cleaning chemicals and heat sources.',
            icon: Icons.rice_bowl,
          ),
        ];
      } else {
        return [
          const TipCardModel(
            title: 'Pest-Proof Storage',
            subtitle: 'Keep bins clean and airtight',
            details:
                'Wipe containers before refilling. Label open dates. Use bay leaves or traps if insects appear.',
            icon: Icons.bug_report_outlined,
          ),
        ];
      }
    }

    // ---- Snacks ----
    if (cat == 'snacks') {
      if (lvl == WeatherLevel.red || lvl == WeatherLevel.blue) {
        return [
          const TipCardModel(
            title: 'Seal Against Humidity',
            subtitle: 'Crisps & crackers go soft fast',
            details:
                'Use clips or airtight jars. Store off the counter in a dry cabinet. Keep a few ready-to-eat packs for emergencies.',
            icon: Icons.cookie,
          ),
        ];
      } else {
        return [
          const TipCardModel(
            title: 'Portion Smart',
            subtitle: 'Avoid staling',
            details:
                'Decant large packs into smaller airtight containers. Keep away from sunlight/stove heat.',
            icon: Icons.set_meal,
          ),
        ];
      }
    }

    // ---- Condiments ----
    if (cat == 'condiments') {
      if (lvl == WeatherLevel.red) {
        return [
          const TipCardModel(
            title: 'Tighten Lids',
            subtitle: 'Prevent leaks in outages',
            details:
                'Check caps on oils, sauces, and vinegar. Move glass bottles to lower shelves to reduce break risk.',
            icon: Icons.soup_kitchen,
          ),
        ];
      } else if (lvl == WeatherLevel.blue) {
        return [
          const TipCardModel(
            title: 'Check Essentials',
            subtitle: 'Salt, sugar, oil, soy, vinegar',
            details:
                'Refill small containers; keep bulk sealed. Store oil in a cool, dark cabinet.',
            icon: Icons.inventory_2,
          ),
        ];
      } else {
        return [
          const TipCardModel(
            title: 'Clean Spouts & Caps',
            subtitle: 'Keep bottles tidy',
            details:
                'Wipe residues; reduce contamination. Keep spices in airtight jars away from heat/light.',
            icon: Icons.cleaning_services,
          ),
        ];
      }
    }

    // ---- Produce (pantry-only scope) ----
    if (cat == 'produce') {
      if (lvl == WeatherLevel.red) {
        return [
          const TipCardModel(
            title: 'Use-First List',
            subtitle: 'Consume the most perishable items',
            details:
                'Prioritize leafy greens and ripe fruits. Keep onions/garlic in aerated baskets; dry muddy veggies before storing.',
            icon: Icons.local_florist,
          ),
        ];
      } else if (lvl == WeatherLevel.blue) {
        return [
          const TipCardModel(
            title: 'Humidity Control',
            subtitle: 'Reduce mold risk',
            details:
                'Keep produce dry; line baskets with paper. Separate ethylene-producers (bananas) from sensitive items.',
            icon: Icons.grass,
          ),
        ];
      } else {
        return [
          const TipCardModel(
            title: 'Cool, Dry, Dark',
            subtitle: 'Standard produce care',
            details:
                'Keep away from stove and sunlight. Rotate (FIFO). Check daily for spoilage spots.',
            icon: Icons.brightness_low,
          ),
        ];
      }
    }

    // ---- Uncategorized / Others ----
    return [
      const TipCardModel(
        title: 'General Pantry Care',
        subtitle: 'Applies to most shelf-stable items',
        details:
            'Keep items sealed and off the floor, away from heat and sunlight. '
            'Label open dates and follow FIFO. Check for pests and moisture.',
        icon: Icons.category,
      ),
    ];
  }
}
