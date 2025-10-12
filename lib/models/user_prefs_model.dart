class UserPrefs {
  final String userId;
  final String householdId;
  final List<String> diets;         // e.g., ["vegetarian"]
  final List<String> allergens;     // e.g., ["peanut","shellfish"]
  final List<String> dislikes;      // e.g., ["cilantro","olives"]
  final int dailyCaloriesTarget;    // e.g., 2000
  final int maxCookMinutes;         // per meal; e.g., 45
  final int defaultServings;        // e.g., 2

  const UserPrefs({
    required this.userId,
    required this.householdId,
    this.diets = const [],
    this.allergens = const [],
    this.dislikes = const [],
    this.dailyCaloriesTarget = 2000,
    this.maxCookMinutes = 45,
    this.defaultServings = 2,
  });

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'householdId': householdId,
    'diets': diets,
    'allergens': allergens,
    'dislikes': dislikes,
    'dailyCaloriesTarget': dailyCaloriesTarget,
    'maxCookMinutes': maxCookMinutes,
    'defaultServings': defaultServings,
  };

  factory UserPrefs.fromFirestore(Map<String, dynamic> m) => UserPrefs(
    userId: m['userId'] ?? '',
    householdId: m['householdId'] ?? '',
    diets: List<String>.from(m['diets'] ?? const []),
    allergens: List<String>.from(m['allergens'] ?? const []),
    dislikes: List<String>.from(m['dislikes'] ?? const []),
    dailyCaloriesTarget: (m['dailyCaloriesTarget'] ?? 2000) as int,
    maxCookMinutes: (m['maxCookMinutes'] ?? 45) as int,
    defaultServings: (m['defaultServings'] ?? 2) as int,
  );
}
