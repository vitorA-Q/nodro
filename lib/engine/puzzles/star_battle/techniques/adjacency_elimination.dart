import '../../../core/cell_ref.dart';
import '../../../core/deduction.dart';
import '../../../core/technique_tier.dart';
import '../board.dart';

/// TIER 1 — Neighbour Elimination.
///
/// Every cell touching a proven star, including diagonally, cannot be a star.
///
/// SOUNDNESS: the no-touch rule holds in every valid solution, so a cell
/// touching a cell that is a star in the true solution is provably not a star
/// in the true solution.
class AdjacencyElimination implements Technique<StarBattleBoard> {
  const AdjacencyElimination();

  @override
  String get id => 'sbAdjacencyElimination';

  @override
  TechniqueTier get tier => TechniqueTier.tier1;

  @override
  List<Deduction> apply(StarBattleBoard state) {
    final deductions = <Deduction>[];
    final cellCount = state.size * state.size;
    for (var cell = 0; cell < cellCount; cell++) {
      if (!state.isStar(cell)) {
        continue;
      }
      final affected =
          state.neighboursOf(cell).where(state.isUnknown).toList(growable: false);
      if (affected.isEmpty) {
        continue;
      }
      deductions.add(Deduction(
        techniqueId: id,
        tier: tier,
        kind: DeductionKind.elimination,
        highlightedCells: <CellRef>[state.refOf(cell)],
        affectedCells: affected.map(state.refOf).toList(growable: false),
        explanationArgs: <String, Object>{
          'starCell': state.refOf(cell).toString(),
          'count': affected.length,
        },
      ));
    }
    return deductions;
  }
}
