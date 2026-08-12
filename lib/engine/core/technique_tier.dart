/// The difficulty ladder, from 1 (a beginner sees it instantly) to 7 (deepest
/// reasoning we are willing to call a technique rather than a search).
///
/// The tier is the **only** difficulty value that is ever persisted (decision
/// D3). The four player-facing names live in a single display-layer file, so
/// changing to five names later touches one file and no stored data.
enum TechniqueTier {
  /// Trivially local: direct counting, adjacency exclusion around a placed mark.
  tier1(1),

  /// Simple counting and line/region containment.
  tier2(2),

  /// Combined counting across a few lines or regions.
  tier3(3),

  /// Shape, parity, or multi-region set arguments.
  tier4(4),

  /// Set-based deduction requiring several possibilities to be tracked at once.
  tier5(5),

  /// Chains and bounded refutation a strong human still performs without guessing.
  tier6(6),

  /// Reserved for anything deeper. Nothing here may require backtracking.
  tier7(7);

  const TechniqueTier(this.level);

  /// The numeric level, 1..7. This is what gets serialised.
  final int level;

  /// Rebuilds a tier from its persisted [level].
  static TechniqueTier fromLevel(int level) {
    for (final tier in TechniqueTier.values) {
      if (tier.level == level) {
        return tier;
      }
    }
    throw ArgumentError.value(level, 'level', 'must be between 1 and 7');
  }

  bool operator <(TechniqueTier other) => level < other.level;
  bool operator <=(TechniqueTier other) => level <= other.level;
  bool operator >(TechniqueTier other) => level > other.level;
  bool operator >=(TechniqueTier other) => level >= other.level;
}
