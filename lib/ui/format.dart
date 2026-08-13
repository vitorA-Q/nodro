/// `m:ss`, or `h:mm:ss` past an hour. Deliberately not localised: a clock
/// reads the same in every language this app ships in, and inventing a
/// localised duration format would add a dependency for no gain.
String formatDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  final ss = s.toString().padLeft(2, '0');
  if (h > 0) {
    return '$h:${m.toString().padLeft(2, '0')}:$ss';
  }
  return '$m:$ss';
}

/// `yyyy-mm-dd` in the player's own calendar.
String isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// How many days in a row ending today (or yesterday) appear in [completions].
///
/// Counting back from yesterday when today is missing is deliberate: a streak
/// should not look broken at breakfast just because the day's puzzle is not
/// done yet.
int currentStreak(Set<String> completions, DateTime today) {
  if (completions.isEmpty) {
    return 0;
  }
  var cursor = today;
  if (!completions.contains(isoDate(cursor))) {
    cursor = cursor.subtract(const Duration(days: 1));
    if (!completions.contains(isoDate(cursor))) {
      return 0;
    }
  }
  var streak = 0;
  while (completions.contains(isoDate(cursor))) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}
