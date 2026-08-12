import 'solve_result.dart';
import 'technique_tier.dart';

/// Produces puzzles from a reproducible seed.
///
/// [P] is the immutable puzzle definition (what the player is shown),
/// [S] is the solution.
///
/// A generator must never hand back a puzzle it has not proven unique — that
/// proof is the exhaustive solver's job, and skipping it is X2.
abstract class PuzzleGenerator<P, S> {
  /// Generates one puzzle. The same [seed] must yield the same puzzle on every
  /// platform, which is why the engine ships its own PRNG rather than using
  /// `dart:math`.
  GeneratedPuzzle<P, S> generate(int seed);
}

/// A generated puzzle together with everything the test harness needs to check
/// it without re-deriving anything.
class GeneratedPuzzle<P, S> {
  const GeneratedPuzzle({
    required this.puzzle,
    required this.solution,
    required this.seed,
    required this.tier,
    required this.attempts,
  });

  final P puzzle;

  /// The intended solution. Property tests cross-check every deduction against
  /// this, which is how PROP-4 catches an unsound technique.
  final S solution;

  final int seed;

  /// The difficulty tier established two-sidedly (decision D4).
  final TechniqueTier tier;

  /// How many candidate puzzles were rejected before this one passed. Purely
  /// diagnostic: a rising number means the human solver's coverage is the
  /// bottleneck, not the uniqueness check (risk E6).
  final int attempts;
}

/// The ORACLE: correct by construction, slow, never used at runtime for hints.
abstract class ExhaustiveSolver<P, S> {
  /// Counts solutions with early exit on the second one.
  SolutionCount countSolutions(P puzzle);

  /// Returns any one solution, or null if the puzzle is unsolvable.
  S? findFirstSolution(P puzzle);
}

/// The PRODUCT: applies named techniques in tier order and never guesses.
///
/// Validated *against* the [ExhaustiveSolver], never the reverse. If the two
/// disagree, this one is wrong until proven otherwise (C3).
abstract class HumanSolver<P, S> {
  /// The i18n keys of every technique this solver knows, ordered by tier.
  ///
  /// Ids rather than the techniques themselves: the working-board type each
  /// module's techniques operate on is module-private, and widening it to
  /// `Technique<Object>` here would put `Object` in a public API (R7).
  List<String> get techniqueIds;

  /// Solves using only techniques at or below [maxTier].
  SolveResult solve(P puzzle, {TechniqueTier maxTier});

  /// Establishes the difficulty two-sidedly: the tier `d` such that the puzzle
  /// solves with techniques up to `d` and **fails** with techniques up to
  /// `d - 1` (decision D4). Null when the puzzle is not human-solvable at all.
  TechniqueTier? rateDifficulty(P puzzle);
}

/// Checks a candidate solution against the rules of the genre.
abstract class RuleValidator<P, S> {
  /// Whether [solution] satisfies every rule of [puzzle].
  bool isValidSolution(P puzzle, S solution);

  /// Human-readable rule violations, for tests and debugging. Empty when valid.
  List<String> violations(P puzzle, S solution);
}

/// Round-trips a puzzle to a compact string.
///
/// PROP-5 requires `deserialize(serialize(x)) == x` for every puzzle state and
/// every progress state, so the format must be total, not best-effort.
abstract class PuzzleSerializer<P> {
  String serialize(P puzzle);
  P deserialize(String data);
}

/// The common interface every puzzle module implements.
///
/// R4: adding the fifteenth type must not require touching the previous
/// fourteen, so nothing here may know a genre-specific concept.
abstract class PuzzleType<P, S> {
  /// Stable identifier, also the i18n key root and the SEO URL segment.
  String get id;

  PuzzleGenerator<P, S> get generator;
  HumanSolver<P, S> get humanSolver;
  ExhaustiveSolver<P, S> get exhaustiveSolver;
  RuleValidator<P, S> get validator;
  PuzzleSerializer<P> get serializer;
}
