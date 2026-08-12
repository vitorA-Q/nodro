// Pre-generated puzzle bank builder.
//
//   dart run tool/generate_bank.dart              build with default budget
//   dart run tool/generate_bank.dart --budget-kb 3072
//
// Decision D2: the player must never wait for generation. The bank is built
// here, once, on a developer machine, and shipped as an asset. That is why this
// script is allowed to use isolates freely — it never runs in the browser.
//
// Every puzzle written here has already passed the exhaustive oracle (exactly
// one solution) and the human solver (no guessing), inside the generator. The
// release gate re-verifies the whole file independently — see
// test/property/bank_verification_test.dart.

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:nodro/engine/puzzles/star_battle/generator.dart';
import 'package:nodro/engine/puzzles/star_battle/serializer.dart';

/// The four shipped configurations (decision D6).
const List<(int size, int stars)> _configs = <(int, int)>[
  (6, 1),
  (8, 1),
  (9, 2),
  (10, 2),
];

/// Seeds handed to one isolate at a time.
///
/// Kept small because the wall-time limit can only be checked *between* rounds:
/// once a round is dispatched it must finish. With eight seeds per isolate a
/// single 10x10 round ran past the whole time budget before the limit could
/// bite. Two keeps rounds short enough for the cap to mean something, at the
/// cost of slightly more isolate spawns — which are cheap next to a 10x10
/// generation.
const int _seedsPerChunk = 2;

Future<void> main(List<String> args) async {
  final budgetKb = _intArg(args, '--budget-kb') ?? 3072;
  // The 3 MB cap is a ceiling, not a target. What actually limits the batch is
  // wall time: a 10x10 two-star puzzle costs about a thousand times a 6x6 one,
  // so the small boards hit the size cap in seconds while the large ones would
  // run for days trying to. Both limits are enforced, whichever comes first.
  final maxMinutes = _intArg(args, '--max-minutes') ?? 45;
  // Without a count cap the cheap boards would eat their whole byte budget:
  // a 6x6 puzzle is small and fast, so 768 KB of them is roughly 64,000 — far
  // more than any player needs, and wildly out of balance with the large boards
  // the same budget only buys a few hundred of.
  final maxPerSize = _intArg(args, '--max-per-size') ?? 1500;
  final cores = Platform.numberOfProcessors;
  final perConfigBudgetBytes = (budgetKb * 1024) ~/ _configs.length;

  stdout.writeln('NODRO bank builder');
  stdout.writeln('cores available : $cores');
  stdout.writeln('total budget    : $budgetKb KB gzipped');
  stdout.writeln('per size budget : ${perConfigBudgetBytes ~/ 1024} KB gzipped');
  stdout.writeln('per size time   : $maxMinutes min');
  stdout.writeln('');

  final outputDir = Directory('assets/bank');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  final overallStopwatch = Stopwatch()..start();
  var grandTotal = 0;
  var grandGzip = 0;

  for (final (size, stars) in _configs) {
    final stopwatch = Stopwatch()..start();
    final entries = await _buildConfig(
      size: size,
      stars: stars,
      cores: cores,
      gzipBudgetBytes: perConfigBudgetBytes,
      timeLimit: Duration(minutes: maxMinutes),
      maxPuzzles: maxPerSize,
    );
    stopwatch.stop();

    final path = 'assets/bank/star_battle_${size}x${size}_$stars.txt';
    final body = entries.join('\n');
    File(path).writeAsStringSync(body);

    final rawBytes = utf8.encode(body).length;
    final gzipBytes = gzip.encode(utf8.encode(body)).length;
    grandTotal += entries.length;
    grandGzip += gzipBytes;

    stdout.writeln('${size}x$size / $stars star(s)');
    stdout.writeln('  puzzles   ${entries.length}');
    stdout.writeln('  raw       ${(rawBytes / 1024).toStringAsFixed(1)} KB');
    stdout.writeln('  gzipped   ${(gzipBytes / 1024).toStringAsFixed(1)} KB');
    stdout.writeln('  wall time ${_duration(stopwatch.elapsed)}');
    stdout.writeln('  tiers     ${_tierSpread(entries)}');
    stdout.writeln('');
  }

  overallStopwatch.stop();
  stdout.writeln('TOTAL');
  stdout.writeln('  puzzles   $grandTotal');
  stdout.writeln('  gzipped   ${(grandGzip / 1024).toStringAsFixed(1)} KB '
      'of $budgetKb KB budget');
  stdout.writeln('  wall time ${_duration(overallStopwatch.elapsed)}');
}

/// Generates one configuration, keeping [cores] isolates busy at once.
///
/// Stops as soon as the gzipped size of what has been collected reaches the
/// budget, so the 3 MB cap is enforced against the number that actually matters
/// — what the browser downloads — rather than against a puzzle count guess.
Future<List<String>> _buildConfig({
  required int size,
  required int stars,
  required int cores,
  required int gzipBudgetBytes,
  required Duration timeLimit,
  required int maxPuzzles,
}) async {
  final collected = <String>[];
  var nextSeed = size * 1000003 + stars * 101;
  var done = false;
  final clock = Stopwatch()..start();

  while (!done) {
    final jobs = <Future<List<String>>>[];
    for (var worker = 0; worker < cores; worker++) {
      final start = nextSeed;
      nextSeed += _seedsPerChunk;
      jobs.add(Isolate.run(
          () => _generateChunk(size, stars, start, _seedsPerChunk)));
    }

    for (final result in await Future.wait(jobs)) {
      collected.addAll(result);
    }

    final gzipBytes = gzip.encode(utf8.encode(collected.join('\n'))).length;
    if (gzipBytes >= gzipBudgetBytes) {
      done = true;
      // Trim back under the budget rather than over it.
      while (collected.isNotEmpty &&
          gzip.encode(utf8.encode(collected.join('\n'))).length >
              gzipBudgetBytes) {
        collected.removeLast();
      }
    } else if (collected.length >= maxPuzzles) {
      done = true;
      while (collected.length > maxPuzzles) {
        collected.removeLast();
      }
    } else if (clock.elapsed >= timeLimit) {
      done = true;
      stdout.write('\r  ${size}x$size: time limit reached          \n');
    }
    stdout.write('\r  ${size}x$size: ${collected.length} puzzles...   ');
  }
  stdout.write('\r                                        \r');
  return collected;
}

/// Runs inside an isolate. Must be a top-level function with sendable arguments.
List<String> _generateChunk(int size, int stars, int seedStart, int count) {
  const serializer = StarBattleSerializer();
  final generator = StarBattleGenerator(size: size, starsPerUnit: stars);
  final lines = <String>[];
  for (var i = 0; i < count; i++) {
    try {
      final generated = generator.generate(seedStart + i);
      lines.add('${generated.tier.level}|${serializer.serialize(generated.puzzle)}');
    } on StateError {
      // The generator refused to certify this seed. Skipping is correct: an
      // uncertified puzzle must never reach the bank (X2).
    }
  }
  return lines;
}

String _tierSpread(List<String> entries) {
  final counts = <int, int>{};
  for (final entry in entries) {
    final tier = int.parse(entry.substring(0, entry.indexOf('|')));
    counts[tier] = (counts[tier] ?? 0) + 1;
  }
  final tiers = counts.keys.toList()..sort();
  return tiers.map((tier) => 'T$tier:${counts[tier]}').join('  ');
}

String _duration(Duration d) {
  final minutes = d.inMinutes;
  final seconds = d.inSeconds % 60;
  return minutes > 0 ? '${minutes}m ${seconds}s' : '${seconds}s';
}

int? _intArg(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index < 0 || index + 1 >= args.length) {
    return null;
  }
  return int.tryParse(args[index + 1]);
}
