// Phase performance numbers. Run with: dart run tool/bench.dart
//
// Deliberately a plain Dart script with no test framework: the numbers it
// prints are pasted into the phase report (C4), so it must be runnable and
// readable by itself.

import 'dart:io';

import 'package:nodro/engine/core/technique_tier.dart';
import 'package:nodro/engine/puzzles/star_battle/exhaustive_solver.dart';
import 'package:nodro/engine/puzzles/star_battle/generator.dart';
import 'package:nodro/engine/puzzles/star_battle/human_solver.dart';
import 'package:nodro/engine/puzzles/star_battle/model.dart';

class _Config {
  const _Config(this.size, this.stars, this.samples);
  final int size;
  final int stars;
  final int samples;
  String get label => '${size}x$size / $stars star(s)';
}

void main(List<String> args) {
  // The four shipped sizes (decision D6).
  const configs = <_Config>[
    _Config(6, 1, 60),
    _Config(8, 1, 60),
    _Config(9, 2, 40),
    _Config(10, 2, 40),
  ];

  stdout.writeln('NODRO benchmark — Star Battle engine');
  stdout.writeln('Dart ${Platform.version.split(' ').first}');
  stdout.writeln('');

  for (final config in configs) {
    _benchmarkGeneration(config);
  }

  _benchmarkOracle();
}

void _benchmarkGeneration(_Config config) {
  final generator =
      StarBattleGenerator(size: config.size, starsPerUnit: config.stars);

  final durations = <int>[];
  final attempts = <int>[];
  final tiers = <TechniqueTier, int>{};
  var failures = 0;

  for (var i = 0; i < config.samples; i++) {
    final stopwatch = Stopwatch()..start();
    try {
      final generated = generator.generate(1000 + i);
      stopwatch.stop();
      durations.add(stopwatch.elapsedMicroseconds);
      attempts.add(generated.attempts);
      tiers[generated.tier] = (tiers[generated.tier] ?? 0) + 1;
    } on StateError {
      stopwatch.stop();
      failures++;
    }
  }

  stdout.writeln('GENERATION  ${config.label}  (${config.samples} puzzles)');
  if (durations.isEmpty) {
    stdout.writeln('  FAILED for every seed');
    stdout.writeln('');
    return;
  }
  durations.sort();
  attempts.sort();
  stdout.writeln('  median   ${_ms(durations[durations.length ~/ 2])}');
  stdout.writeln('  p90      ${_ms(durations[(durations.length * 9) ~/ 10])}');
  stdout.writeln('  worst    ${_ms(durations.last)}');
  stdout.writeln('  attempts median ${attempts[attempts.length ~/ 2]}, '
      'worst ${attempts.last}');
  if (failures > 0) {
    stdout.writeln('  GAVE UP on $failures seed(s)');
  }
  final tierLine = (tiers.keys.toList()..sort((a, b) => a.level - b.level))
      .map((tier) => 'T${tier.level}:${tiers[tier]}')
      .join('  ');
  stdout.writeln('  difficulty spread  $tierLine');
  stdout.writeln('');
}

void _benchmarkOracle() {
  const oracle = StarBattleExhaustiveSolver();
  final solver = StarBattleHumanSolver();
  final generator = StarBattleGenerator(size: 10, starsPerUnit: 2);

  final puzzles = <StarBattlePuzzle>[];
  for (var i = 0; i < 20; i++) {
    puzzles.add(generator.generate(5000 + i).puzzle);
  }

  var stopwatch = Stopwatch()..start();
  for (final puzzle in puzzles) {
    oracle.countSolutions(puzzle);
  }
  stopwatch.stop();
  stdout.writeln('ORACLE      10x10 / 2 stars, uniqueness check');
  stdout.writeln('  mean     ${_ms(stopwatch.elapsedMicroseconds ~/ puzzles.length)}');

  stopwatch = Stopwatch()..start();
  for (final puzzle in puzzles) {
    solver.solve(puzzle);
  }
  stopwatch.stop();
  stdout.writeln('HUMAN SOLVER 10x10 / 2 stars, full solve');
  stdout.writeln('  mean     ${_ms(stopwatch.elapsedMicroseconds ~/ puzzles.length)}');
  stdout.writeln('');
}

String _ms(int microseconds) =>
    '${(microseconds / 1000).toStringAsFixed(1)} ms';
