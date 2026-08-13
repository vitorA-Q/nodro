import '../../engine/core/technique_tier.dart';
import '../../l10n/app_localizations.dart';

/// The four player-facing difficulty bands (decision D3).
///
/// Only the TIER is ever stored — in the bank, in progress, everywhere. This
/// enum is a display mapping and nothing else, which is what makes "show five
/// names instead of four" a one-file change that touches no saved data.
enum Difficulty {
  easy(<int>[1]),
  medium(<int>[2]),
  hard(<int>[3]),
  extreme(<int>[4, 5, 6, 7]);

  const Difficulty(this.tiers);

  /// Technique tiers that fall into this band.
  final List<int> tiers;

  bool matches(TechniqueTier tier) => tiers.contains(tier.level);

  static Difficulty of(TechniqueTier tier) {
    for (final difficulty in Difficulty.values) {
      if (difficulty.matches(tier)) {
        return difficulty;
      }
    }
    return Difficulty.extreme;
  }

  String label(AppLocalizations l10n) => switch (this) {
        Difficulty.easy => l10n.difficultyEasy,
        Difficulty.medium => l10n.difficultyMedium,
        Difficulty.hard => l10n.difficultyHard,
        Difficulty.extreme => l10n.difficultyExtreme,
      };

  /// Stable key for storing progress. Deliberately the enum name rather than
  /// the index, so reordering the enum never silently reassigns someone's
  /// saved history.
  String get storageKey => name;
}
