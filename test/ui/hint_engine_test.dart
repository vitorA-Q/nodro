import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nodro/engine/puzzles/star_battle/board.dart';
import 'package:nodro/engine/puzzles/star_battle/exhaustive_solver.dart';
import 'package:nodro/engine/puzzles/star_battle/model.dart';
import 'package:nodro/engine/puzzles/star_battle/serializer.dart';
import 'package:nodro/ui/game/hint_engine.dart';
import 'package:nodro/ui/game/play_grid.dart';

/// Invariant P3: a hint finds the simplest next valid deduction, names the
/// technique, points at the cells, and explains why.
///
/// The test that matters most is the soundness one: a hint must never assert
/// something the real solution contradicts. A wrong hint is worse than no hint,
/// because the player trusts it.
void main() {
  const serializer = StarBattleSerializer();
  const oracle = StarBattleExhaustiveSolver();

  StarBattlePuzzle loadPuzzle(String prefix) {
    final line = File('assets/bank/star_battle_6x6_1.txt')
        .readAsLinesSync()
        .firstWhere((line) => line.startsWith(prefix));
    return serializer.deserialize(line.substring(line.indexOf('|') + 1));
  }

  test('an empty board gets a real, named first step', () {
    final puzzle = loadPuzzle('2|');
    final hint = HintEngine(puzzle).hintFor(PlayGrid.empty(puzzle));

    expect(hint, isA<DeductionHint>());
    final deduction = (hint as DeductionHint).deduction;
    expect(deduction.techniqueId, isNotEmpty);
    expect(deduction.affectedCells, isNotEmpty,
        reason: 'a hint that concludes nothing is not a hint');
    expect(deduction.highlightedCells, isNotEmpty,
        reason: 'the player has to be told where to look');
  });

  test('hints never contradict the real solution, all the way to the end', () {
    // Walk a whole puzzle using nothing but hints and check every single
    // conclusion against the oracle. This is PROP-4 applied to the hint path.
    for (final prefix in <String>['1|', '2|', '3|']) {
      final puzzle = loadPuzzle(prefix);
      final engine = HintEngine(puzzle);
      final truth = oracle.findFirstSolution(puzzle)!.starIndices.toSet();

      var grid = PlayGrid.empty(puzzle);
      var steps = 0;
      while (!grid.isSolved && steps < 400) {
        final hint = engine.hintFor(grid);
        if (hint is! DeductionHint) {
          break;
        }
        for (final ref in hint.deduction.affectedCells) {
          final index = ref.toIndex(puzzle.size);
          final asserted = hint.deduction.kind.name == 'assertion';
          expect(truth.contains(index), asserted,
              reason: 'hint ${hint.deduction.techniqueId} was wrong about '
                  '$ref on puzzle $prefix');
        }
        grid = engine.apply(grid, hint.deduction);
        steps++;
      }

      expect(grid.isSolved, isTrue,
          reason: 'following hints alone must finish the puzzle — otherwise '
              'the hint engine strands the player it was meant to help');
    }
  });

  test('a wrong star is reported as a mistake instead of deduced upon', () {
    final puzzle = loadPuzzle('2|');
    final engine = HintEngine(puzzle);
    final truth = oracle.findFirstSolution(puzzle)!.starIndices.toSet();

    final wrongCell =
        List<int>.generate(36, (i) => i).firstWhere((i) => !truth.contains(i));
    final grid = PlayGrid.empty(puzzle).cycled(wrongCell);

    final hint = engine.hintFor(grid);
    expect(hint, isA<MistakeHint>(),
        reason: 'deducing on top of a broken board produces confident '
            'nonsense; the engine must refuse and point at the mistake');
    expect((hint as MistakeHint).wrongCells.single.toIndex(6), wrongCell);
  });

  test('a wrong cross is a mistake too', () {
    final puzzle = loadPuzzle('2|');
    final engine = HintEngine(puzzle);
    final truth = oracle.findFirstSolution(puzzle)!.starIndices.first;

    // Cycle twice: empty -> star -> cross, over a cell that really holds a star.
    final grid = PlayGrid.empty(puzzle).cycled(truth).cycled(truth);
    expect(grid.stateAt(truth), CellState.empty);

    expect(engine.hintFor(grid), isA<MistakeHint>());
  });

  test('a finished board reports nothing left to do', () {
    final puzzle = loadPuzzle('2|');
    final engine = HintEngine(puzzle);
    var grid = PlayGrid.empty(puzzle);
    for (final index in oracle.findFirstSolution(puzzle)!.starIndices) {
      grid = grid.withState(index, CellState.star);
    }
    expect(engine.hintFor(grid), isA<SolvedHint>());
  });

  test('hints get simpler-first: the earliest steps are the cheapest tiers', () {
    final puzzle = loadPuzzle('3|');
    final engine = HintEngine(puzzle);
    var grid = PlayGrid.empty(puzzle);

    final tiers = <int>[];
    for (var i = 0; i < 6 && !grid.isSolved; i++) {
      final hint = engine.hintFor(grid);
      if (hint is! DeductionHint) {
        break;
      }
      tiers.add(hint.deduction.tier.level);
      grid = engine.apply(grid, hint.deduction);
    }

    expect(tiers, isNotEmpty);
    expect(tiers.first, lessThanOrEqualTo(2),
        reason: 'P3 asks for the SIMPLEST next deduction. Opening with an '
            'advanced technique when a basic one applies teaches the wrong '
            'lesson, tiers were $tiers');
  });
}
