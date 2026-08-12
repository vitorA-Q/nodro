import 'package:flutter_test/flutter_test.dart';
import 'package:nodro/engine/core/deduction.dart';
import 'package:nodro/engine/core/solve_result.dart';
import 'package:nodro/engine/core/technique_tier.dart';
import 'package:nodro/engine/puzzles/star_battle/board.dart';
import 'package:nodro/engine/puzzles/star_battle/exhaustive_solver.dart';
import 'package:nodro/engine/puzzles/star_battle/human_solver.dart';
import 'package:nodro/engine/puzzles/star_battle/model.dart';
import 'package:nodro/engine/puzzles/star_battle/rules.dart';
import 'package:nodro/engine/puzzles/star_battle/serializer.dart';

/// PROP-1 .. PROP-6 as reusable checks.
///
/// Shared by all three test layers so that a puzzle from the shipped bank and a
/// puzzle generated seconds ago are held to exactly the same standard. If these
/// ever diverge, one of the layers is quietly weaker than it looks.
///
/// ## PROP-6 is NOT APPLICABLE to Star Battle — decided, not deferred
///
/// There is no minimality check here and there should not be one. Star Battle
/// has no removable clues: the region partition IS the clue. The proposed
/// substitute (no single cell may change region and still leave a uniquely
/// solvable puzzle) was implemented and measured: 62.6% / 63.6% / 71.7% of legal
/// boundary moves preserve uniqueness on 6x6 / 8x8 / 9x9, and 0 of 48 puzzles
/// were rigid. A cell far from any star carries no information, so moving it
/// changes no deduction. Same conclusion the research reached for Shikaku.
///
/// **The two-sided PROP-3 below is the official guard against a flabby puzzle**
/// (decision D4). Reproduce the measurement with `dart run tool/diagnose.dart`.
const StarBattleExhaustiveSolver oracle = StarBattleExhaustiveSolver();
const StarBattleValidator validator = StarBattleValidator();
const StarBattleSerializer serializer = StarBattleSerializer();

/// Runs every property against one puzzle.
///
/// [expectedTier] is the label the puzzle claims. [knownSolution] may be null,
/// in which case the oracle supplies the truth — which is the right source
/// anyway, since PROP-4 must be checked against something independent of the
/// generator.
void verifyPuzzle(
  StarBattlePuzzle puzzle, {
  required TechniqueTier expectedTier,
  required String label,
  StarBattleSolution? knownSolution,
}) {
  // ---------------------------------------------------------------- PROP-1
  expect(oracle.countSolutions(puzzle), SolutionCount.unique,
      reason: 'PROP-1 [$label]: puzzle does not have exactly one solution');

  final truthSolution = oracle.findFirstSolution(puzzle);
  expect(truthSolution, isNotNull,
      reason: 'PROP-1 [$label]: oracle found no solution at all');
  final truth = truthSolution!;

  if (knownSolution != null) {
    expect(truth, equals(knownSolution),
        reason: 'PROP-1 [$label]: oracle and generator disagree on the solution');
  }

  final ruleProblems = validator.violations(puzzle, truth);
  expect(ruleProblems, isEmpty,
      reason: 'PROP-1 [$label]: solution breaks the rules — '
          '${ruleProblems.join('; ')}');

  final structureProblems = validator.puzzleViolations(puzzle);
  expect(structureProblems, isEmpty,
      reason: 'PROP-1 [$label]: malformed regions — '
          '${structureProblems.join('; ')}');

  // ---------------------------------------------------------------- PROP-2
  final solver = StarBattleHumanSolver();
  final board = StarBattleBoard(puzzle);
  final result = solver.solveBoard(board);
  expect(result.outcome, SolveOutcome.solved,
      reason: 'PROP-2 [$label]: human solver ended ${result.outcome.name} '
          'after ${result.steps.length} steps — the puzzle needs guessing');
  expect(board.toSolution(), equals(truth),
      reason: 'PROP-2 [$label]: human solver reached a different grid than '
          'the oracle');

  // ---------------------------------------------------------------- PROP-4
  // Checked before PROP-3 because an unsound technique would also corrupt the
  // difficulty rating, and the soundness failure is the more useful message.
  final truthStars = truth.starIndices.toSet();
  for (final step in result.steps) {
    for (final ref in step.affectedCells) {
      final index = ref.toIndex(puzzle.size);
      final isTrueStar = truthStars.contains(index);
      if (step.kind == DeductionKind.assertion) {
        expect(isTrueStar, isTrue,
            reason: 'PROP-4 UNSOUND [$label]: ${step.techniqueId} '
                '(T${step.tier.level}) placed a star at $ref, which is empty '
                'in the true solution');
      } else {
        expect(isTrueStar, isFalse,
            reason: 'PROP-4 UNSOUND [$label]: ${step.techniqueId} '
                '(T${step.tier.level}) eliminated $ref, which HOLDS a star in '
                'the true solution');
      }
    }
  }

  // ---------------------------------------------------------------- PROP-3
  final rated = solver.rateDifficulty(puzzle);
  expect(rated, isNotNull, reason: 'PROP-3 [$label]: puzzle is unratable');
  expect(rated, expectedTier,
      reason: 'PROP-3 [$label]: stored tier T${expectedTier.level} but the '
          'solver rates it T${rated?.level}');
  if (rated!.level > 1) {
    final easier = TechniqueTier.fromLevel(rated.level - 1);
    expect(solver.solve(puzzle, maxTier: easier).isSolved, isFalse,
        reason: 'PROP-3 [$label]: labelled T${rated.level} but also solves '
            'with techniques up to T${easier.level}, so the label overstates '
            'the difficulty (decision D4 requires the two-sided test)');
  }

  // ---------------------------------------------------------------- PROP-5
  final text = serializer.serialize(puzzle);
  final restored = serializer.deserialize(text);
  expect(restored, equals(puzzle),
      reason: 'PROP-5 [$label]: puzzle did not survive the round trip');
  expect(serializer.serialize(restored), text,
      reason: 'PROP-5 [$label]: re-serialising produced different text');

  final partial = StarBattleBoard(puzzle);
  solver.solveBoard(partial, maxTier: TechniqueTier.tier1);
  final progressText = serializer.serializeBoard(partial);
  final progressBack = serializer.deserializeBoard(progressText);
  expect(serializer.serializeBoard(progressBack), progressText,
      reason: 'PROP-5 [$label]: progress did not survive the round trip');

  // PROP-6 — intentionally absent. See the class-level note above.
}
