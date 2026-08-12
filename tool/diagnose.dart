// Generation funnel diagnostic. Run with: dart run tool/diagnose.dart
//
// Answers one question: of N random attempts, how many survive each stage?
// Written because "generation failed" is not a diagnosis — the fix for "regions
// are malformed" and the fix for "uniqueness is rare" are completely different.

import 'dart:io';

import 'package:nodro/engine/core/deterministic_random.dart';
import 'package:nodro/engine/core/solve_result.dart';
import 'package:nodro/engine/puzzles/star_battle/exhaustive_solver.dart';
import 'package:nodro/engine/puzzles/star_battle/generator.dart';
import 'package:nodro/engine/puzzles/star_battle/human_solver.dart';
import 'package:nodro/engine/puzzles/star_battle/model.dart';
import 'package:nodro/engine/puzzles/star_battle/rules.dart';

void main() {
  for (final config in <List<int>>[
    <int>[6, 1],
    <int>[8, 1],
    <int>[9, 2],
    <int>[10, 2],
  ]) {
    _funnel(config[0], config[1], 300);
  }
}

void _funnel(int size, int stars, int attempts) {
  final probe = _GeneratorProbe(size: size, starsPerUnit: stars);
  const oracle = StarBattleExhaustiveSolver();
  const validator = StarBattleValidator();
  final human = StarBattleHumanSolver();

  var sampled = 0;
  var regionsBuilt = 0;
  var solutionValid = 0;
  var structureValid = 0;
  var none = 0;
  var unique = 0;
  var multiple = 0;
  var humanSolvable = 0;

  final rng = DeterministicRandom(42);

  for (var i = 0; i < attempts; i++) {
    final solution = probe.sampleSolution(rng);
    if (solution == null) {
      continue;
    }
    sampled++;

    final regions = probe.buildRegions(rng, solution);
    if (regions == null) {
      continue;
    }
    regionsBuilt++;

    final puzzle = StarBattlePuzzle(
      size: size,
      starsPerUnit: stars,
      regionOfCell: regions,
    );

    if (validator.isValidSolution(puzzle, solution)) {
      solutionValid++;
    } else {
      continue;
    }
    if (validator.puzzleViolations(puzzle).isEmpty) {
      structureValid++;
    } else {
      continue;
    }

    switch (oracle.countSolutions(puzzle)) {
      case SolutionCount.none:
        none++;
      case SolutionCount.unique:
        unique++;
        if (human.rateDifficulty(puzzle) != null) {
          humanSolvable++;
        }
      case SolutionCount.multiple:
        multiple++;
    }
  }

  stdout.writeln('FUNNEL ${size}x$size / $stars star(s), $attempts attempts');
  stdout.writeln('  star config sampled : $sampled');
  stdout.writeln('  regions built       : $regionsBuilt');
  stdout.writeln('  solution valid      : $solutionValid');
  stdout.writeln('  structure valid     : $structureValid');
  stdout.writeln('  oracle none         : $none');
  stdout.writeln('  oracle UNIQUE       : $unique');
  stdout.writeln('  oracle multiple     : $multiple');
  stdout.writeln('  human solvable      : $humanSolvable');
  stdout.writeln('');
}

/// Exposes the generator's private stages so the funnel can be measured without
/// weakening the real generator's API.
class _GeneratorProbe extends StarBattleGenerator {
  _GeneratorProbe({required super.size, required super.starsPerUnit});

  StarBattleSolution? sampleSolution(DeterministicRandom rng) =>
      sampleSolutionForDiagnostics(rng);

  List<int>? buildRegions(DeterministicRandom rng, StarBattleSolution solution) =>
      buildRegionsForDiagnostics(rng, solution);
}
