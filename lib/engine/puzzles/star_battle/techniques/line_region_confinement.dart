import '../../../core/deduction.dart';
import '../../../core/technique_tier.dart';
import '../board.dart';

/// TIER 2 — Line Confined to a Region. The dual of [RegionLineConfinement].
///
/// If every undetermined cell of a row or column lies inside a single region,
/// the line's remaining stars must come out of that region's quota. When they
/// consume it entirely, the region's cells outside the line are empty.
///
/// SOUNDNESS: the line's remaining true stars lie inside its candidates, which
/// are contained in the region, and the region's quota is fixed; so the
/// region's cells outside the line can hold at most
/// `regionRemaining - lineRemaining`, and elimination happens only at zero.
class LineRegionConfinement implements Technique<StarBattleBoard> {
  const LineRegionConfinement();

  @override
  String get id => 'sbLineRegionConfinement';

  @override
  TechniqueTier get tier => TechniqueTier.tier2;

  @override
  List<Deduction> apply(StarBattleBoard state) {
    final deductions = <Deduction>[];

    for (final line in state.units) {
      if (line.kind == UnitKind.region) {
        continue;
      }
      final lineRemaining = state.remainingIn(line);
      if (lineRemaining < 1) {
        continue;
      }
      final candidates = state.unknownsIn(line);
      if (candidates.isEmpty) {
        continue;
      }

      final firstRegion = state.puzzle.regionOfCell[candidates.first];
      final allSameRegion = candidates
          .every((cell) => state.puzzle.regionOfCell[cell] == firstRegion);
      if (!allSameRegion) {
        continue;
      }

      final region = state.units.firstWhere((unit) =>
          unit.kind == UnitKind.region && unit.index == firstRegion);
      if (state.remainingIn(region) != lineRemaining) {
        continue;
      }

      final affected = state
          .unknownsIn(region)
          .where((cell) => !candidates.contains(cell))
          .toList(growable: false);
      if (affected.isEmpty) {
        continue;
      }

      deductions.add(Deduction(
        techniqueId: id,
        tier: tier,
        kind: DeductionKind.elimination,
        highlightedCells: candidates.map(state.refOf).toList(growable: false),
        affectedCells: affected.map(state.refOf).toList(growable: false),
        explanationArgs: <String, Object>{
          'lineKind': line.kind.name,
          'lineIndex': line.displayIndex,
          'regionIndex': region.displayIndex,
          'stars': lineRemaining,
        },
      ));
    }
    return deductions;
  }
}
