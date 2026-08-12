import 'package:flutter_test/flutter_test.dart';
import 'package:nodro/engine/core/technique_tier.dart';
import 'package:nodro/engine/puzzles/star_battle/generator.dart';
import 'package:nodro/engine/puzzles/star_battle/human_solver.dart';

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

  // PROP-6 has no Star Battle analogue and is deliberately not tested here.
  // See the note at the top of prop_checks.dart for the measurement that
  // settled it. The test below is what replaces it.

  test('PROP-3 two-sided actually bites — the label is earned, not decorative',
      () {
    // The whole value of the two-sided rating is that it REJECTS. If every
    // puzzle also solved one tier lower, the labels would be noise and this
    // check would be passing vacuously. So assert both directions explicitly:
    // the harder tier solves, the easier tier fails, and the corpus genuinely
    // contains puzzles above tier 1.
    final solver = StarBattleHumanSolver();
    final generator = StarBattleGenerator(size: 8, starsPerUnit: 1);

    var aboveTierOne = 0;
    for (var i = 0; i < 25; i++) {
      final generated = generator.generate(783000 + i);
      final tier = generated.tier;

      expect(solver.solve(generated.puzzle, maxTier: tier).isSolved, isTrue,
          reason: 'seed ${generated.seed}: does not solve at its own tier');

      if (tier.level > 1) {
        aboveTierOne++;
        final easier = TechniqueTier.fromLevel(tier.level - 1);
        expect(solver.solve(generated.puzzle, maxTier: easier).isSolved, isFalse,
            reason: 'seed ${generated.seed}: labelled T${tier.level} but also '
                'solves at T${easier.level} — the label overstates it');
      }
    }

    expect(aboveTierOne, greaterThan(10),
        reason: 'only $aboveTierOne of 25 puzzles are above tier 1, so the '
            'lower-bound half of PROP-3 is barely exercised and the guarantee '
            'is close to vacuous');
  });

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
