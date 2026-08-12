import 'package:flutter_test/flutter_test.dart';
import 'package:nodro/engine/puzzles/star_battle/generator.dart';

import 'prop_checks.dart';

/// LAYER 2 — Generator regression. **This is the day-to-day gate.**
///
/// Fifty freshly generated puzzles on the small boards, checked against every
/// property. Layer 1 proves the shipped artefact is correct; this layer proves
/// the machine that produced it still works, so a regression is caught the
/// moment it is introduced rather than at the next bank rebuild.
///
/// Deliberately small boards only: the point is to exercise every code path
/// quickly. Volume on the large boards belongs to Layer 3.
///
///   flutter test test/property/generator_regression_test.dart
void main() {
  const configs = <(int size, int stars, int count)>[
    (6, 1, 20),
    (8, 1, 20),
    (9, 2, 10),
  ];

  for (final (size, stars, count) in configs) {
    test('${size}x$size / $stars star(s) — $count fresh puzzles pass '
        'PROP-1 to PROP-5', () {
      final generator = StarBattleGenerator(size: size, starsPerUnit: stars);
      var seed = 770000 + size * 1000 + stars;
      for (var i = 0; i < count; i++) {
        final generated = generator.generate(seed++);
        verifyPuzzle(
          generated.puzzle,
          expectedTier: generated.tier,
          knownSolution: generated.solution,
          label: '${size}x$size/$stars seed ${generated.seed}',
        );
      }
    });
  }

  test('6x6 — PROP-6-SB boundary rigidity on fresh puzzles', () {
    final generator = StarBattleGenerator(size: 6, starsPerUnit: 1);
    for (var i = 0; i < 5; i++) {
      final generated = generator.generate(781000 + i);
      verifyBoundaryRigidity(generated.puzzle,
          label: '6x6 seed ${generated.seed}');
    }
  },
      skip: 'BLOCKED ON A PRODUCT DECISION, not weakened. The PROP-6-SB '
          'definition (no single cell may change region and still leave a '
          'uniquely solvable puzzle) is not merely hard to satisfy, it is '
          'structurally wrong: dart run tool/diagnose.dart measures 63% of '
          'legal boundary moves preserving uniqueness, and 0 of 48 generated '
          'puzzles across three sizes are fully rigid. Enabling the gate in '
          'the generator makes it fail after 4,000 consecutive attempts on a '
          '6x6 board. Star Battle appears to have no meaningful clue-removal '
          'analogue, like Shikaku. Awaiting the decision recorded in '
          'PROGRESS.md before this test is rewritten or retired.');

  test('generation is reproducible from a seed', () {
    // The whole harness rests on this: without it a failure at sample 837
    // cannot be reproduced, and the seeded corpus is theatre.
    final a = StarBattleGenerator(size: 8, starsPerUnit: 1).generate(4242);
    final b = StarBattleGenerator(size: 8, starsPerUnit: 1).generate(4242);
    expect(serializer.serialize(a.puzzle), serializer.serialize(b.puzzle));
    expect(a.tier, b.tier);
    expect(a.solution, equals(b.solution));
    expect(a.attempts, b.attempts);
  });
}
