import '../../../core/cell_ref.dart';
import '../../../core/deduction.dart';
import '../../../core/technique_tier.dart';
import '../board.dart';

/// TIER 2 — Crowding (the "selfish roommate").
///
/// In a unit that still needs two or more stars, a candidate that touches
/// *every* other candidate of that unit is impossible: taking it would leave
/// nowhere legal for the unit's other stars.
///
/// SOUNDNESS: a star at such a cell would blank out every remaining candidate
/// of the unit through the no-touch rule, leaving the unit with zero places for
/// the `r - 1` stars it still owes. That is a genuine contradiction, so no
/// valid solution — in particular not the true one — stars that cell.
///
/// The classic instance is the centre of a 3x3 cluster.
class CrowdingExclusion implements Technique<StarBattleBoard> {
  const CrowdingExclusion();

  @override
  String get id => 'sbCrowdingExclusion';

  @override
  TechniqueTier get tier => TechniqueTier.tier2;

  @override
  List<Deduction> apply(StarBattleBoard state) {
    final deductions = <Deduction>[];
    for (final unit in state.units) {
      final remaining = state.remainingIn(unit);
      if (remaining < 2) {
        continue;
      }
      final candidates = state.unknownsIn(unit);
      if (candidates.length <= remaining) {
        continue; // forced fill territory, not crowding
      }

      for (final candidate in candidates) {
        final survivors = candidates
            .where((other) =>
                other != candidate && !state.touches(candidate, other))
            .toList(growable: false);
        if (survivors.length >= remaining - 1) {
          continue;
        }
        deductions.add(Deduction(
          techniqueId: id,
          tier: tier,
          kind: DeductionKind.elimination,
          highlightedCells: candidates.map(state.refOf).toList(growable: false),
          affectedCells: <CellRef>[state.refOf(candidate)],
          explanationArgs: <String, Object>{
            'unitKind': unit.kind.name,
            'unitIndex': unit.displayIndex,
            'remaining': remaining,
          },
        ));
      }
    }
    return deductions;
  }
}
