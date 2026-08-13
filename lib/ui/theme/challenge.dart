import '../../engine/core/technique_tier.dart';

/// A single 1..10 number comparable ACROSS board sizes.
///
/// ## Why this exists
///
/// The four difficulty labels are a convention *within* a size, and that is
/// correct: an "Extreme" 6x6 really is easier than a "Medium" 9x9, in this app
/// and in every other one in the genre. The labels are not wrong — they are
/// simply silent about the comparison, and the player is left to discover it by
/// being surprised. So nothing about the labels changes; this adds the missing
/// axis beside them.
///
/// ## The formula
///
/// ```
/// raw = 1
///     + (size - 6)  * 0.7    // more cells, more to hold in your head
///     + (stars - 1) * 1.8    // two stars per unit is a different game
///     + (tier - 1)  * 1.05   // the deduction the puzzle actually demands
/// challenge = round(raw), clamped to 1..10
/// ```
///
/// The weights are chosen so the star count outranks the board size: going from
/// one star to two changes the reasoning itself, while going from 6x6 to 8x8
/// mostly adds bookkeeping. Deterministic, so the same puzzle always shows the
/// same number.
///
/// Worked examples:
/// ```
/// 6x6 1★ tier 1  ->  1      6x6 1★ tier 4  ->  4
/// 8x8 1★ tier 2  ->  3      8x8 1★ tier 4  ->  5
/// 9x9 2★ tier 2  ->  6      9x9 2★ tier 4  ->  8
/// ```
int globalChallenge({
  required int size,
  required int stars,
  required TechniqueTier tier,
}) {
  final raw = 1 +
      (size - 6) * 0.7 +
      (stars - 1) * 1.8 +
      (tier.level - 1) * 1.05;
  return raw.round().clamp(1, 10);
}
