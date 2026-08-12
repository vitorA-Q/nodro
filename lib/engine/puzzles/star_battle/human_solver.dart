import '../../core/deduction.dart';
import '../../core/puzzle_type.dart';
import '../../core/solve_result.dart';
import '../../core/technique_tier.dart';
import 'board.dart';
import 'model.dart';
import 'techniques/adjacency_elimination.dart';
import 'techniques/crowding_exclusion.dart';
import 'techniques/forward_elimination.dart';
import 'techniques/line_region_confinement.dart';
import 'techniques/region_line_confinement.dart';
import 'techniques/regions_within_lines.dart';
import 'techniques/shared_neighbour_elimination.dart';
import 'techniques/unit_completion_elimination.dart';
import 'techniques/unit_forced_fill.dart';

/// The PRODUCT (C3). Applies named techniques in tier order and never guesses.
///
/// DETERMINISM (risk E5) is a hard requirement, not a nicety: if the same puzzle
/// could be rated differently on two runs, PROP-3 would fail intermittently,
/// which is the worst kind of bug. Three rules guarantee it:
///
///   1. techniques are held in a fixed, ordered list;
///   2. after ANY change the search restarts from tier 1, so a cheap technique
///      is always preferred over an expensive one for the same conclusion;
///   3. every technique scans cells in row-major order and never iterates a
///      structure with undefined ordering.
class StarBattleHumanSolver
    implements HumanSolver<StarBattlePuzzle, StarBattleSolution> {
  StarBattleHumanSolver();

  /// Ordered by tier, then by cost within a tier. The order is part of the
  /// contract: changing it changes hint choice and can change difficulty labels.
  static final List<Technique<StarBattleBoard>> orderedTechniques =
      List<Technique<StarBattleBoard>>.unmodifiable(
          <Technique<StarBattleBoard>>[
    // Tier 1 — cheap, cascading, run to fixpoint constantly.
    const AdjacencyElimination(),
    const UnitCompletionElimination(),
    const UnitForcedFill(),
    // Tier 2 — local confinement.
    const SharedNeighbourElimination(),
    const RegionLineConfinement(),
    const LineRegionConfinement(),
    const CrowdingExclusion(),
    // Tier 3 — bounded refutation.
    const ForwardElimination(),
    // Tier 4 — set arguments across units.
    const RegionsWithinLines(),
  ]);

  @override
  List<String> get techniqueIds =>
      orderedTechniques.map((technique) => technique.id).toList(growable: false);

  @override
  SolveResult solve(StarBattlePuzzle puzzle,
      {TechniqueTier maxTier = TechniqueTier.tier7}) {
    final board = StarBattleBoard(puzzle);
    return solveBoard(board, maxTier: maxTier);
  }

  /// Solves from an existing board, so the hint engine can resume from whatever
  /// the player has already filled in.
  SolveResult solveBoard(StarBattleBoard board,
      {TechniqueTier maxTier = TechniqueTier.tier7}) {
    final steps = <Deduction>[];

    while (true) {
      if (board.hasContradiction) {
        return SolveResult(
          outcome: SolveOutcome.contradiction,
          steps: steps,
          cellsResolved: board.resolvedCellCount,
        );
      }
      if (board.isSolved) {
        return SolveResult(
          outcome: SolveOutcome.solved,
          steps: steps,
          cellsResolved: board.resolvedCellCount,
        );
      }

      final applied = _applyOneRound(board, maxTier, steps);
      if (!applied) {
        return SolveResult(
          outcome: SolveOutcome.stuck,
          steps: steps,
          cellsResolved: board.resolvedCellCount,
        );
      }
    }
  }

  /// Runs techniques in order until one of them changes something, then stops.
  /// Returning after the first productive technique is what implements rule 2
  /// above: the search always restarts from tier 1.
  bool _applyOneRound(
      StarBattleBoard board, TechniqueTier maxTier, List<Deduction> steps) {
    for (final technique in orderedTechniques) {
      if (technique.tier > maxTier) {
        continue;
      }
      final deductions = technique.apply(board);
      var changed = false;
      for (final deduction in deductions) {
        if (_applyDeduction(board, deduction)) {
          steps.add(deduction);
          changed = true;
        }
      }
      if (changed) {
        return true;
      }
    }
    return false;
  }

  /// Writes one deduction to the board. Returns whether anything was new.
  static bool _applyDeduction(StarBattleBoard board, Deduction deduction) {
    var changed = false;
    for (final ref in deduction.affectedCells) {
      final index = ref.toIndex(board.size);
      final didChange = deduction.kind == DeductionKind.assertion
          ? board.placeStar(index)
          : board.markEmpty(index);
      changed = changed || didChange;
    }
    return changed;
  }

  /// The next deduction a hint should show, or null when nothing applies.
  ///
  /// Always the lowest-tier step available (P3: the *simplest* next valid
  /// deduction), because [orderedTechniques] is scanned in tier order.
  Deduction? nextHint(StarBattleBoard board,
      {TechniqueTier maxTier = TechniqueTier.tier7}) {
    for (final technique in orderedTechniques) {
      if (technique.tier > maxTier) {
        continue;
      }
      for (final deduction in technique.apply(board)) {
        if (_wouldChangeAnything(board, deduction)) {
          return deduction;
        }
      }
    }
    return null;
  }

  static bool _wouldChangeAnything(StarBattleBoard board, Deduction deduction) {
    for (final ref in deduction.affectedCells) {
      if (board.isUnknown(ref.toIndex(board.size))) {
        return true;
      }
    }
    return false;
  }

  /// PROP-3 / decision D4 — the two-sided difficulty rating.
  ///
  /// Walking tiers upward gives the two-sided property for free: the first tier
  /// `d` that solves is, by construction, a tier at which `d - 1` already
  /// failed. That rules out the case the one-sided definition would accept — a
  /// puzzle labelled hard where the hard technique was used but never needed.
  ///
  /// Returns null when no tier solves it, which means the puzzle requires
  /// guessing and must be rejected by the generator (PROP-2).
  @override
  TechniqueTier? rateDifficulty(StarBattlePuzzle puzzle) {
    for (final tier in TechniqueTier.values) {
      if (solve(puzzle, maxTier: tier).isSolved) {
        return tier;
      }
    }
    return null;
  }
}
