import '../../../core/cell_ref.dart';
import '../../../core/deduction.dart';
import '../../../core/technique_tier.dart';
import '../board.dart';

/// TIER 3 — Forward Elimination (depth-1 refutation).
///
/// Tentatively place a star in one candidate, apply **only** the immediate
/// forced consequences — the no-touch blackout and unit saturation — and if any
/// unit can then no longer reach its quota, the candidate is eliminated.
///
/// SOUNDNESS: this is modus tollens. `star(c)` implies a contradiction,
/// therefore `not star(c)`. The contradiction is detected using only monotone,
/// sound propagation and capacity counts, so a reported contradiction is a real
/// one and the true solution's stars are never refuted.
///
/// THIS IS NOT GUESSING. It is depth 1, it never branches, it never selects a
/// branch to keep, and no state survives a failed trial. The multi-ply version
/// (`deepLookAhead`) is deliberately excluded from this project: it would solve
/// every uniquely-solvable puzzle and so destroy the difficulty ladder that P2
/// depends on.
class ForwardElimination implements Technique<StarBattleBoard> {
  const ForwardElimination();

  @override
  String get id => 'sbForwardElimination';

  @override
  TechniqueTier get tier => TechniqueTier.tier3;

  @override
  List<Deduction> apply(StarBattleBoard state) {
    final deductions = <Deduction>[];
    final cellCount = state.size * state.size;

    for (var cell = 0; cell < cellCount; cell++) {
      if (!state.isUnknown(cell)) {
        continue;
      }
      if (!_leadsToContradiction(state, cell)) {
        continue;
      }
      deductions.add(Deduction(
        techniqueId: id,
        tier: tier,
        kind: DeductionKind.elimination,
        highlightedCells: <CellRef>[state.refOf(cell)],
        affectedCells: <CellRef>[state.refOf(cell)],
        explanationArgs: <String, Object>{
          'cell': state.refOf(cell).toString(),
        },
      ));
    }
    return deductions;
  }

  /// Places a star on a throwaway copy and applies one round of forced marks.
  bool _leadsToContradiction(StarBattleBoard state, int cell) {
    final trial = StarBattleBoard.copy(state);
    trial.placeStar(cell);

    // Consequence 1: the no-touch blackout.
    for (final neighbour in trial.neighboursOf(cell)) {
      if (trial.isUnknown(neighbour)) {
        trial.markEmpty(neighbour);
      }
    }

    // Consequence 2: any unit that just reached its quota is closed out.
    for (final unit in trial.unitsOfCell[cell]) {
      if (trial.remainingIn(unit) != 0) {
        continue;
      }
      for (final other in trial.unknownsIn(unit)) {
        trial.markEmpty(other);
      }
    }

    return trial.hasContradiction;
  }
}
