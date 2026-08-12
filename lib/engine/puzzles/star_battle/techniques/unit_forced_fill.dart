import '../../../core/deduction.dart';
import '../../../core/technique_tier.dart';
import '../board.dart';

/// TIER 1 — Forced Fill / Last Cells.
///
/// When a unit's undetermined cells are exactly as many as the stars it still
/// needs, every one of them is a star.
///
/// SOUNDNESS: the unit's remaining true stars are a subset of its surviving
/// candidates, because every prior elimination was sound; a subset of size `r`
/// inside a set of size `r` is the whole set.
class UnitForcedFill implements Technique<StarBattleBoard> {
  const UnitForcedFill();

  @override
  String get id => 'sbUnitForcedFill';

  @override
  TechniqueTier get tier => TechniqueTier.tier1;

  @override
  List<Deduction> apply(StarBattleBoard state) {
    final deductions = <Deduction>[];
    for (final unit in state.units) {
      final remaining = state.remainingIn(unit);
      if (remaining <= 0) {
        continue;
      }
      final unknowns = state.unknownsIn(unit);
      if (unknowns.length != remaining) {
        continue;
      }
      deductions.add(Deduction(
        techniqueId: id,
        tier: tier,
        kind: DeductionKind.assertion,
        highlightedCells: unknowns.map(state.refOf).toList(growable: false),
        affectedCells: unknowns.map(state.refOf).toList(growable: false),
        explanationArgs: <String, Object>{
          'unitKind': unit.kind.name,
          'unitIndex': unit.displayIndex,
          'remaining': remaining,
        },
      ));
    }
    return deductions;
  }
}
