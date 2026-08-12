import '../../../core/deduction.dart';
import '../../../core/technique_tier.dart';
import '../board.dart';

/// TIER 2 — Region Confined to a Line.
///
/// If every undetermined cell of a region sits in one row (or one column), the
/// region must place all its remaining stars in that line. When those stars use
/// up the line's entire remaining quota, every other undetermined cell of the
/// line is empty.
///
/// SOUNDNESS: the region's remaining true stars all sit among its surviving
/// candidates, which are contained in the line; the line needs a fixed number,
/// so the line's cells outside the region can hold at most
/// `lineRemaining - regionRemaining` stars. Cells are only eliminated when that
/// figure is zero, which is pure containment-plus-cardinality.
class RegionLineConfinement implements Technique<StarBattleBoard> {
  const RegionLineConfinement();

  @override
  String get id => 'sbRegionLineConfinement';

  @override
  TechniqueTier get tier => TechniqueTier.tier2;

  @override
  List<Deduction> apply(StarBattleBoard state) {
    final deductions = <Deduction>[];
    final size = state.size;

    for (final region in state.units) {
      if (region.kind != UnitKind.region) {
        continue;
      }
      final regionRemaining = state.remainingIn(region);
      if (regionRemaining < 1) {
        continue;
      }
      final candidates = state.unknownsIn(region);
      if (candidates.isEmpty) {
        continue;
      }

      for (final kind in <UnitKind>[UnitKind.row, UnitKind.column]) {
        final first = kind == UnitKind.row
            ? candidates.first ~/ size
            : candidates.first % size;
        final allSameLine = candidates.every((cell) =>
            (kind == UnitKind.row ? cell ~/ size : cell % size) == first);
        if (!allSameLine) {
          continue;
        }

        final line = state.units.firstWhere(
            (unit) => unit.kind == kind && unit.index == first);
        if (state.remainingIn(line) != regionRemaining) {
          continue; // the line keeps spare quota; nothing is forced yet
        }

        final affected = state
            .unknownsIn(line)
            .where((cell) => !candidates.contains(cell))
            .toList(growable: false);
        if (affected.isEmpty) {
          continue;
        }

        deductions.add(Deduction(
          techniqueId: id,
          tier: tier,
          kind: DeductionKind.elimination,
          highlightedCells:
              candidates.map(state.refOf).toList(growable: false),
          affectedCells: affected.map(state.refOf).toList(growable: false),
          explanationArgs: <String, Object>{
            'regionIndex': region.displayIndex,
            'lineKind': kind.name,
            'lineIndex': line.displayIndex,
            'stars': regionRemaining,
          },
        ));
      }
    }
    return deductions;
  }
}
