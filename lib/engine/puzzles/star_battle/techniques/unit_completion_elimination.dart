import '../../../core/deduction.dart';
import '../../../core/technique_tier.dart';
import '../board.dart';

/// TIER 1 — Saturated Unit Elimination.
///
/// Once a row, column or region already holds its full quota of stars, every
/// remaining undetermined cell in it is empty.
///
/// SOUNDNESS: the unit contains exactly `k` stars in the true solution, and `k`
/// true stars are already identified inside it, so any further star there would
/// give `k + 1`.
class UnitCompletionElimination implements Technique<StarBattleBoard> {
  const UnitCompletionElimination();

  @override
  String get id => 'sbUnitCompletionElimination';

  @override
  TechniqueTier get tier => TechniqueTier.tier1;

  @override
  List<Deduction> apply(StarBattleBoard state) {
    final deductions = <Deduction>[];
    for (final unit in state.units) {
      final stars = state.starsIn(unit);
      if (stars.length != state.starsPerUnit) {
        continue;
      }
      final affected = state.unknownsIn(unit);
      if (affected.isEmpty) {
        continue;
      }
      deductions.add(Deduction(
        techniqueId: id,
        tier: tier,
        kind: DeductionKind.elimination,
        highlightedCells:
            stars.map(state.refOf).toList(growable: false),
        affectedCells: affected.map(state.refOf).toList(growable: false),
        explanationArgs: <String, Object>{
          'unitKind': unit.kind.name,
          'unitIndex': unit.displayIndex,
          'quota': state.starsPerUnit,
        },
      ));
    }
    return deductions;
  }
}
