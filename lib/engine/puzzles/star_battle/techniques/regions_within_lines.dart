import '../../../core/deduction.dart';
import '../../../core/technique_tier.dart';
import '../board.dart';

/// TIER 4 — N Regions in N Lines (also called Undercounting).
///
/// If `n` regions have all their surviving candidates inside a set of `n` rows
/// (or `n` columns), those regions supply exactly as many stars as the lines
/// demand, so every cell of those lines lying outside those regions is empty.
///
/// SOUNDNESS: containment plus equal cardinality forces the two star sets to
/// coincide. The lines' remaining stars are exactly the regions' remaining
/// stars, leaving zero available for line cells outside the regions — so no
/// eliminated cell could have been a true star.
///
/// Uses **remaining** quotas rather than nominal ones, which is what keeps the
/// rule valid on a partially solved board.
class RegionsWithinLines implements Technique<StarBattleBoard> {
  const RegionsWithinLines();

  /// Subsets larger than this are not enumerated. Beyond 3 the rule fires
  /// vanishingly rarely while the subset count grows fast, and a human does not
  /// spot them either.
  static const int maxSubsetSize = 3;

  @override
  String get id => 'sbRegionsWithinLines';

  @override
  TechniqueTier get tier => TechniqueTier.tier4;

  @override
  List<Deduction> apply(StarBattleBoard state) {
    final deductions = <Deduction>[];
    for (final kind in <UnitKind>[UnitKind.row, UnitKind.column]) {
      deductions.addAll(_scan(state, kind));
    }
    return deductions;
  }

  List<Deduction> _scan(StarBattleBoard state, UnitKind lineKind) {
    final size = state.size;
    final deductions = <Deduction>[];

    // Regions that still owe stars, with the set of lines they can reach.
    final activeRegions = <BoardUnit>[];
    final linesOf = <int, Set<int>>{};
    for (final unit in state.units) {
      if (unit.kind != UnitKind.region || state.remainingIn(unit) < 1) {
        continue;
      }
      final candidates = state.unknownsIn(unit);
      if (candidates.isEmpty) {
        continue;
      }
      final lines = candidates
          .map((cell) => lineKind == UnitKind.row ? cell ~/ size : cell % size)
          .toSet();
      if (lines.length > maxSubsetSize) {
        continue;
      }
      activeRegions.add(unit);
      linesOf[unit.index] = lines;
    }

    for (var subsetSize = 2; subsetSize <= maxSubsetSize; subsetSize++) {
      _forEachSubset(activeRegions, subsetSize, (subset) {
        final coveredLines = <int>{};
        var starsOwed = 0;
        for (final region in subset) {
          coveredLines.addAll(linesOf[region.index]!);
          starsOwed += state.remainingIn(region);
        }
        if (coveredLines.length != subsetSize) {
          return;
        }

        var lineDemand = 0;
        final lineUnits = <BoardUnit>[];
        for (final lineIndex in coveredLines) {
          final line = state.units.firstWhere(
              (unit) => unit.kind == lineKind && unit.index == lineIndex);
          lineUnits.add(line);
          lineDemand += state.remainingIn(line);
        }
        if (lineDemand != starsOwed) {
          return;
        }

        final regionIndices = subset.map((region) => region.index).toSet();
        final affected = <int>[];
        for (final line in lineUnits) {
          for (final cell in state.unknownsIn(line)) {
            if (!regionIndices.contains(state.puzzle.regionOfCell[cell])) {
              affected.add(cell);
            }
          }
        }
        if (affected.isEmpty) {
          return;
        }

        final highlighted = <int>[];
        for (final region in subset) {
          highlighted.addAll(state.unknownsIn(region));
        }

        deductions.add(Deduction(
          techniqueId: id,
          tier: tier,
          kind: DeductionKind.elimination,
          highlightedCells:
              highlighted.map(state.refOf).toList(growable: false),
          affectedCells: affected.map(state.refOf).toList(growable: false),
          explanationArgs: <String, Object>{
            'regionCount': subsetSize,
            'lineKind': lineKind.name,
            'lineIndices':
                (coveredLines.toList()..sort()).map((i) => i + 1).join(', '),
            'stars': starsOwed,
          },
        ));
      });
    }
    return deductions;
  }

  static void _forEachSubset(
    List<BoardUnit> items,
    int size,
    void Function(List<BoardUnit> subset) visit,
  ) {
    if (items.length < size) {
      return;
    }
    final indices = List<int>.generate(size, (i) => i);
    while (true) {
      visit(indices.map((i) => items[i]).toList(growable: false));
      var position = size - 1;
      while (position >= 0 && indices[position] == items.length - size + position) {
        position--;
      }
      if (position < 0) {
        return;
      }
      indices[position]++;
      for (var next = position + 1; next < size; next++) {
        indices[next] = indices[next - 1] + 1;
      }
    }
  }
}
