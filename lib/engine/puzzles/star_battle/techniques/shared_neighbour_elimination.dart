import '../../../core/deduction.dart';
import '../../../core/technique_tier.dart';
import '../board.dart';

/// TIER 2 — Nosy Neighbours / Shared Exclusion.
///
/// If a unit still needs at least one star, then at least one of its
/// undetermined cells holds one. Any cell outside that set which touches
/// *every* one of them therefore cannot be a star.
///
/// SOUNDNESS: whichever candidate actually carries the star in the true
/// solution, the target cell touches it, so a star there would violate the
/// no-touch rule in every valid solution.
///
/// The everyday case is a unit down to two candidates: their common neighbours
/// all die. It also fires on larger sets whenever they happen to be tightly
/// clustered.
class SharedNeighbourElimination implements Technique<StarBattleBoard> {
  const SharedNeighbourElimination();

  @override
  String get id => 'sbSharedNeighbourElimination';

  @override
  TechniqueTier get tier => TechniqueTier.tier2;

  @override
  List<Deduction> apply(StarBattleBoard state) {
    final deductions = <Deduction>[];
    for (final unit in state.units) {
      if (state.remainingIn(unit) < 1) {
        continue;
      }
      final candidates = state.unknownsIn(unit);
      // A single candidate is handled by unitForcedFill; scanning huge sets is
      // pointless because the intersection is empty long before that.
      if (candidates.length < 2 || candidates.length > 4) {
        continue;
      }

      Set<int>? shared;
      for (final candidate in candidates) {
        final neighbours = state.neighboursOf(candidate).toSet();
        if (shared == null) {
          shared = neighbours;
        } else {
          shared = shared.intersection(neighbours);
        }
        if (shared.isEmpty) {
          break;
        }
      }
      if (shared == null || shared.isEmpty) {
        continue;
      }

      final affected = shared
          .where((cell) => state.isUnknown(cell) && !candidates.contains(cell))
          .toList(growable: false)
        ..sort();
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
          'unitKind': unit.kind.name,
          'unitIndex': unit.displayIndex,
          'candidateCount': candidates.length,
        },
      ));
    }
    return deductions;
  }
}
