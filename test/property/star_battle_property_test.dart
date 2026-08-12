import 'package:nodro/engine/core/deduction.dart';
import 'package:nodro/engine/core/puzzle_type.dart';
import 'package:nodro/engine/core/solve_result.dart';
import 'package:nodro/engine/core/technique_tier.dart';
import 'package:nodro/engine/puzzles/star_battle/board.dart';
import 'package:nodro/engine/puzzles/star_battle/exhaustive_solver.dart';
import 'package:nodro/engine/puzzles/star_battle/generator.dart';
import 'package:nodro/engine/puzzles/star_battle/human_solver.dart';
import 'package:nodro/engine/puzzles/star_battle/model.dart';
import 'package:nodro/engine/puzzles/star_battle/rules.dart';
import 'package:nodro/engine/puzzles/star_battle/serializer.dart';
import 'package:flutter_test/flutter_test.dart';

/// PROP-1 .. PROP-6 for Star Battle.
///
/// Sample count follows decision D15: 150 in the day-to-day run, the full 1,000
/// before every delivery. Raise it with
///   flutter test --dart-define=NODRO_SAMPLES=1000
/// The seeds are fixed, so run N is always the same first N puzzles — a failure
/// at sample 837 is reproducible by re-running with the same count.
const int _sampleCount =
    int.fromEnvironment('NODRO_SAMPLES', defaultValue: 150);

/// The four shipped configurations (decision D6), weighted so the fast suite
/// stays usable. Larger boards cost far more to generate, and a suite nobody
/// runs protects nothing.
const List<_Config> _configs = <_Config>[
  _Config(6, 1, 0.40),
  _Config(8, 1, 0.35),
  _Config(9, 2, 0.15),
  _Config(10, 2, 0.10),
];

class _Config {
  const _Config(this.size, this.stars, this.share);
  final int size;
  final int stars;
  final double share;
  String get label => '${size}x$size/$stars';
}

const StarBattleExhaustiveSolver _oracle = StarBattleExhaustiveSolver();
const StarBattleValidator _validator = StarBattleValidator();
const StarBattleSerializer _serializer = StarBattleSerializer();

/// Generated once and shared by every property, because generation is by far
/// the most expensive step and every property needs the same corpus.
final List<GeneratedPuzzle<StarBattlePuzzle, StarBattleSolution>> _corpus =
    <GeneratedPuzzle<StarBattlePuzzle, StarBattleSolution>>[];

void main() {
  setUpAll(() {
    var seed = 20260812;
    for (final config in _configs) {
      final count = (_sampleCount * config.share).round();
      final generator =
          StarBattleGenerator(size: config.size, starsPerUnit: config.stars);
      for (var i = 0; i < count; i++) {
        _corpus.add(generator.generate(seed));
        seed += 1;
      }
    }
  });

  test('corpus was actually generated', () {
    expect(_corpus, isNotEmpty);
    // Guards against a silently empty corpus making every property vacuous.
    expect(_corpus.length, greaterThanOrEqualTo((_sampleCount * 0.9).floor()));
  });

  test('PROP-1 — every generated puzzle has exactly one solution', () {
    for (final generated in _corpus) {
      expect(_oracle.countSolutions(generated.puzzle), SolutionCount.unique,
          reason: 'seed ${generated.seed} (${generated.puzzle}) is not unique');
    }
  });

  test('PROP-1b — the intended solution is a legal solution of the puzzle', () {
    for (final generated in _corpus) {
      final problems =
          _validator.violations(generated.puzzle, generated.solution);
      expect(problems, isEmpty,
          reason: 'seed ${generated.seed}: ${problems.join('; ')}');
    }
  });

  test('PROP-1c — every region is non-empty and connected', () {
    for (final generated in _corpus) {
      final problems = _validator.puzzleViolations(generated.puzzle);
      expect(problems, isEmpty,
          reason: 'seed ${generated.seed}: ${problems.join('; ')}');
    }
  });

  test('PROP-2 — every puzzle is solvable by named techniques, no guessing', () {
    final solver = StarBattleHumanSolver();
    for (final generated in _corpus) {
      final result = solver.solve(generated.puzzle);
      expect(result.outcome, SolveOutcome.solved,
          reason: 'seed ${generated.seed} (${generated.puzzle}) ended '
              '${result.outcome.name} after ${result.steps.length} steps');
      expect(result.steps, isNotEmpty);
    }
  });

  test('PROP-2b — the human solver reaches the SAME solution as the oracle', () {
    final solver = StarBattleHumanSolver();
    for (final generated in _corpus) {
      final board = StarBattleBoard(generated.puzzle);
      final result = solver.solveBoard(board);
      expect(result.outcome, SolveOutcome.solved);
      expect(board.toSolution(), equals(generated.solution),
          reason: 'seed ${generated.seed}: human solver disagreed with the '
              'intended solution');
    }
  });

  test('PROP-3 — difficulty is the two-sided tier (decision D4)', () {
    final solver = StarBattleHumanSolver();
    for (final generated in _corpus) {
      final rated = solver.rateDifficulty(generated.puzzle);
      expect(rated, isNotNull, reason: 'seed ${generated.seed} is unratable');
      expect(rated, generated.tier,
          reason: 'seed ${generated.seed}: label and rating disagree');

      // The lower half of the two-sided test: one tier down must FAIL.
      if (rated!.level > 1) {
        final easier = TechniqueTier.fromLevel(rated.level - 1);
        expect(solver.solve(generated.puzzle, maxTier: easier).isSolved, isFalse,
            reason: 'seed ${generated.seed} is labelled T${rated.level} but '
                'also solves at T${easier.level}, so the label overstates it');
      }
    }
  });

  test('PROP-3b — rating is deterministic across repeated runs', () {
    final solver = StarBattleHumanSolver();
    for (final generated in _corpus.take(40)) {
      final first = solver.rateDifficulty(generated.puzzle);
      final second = solver.rateDifficulty(generated.puzzle);
      final third = StarBattleHumanSolver().rateDifficulty(generated.puzzle);
      expect(second, first);
      expect(third, first);
    }
  });

  test('PROP-4 — no technique ever contradicts the true solution', () {
    final solver = StarBattleHumanSolver();
    for (final generated in _corpus) {
      final truth = generated.solution.starIndices.toSet();
      final size = generated.puzzle.size;
      final result = solver.solve(generated.puzzle);

      for (final step in result.steps) {
        for (final ref in step.affectedCells) {
          final index = ref.toIndex(size);
          final isTrueStar = truth.contains(index);
          if (step.kind == DeductionKind.assertion) {
            expect(isTrueStar, isTrue,
                reason: 'UNSOUND: ${step.techniqueId} (T${step.tier.level}) '
                    'placed a star at $ref, which is empty in the true '
                    'solution. Seed ${generated.seed}.');
          } else {
            expect(isTrueStar, isFalse,
                reason: 'UNSOUND: ${step.techniqueId} (T${step.tier.level}) '
                    'eliminated $ref, which HOLDS a star in the true '
                    'solution. Seed ${generated.seed}.');
          }
        }
      }
    }
  });

  test('PROP-5 — puzzle serialisation round-trips exactly', () {
    for (final generated in _corpus) {
      final text = _serializer.serialize(generated.puzzle);
      final restored = _serializer.deserialize(text);
      expect(restored, equals(generated.puzzle),
          reason: 'seed ${generated.seed} did not survive the round trip');
      expect(_serializer.serialize(restored), text);
    }
  });

  test('PROP-5b — progress serialisation round-trips exactly', () {
    final solver = StarBattleHumanSolver();
    for (final generated in _corpus.take(60)) {
      // A half-solved board is the interesting case: fully empty and fully
      // solved boards would hide any bug in encoding the third cell state.
      final board = StarBattleBoard(generated.puzzle);
      solver.solveBoard(board, maxTier: TechniqueTier.tier1);

      final text = _serializer.serializeBoard(board);
      final restored = _serializer.deserializeBoard(text);
      expect(_serializer.serializeBoard(restored), text,
          reason: 'seed ${generated.seed} progress did not round-trip');
      expect(restored.puzzle, equals(generated.puzzle));
      for (var cell = 0; cell < board.size * board.size; cell++) {
        expect(restored.stateAt(cell), board.stateAt(cell));
      }
    }
  });

  test('PROP-6-SB — the region layout is locally rigid (decision D5)', () {
    // Star Battle has no removable clues: the region partition IS the clue.
    // The agreed substitute is boundary rigidity — no single cell may change
    // region and still leave a legal, uniquely solvable puzzle.
    var checked = 0;
    for (final generated in _corpus.take(25)) {
      final puzzle = generated.puzzle;
      final size = puzzle.size;
      final owner = List<int>.from(puzzle.regionOfCell);

      for (var cell = 0; cell < size * size; cell++) {
        final from = owner[cell];
        for (final to in _adjacentRegions(owner, cell, size)) {
          final variant = List<int>.from(owner);
          variant[cell] = to;
          final altered = StarBattlePuzzle(
            size: size,
            starsPerUnit: puzzle.starsPerUnit,
            regionOfCell: variant,
          );
          if (_validator.puzzleViolations(altered).isNotEmpty) {
            continue; // illegal layout: rigidity holds for this move
          }
          checked++;
          expect(_oracle.countSolutions(altered), isNot(SolutionCount.unique),
              reason: 'seed ${generated.seed}: moving cell '
                  '${puzzle.cellRefOf(cell)} from region ${from + 1} to '
                  'region ${to + 1} leaves another uniquely solvable puzzle, '
                  'so the layout carries slack');
        }
      }
    }
    expect(checked, greaterThan(0),
        reason: 'no boundary move was testable; the property is vacuous');
  });
}

List<int> _adjacentRegions(List<int> owner, int cell, int size) {
  final row = cell ~/ size;
  final col = cell % size;
  final result = <int>[];
  void consider(int r, int c) {
    if (r < 0 || r >= size || c < 0 || c >= size) {
      return;
    }
    final region = owner[r * size + c];
    if (region != owner[cell] && !result.contains(region)) {
      result.add(region);
    }
  }

  consider(row - 1, col);
  consider(row + 1, col);
  consider(row, col - 1);
  consider(row, col + 1);
  return result;
}
