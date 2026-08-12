// Engine diagnostics. Run with: dart run tool/diagnose.dart
//
// Answers questions that a pass/fail test cannot: not "did it break" but
// "how far off is it, and in which direction". Written because guessing which
// stage of a pipeline is the problem wastes far more time than measuring.

import 'dart:io';

import 'package:nodro/engine/core/solve_result.dart';
import 'package:nodro/engine/puzzles/star_battle/exhaustive_solver.dart';
import 'package:nodro/engine/puzzles/star_battle/generator.dart';
import 'package:nodro/engine/puzzles/star_battle/model.dart';
import 'package:nodro/engine/puzzles/star_battle/rules.dart';

const StarBattleExhaustiveSolver _oracle = StarBattleExhaustiveSolver();
const StarBattleValidator _validator = StarBattleValidator();

void main() {
  stdout.writeln('NODRO diagnostics');
  stdout.writeln('');
  _boundarySlack();
}

/// PROP-6-SB slack distribution.
///
/// For each generated puzzle, counts every LEGAL single-cell region change and
/// how many of those still leave a uniquely solvable puzzle. Full rigidity —
/// the property as currently written — means that second number is zero.
void _boundarySlack() {
  stdout.writeln('BOUNDARY SLACK (PROP-6-SB)');
  stdout.writeln('  legal  = single-cell region changes that keep a valid puzzle');
  stdout.writeln('  slack  = those that ALSO keep the solution unique');
  stdout.writeln('  rigid  = puzzles with zero slack');
  stdout.writeln('');

  for (final (size, stars, count) in <(int, int, int)>[
    (6, 1, 25),
    (8, 1, 15),
    (9, 2, 8),
  ]) {
    final generator = StarBattleGenerator(size: size, starsPerUnit: stars);
    var totalLegal = 0;
    var totalSlack = 0;
    var rigidPuzzles = 0;
    final slackPerPuzzle = <int>[];

    for (var i = 0; i < count; i++) {
      final generated = generator.generate(31000 + i);
      final owner = List<int>.from(generated.puzzle.regionOfCell);
      var legal = 0;
      var slack = 0;

      for (var cell = 0; cell < size * size; cell++) {
        final from = owner[cell];
        for (final to in _adjacentRegions(owner, cell, size)) {
          if (to == from) {
            continue;
          }
          final variant = List<int>.from(owner)..[cell] = to;
          final altered = StarBattlePuzzle(
            size: size,
            starsPerUnit: stars,
            regionOfCell: variant,
          );
          if (_validator.puzzleViolations(altered).isNotEmpty) {
            continue;
          }
          legal++;
          if (_oracle.countSolutions(altered) == SolutionCount.unique) {
            slack++;
          }
        }
      }

      totalLegal += legal;
      totalSlack += slack;
      slackPerPuzzle.add(slack);
      if (slack == 0) {
        rigidPuzzles++;
      }
    }

    slackPerPuzzle.sort();
    final median = slackPerPuzzle[slackPerPuzzle.length ~/ 2];
    stdout.writeln('${size}x$size / $stars star(s), $count puzzles');
    stdout.writeln('  legal moves per puzzle : '
        '${(totalLegal / count).toStringAsFixed(1)}');
    stdout.writeln('  slack moves per puzzle : '
        'median $median, min ${slackPerPuzzle.first}, '
        'max ${slackPerPuzzle.last}');
    stdout.writeln('  slack rate             : '
        '${(100 * totalSlack / totalLegal).toStringAsFixed(1)}%');
    stdout.writeln('  fully rigid puzzles    : $rigidPuzzles of $count');
    stdout.writeln('');
  }
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
