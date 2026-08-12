import 'cell_ref.dart';
import 'technique_tier.dart';

/// What a deduction concludes about the cells it affects.
///
/// Deliberately generic across all puzzle types (R4): "place a star" and "mark
/// grass" in Star Battle, "edge on" and "edge off" in Slitherlink, "assign this
/// cell to that clue" and "discard this rectangle" in Shikaku all collapse to
/// these two. Keeping it here means adding the fifteenth puzzle type does not
/// touch `engine/core`.
enum DeductionKind {
  /// The affected cells are proven to hold the puzzle's positive mark.
  assertion,

  /// The affected cells are proven NOT to hold the positive mark.
  elimination,
}

/// One proven logical step, produced by exactly one [Technique].
///
/// This type is what makes P3 possible without hacks: a hint is not pasted
/// text, it is a real deduction that the UI renders. [highlightedCells] is the
/// evidence the player should look at; [affectedCells] is the conclusion;
/// [explanationArgs] is interpolated into the localised `.arb` string keyed by
/// [techniqueId], so no sentence is ever hardcoded (R6).
class Deduction {
  Deduction({
    required this.techniqueId,
    required this.tier,
    required this.kind,
    required List<CellRef> highlightedCells,
    required List<CellRef> affectedCells,
    Map<String, Object> explanationArgs = const <String, Object>{},
  })  : highlightedCells = List<CellRef>.unmodifiable(highlightedCells),
        affectedCells = List<CellRef>.unmodifiable(affectedCells),
        explanationArgs = Map<String, Object>.unmodifiable(explanationArgs);

  /// The i18n key of the technique that produced this step.
  final String techniqueId;

  /// The tier of that technique. Drives PROP-3 and the hint ordering.
  final TechniqueTier tier;

  /// Whether the affected cells are asserted or eliminated.
  final DeductionKind kind;

  /// The cells forming the *evidence* — what the hint asks the player to look at.
  final List<CellRef> highlightedCells;

  /// The cells this step draws a conclusion about.
  final List<CellRef> affectedCells;

  /// Values interpolated into the localised explanation string.
  final Map<String, Object> explanationArgs;

  @override
  String toString() =>
      '$techniqueId(T${tier.level}, ${kind.name}) -> $affectedCells';
}

/// A named human deduction rule.
///
/// One technique = one file = one class. [apply] returns every step the rule can
/// currently justify, or an empty list when the rule does not fire. A technique
/// must never guess: every returned [Deduction] has to be true in *every*
/// solution of the puzzle, which is exactly what PROP-4 verifies against the
/// known solution.
abstract class Technique<S> {
  /// Stable i18n key. Never a display string.
  String get id;

  /// Where this rule sits on the difficulty ladder.
  TechniqueTier get tier;

  /// Every step this rule can justify in [state]. Empty when it does not apply.
  List<Deduction> apply(S state);
}
