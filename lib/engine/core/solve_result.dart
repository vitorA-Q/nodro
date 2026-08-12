import 'deduction.dart';
import 'technique_tier.dart';

/// How a human-simile solve ended.
enum SolveOutcome {
  /// Every cell was determined using named techniques only.
  solved,

  /// No technique in the enabled set fires any more, and the grid is unfinished.
  /// This is a legitimate outcome, not an error: it means the puzzle is outside
  /// the declared difficulty envelope and the generator must reject it (PROP-2).
  stuck,

  /// The state is provably inconsistent. On a well-formed puzzle this can only
  /// mean a technique is unsound, which is a critical bug (PROP-4).
  contradiction,
}

/// The outcome of counting solutions with the exhaustive oracle.
///
/// Deliberately has no "how many" beyond two: the oracle exits early on the
/// second solution, because the only question P1 asks is "exactly one?".
enum SolutionCount {
  /// No solution exists. For a solution-first generator this indicates a bug.
  none,

  /// Exactly one solution. This is the only acceptable state for a shipped puzzle.
  unique,

  /// At least two solutions. The puzzle is rejected.
  multiple,
}

/// The full record of a human-simile solve.
///
/// [steps] is kept in order because it is the raw material for both the hint
/// engine (P3) and the difficulty rating (P2): the hint is the first step still
/// applicable, and the rating is derived from the tiers used.
class SolveResult {
  SolveResult({
    required this.outcome,
    required List<Deduction> steps,
    required this.cellsResolved,
  }) : steps = List<Deduction>.unmodifiable(steps);

  final SolveOutcome outcome;

  /// Every deduction applied, in the order it was applied.
  final List<Deduction> steps;

  /// How many cells the solver managed to determine.
  final int cellsResolved;

  bool get isSolved => outcome == SolveOutcome.solved;

  /// The most advanced tier any applied step needed.
  ///
  /// Null only when no step was applied at all. Note this is one half of PROP-3:
  /// the label is confirmed only when the solve also *fails* one tier lower
  /// (decision D4), which [SolveResult] alone cannot know.
  TechniqueTier? get hardestTier {
    TechniqueTier? hardest;
    for (final step in steps) {
      if (hardest == null || step.tier > hardest) {
        hardest = step.tier;
      }
    }
    return hardest;
  }

  /// Counts how many steps were applied at each tier. Useful for grading how
  /// *often* the hardest technique was actually needed, not just whether it was.
  Map<TechniqueTier, int> get stepsPerTier {
    final counts = <TechniqueTier, int>{};
    for (final step in steps) {
      counts[step.tier] = (counts[step.tier] ?? 0) + 1;
    }
    return counts;
  }

  @override
  String toString() => 'SolveResult(${outcome.name}, ${steps.length} steps, '
      'hardest T${hardestTier?.level ?? 0})';
}
