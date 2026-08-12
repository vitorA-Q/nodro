@Tags(<String>['nightly'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:nodro/engine/puzzles/star_battle/generator.dart';

import 'prop_checks.dart';

/// LAYER 3 — Nightly batch. Fresh generation in volume, on demand only.
///
/// Excluded from the default run by its `nightly` tag, because generating this
/// many large boards takes far longer than anyone will wait between edits.
/// Layers 1 and 2 are the gates; this layer is the wide net that catches rare
/// seeds neither of them happens to hit.
///
///   flutter test test/property/nightly_batch_test.dart --tags nightly
///   flutter test test/property/nightly_batch_test.dart --tags nightly \
///       --dart-define=NODRO_NIGHTLY_PER_SIZE=250
void main() {
  const perSize =
      int.fromEnvironment('NODRO_NIGHTLY_PER_SIZE', defaultValue: 60);

  const configs = <(int size, int stars)>[
    (6, 1),
    (8, 1),
    (9, 2),
    (10, 2),
  ];

  for (final (size, stars) in configs) {
    test('${size}x$size / $stars star(s) — $perSize fresh puzzles', () {
      final generator = StarBattleGenerator(size: size, starsPerUnit: stars);
      var seed = 900000 + size * 10000 + stars * 97;
      for (var i = 0; i < perSize; i++) {
        final generated = generator.generate(seed++);
        verifyPuzzle(
          generated.puzzle,
          expectedTier: generated.tier,
          knownSolution: generated.solution,
          label: '${size}x$size/$stars seed ${generated.seed}',
        );
      }
    }, timeout: const Timeout(Duration(hours: 4)));
  }
}
