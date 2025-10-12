String normalizeName(String raw) {
  final s = raw.toLowerCase().trim();
  // minimal aliasing — expand later
  if (s.contains('pancit canton') || s.contains('ramen') || s.contains('noodles')) return 'instant noodles';
  if (s.contains('spaghetti') || s.contains('pasta')) return 'pasta';
  return s;
}

bool isNearExpiry(DateTime? expiry, {int days = 5}) {
  if (expiry == null) return false;
  return expiry.difference(DateTime.now()).inDays <= days;
}
