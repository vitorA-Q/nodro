import '../../engine/core/deduction.dart';
import '../../l10n/app_localizations.dart';

/// Turns a typed [Deduction] into the sentences the player reads.
///
/// Nothing here builds a string by hand: every word comes from an `.arb` file
/// (R6), interpolated with the arguments the technique itself reported. That is
/// what makes P3 work without special cases — a hint is a real deduction being
/// rendered, not prose written to look like one.
class HintText {
  const HintText(this.l10n);

  final AppLocalizations l10n;

  String unitWord(Object? kind) => switch (kind) {
        'row' => l10n.unitRow,
        'column' => l10n.unitColumn,
        _ => l10n.unitRegion,
      };

  String name(String techniqueId) => switch (techniqueId) {
        'sbAdjacencyElimination' => l10n.techName_sbAdjacencyElimination,
        'sbUnitCompletionElimination' =>
          l10n.techName_sbUnitCompletionElimination,
        'sbUnitForcedFill' => l10n.techName_sbUnitForcedFill,
        'sbSharedNeighbourElimination' =>
          l10n.techName_sbSharedNeighbourElimination,
        'sbRegionLineConfinement' => l10n.techName_sbRegionLineConfinement,
        'sbLineRegionConfinement' => l10n.techName_sbLineRegionConfinement,
        'sbCrowdingExclusion' => l10n.techName_sbCrowdingExclusion,
        'sbForwardElimination' => l10n.techName_sbForwardElimination,
        'sbRegionsWithinLines' => l10n.techName_sbRegionsWithinLines,
        _ => techniqueId,
      };

  String why(Deduction deduction) {
    final args = deduction.explanationArgs;
    int intArg(String key) => (args[key] as int?) ?? 0;
    String stringArg(String key) => (args[key] as String?) ?? '';

    return switch (deduction.techniqueId) {
      'sbAdjacencyElimination' => l10n.techWhy_sbAdjacencyElimination(
          stringArg('starCell'), intArg('count')),
      'sbUnitCompletionElimination' =>
        l10n.techWhy_sbUnitCompletionElimination(unitWord(args['unitKind']),
            intArg('unitIndex'), intArg('quota')),
      'sbUnitForcedFill' => l10n.techWhy_sbUnitForcedFill(
          unitWord(args['unitKind']), intArg('unitIndex'), intArg('remaining')),
      'sbSharedNeighbourElimination' => l10n
          .techWhy_sbSharedNeighbourElimination(unitWord(args['unitKind']),
              intArg('unitIndex'), intArg('candidateCount')),
      'sbRegionLineConfinement' => l10n.techWhy_sbRegionLineConfinement(
          intArg('regionIndex'),
          unitWord(args['lineKind']),
          intArg('lineIndex'),
          intArg('stars')),
      'sbLineRegionConfinement' => l10n.techWhy_sbLineRegionConfinement(
          unitWord(args['lineKind']),
          intArg('lineIndex'),
          intArg('regionIndex'),
          intArg('stars')),
      'sbCrowdingExclusion' => l10n.techWhy_sbCrowdingExclusion(
          unitWord(args['unitKind']), intArg('unitIndex'), intArg('remaining')),
      'sbForwardElimination' =>
        l10n.techWhy_sbForwardElimination(stringArg('cell')),
      'sbRegionsWithinLines' => l10n.techWhy_sbRegionsWithinLines(
          intArg('regionCount'),
          unitWord(args['lineKind']),
          stringArg('lineIndices'),
          intArg('stars')),
      _ => '',
    };
  }
}
