import 'package:flutter_test/flutter_test.dart';
import 'package:nodro/data/progress_repository.dart';
import 'package:nodro/engine/core/technique_tier.dart';
import 'package:nodro/ui/format.dart';
import 'package:nodro/ui/theme/challenge.dart';

/// The 1..10 axis that makes board sizes comparable, and the rule that keeps a
/// daily challenge daily.
void main() {
  group('global challenge', () {
    test('no 6x6 outranks a 9x9 of the same tier', () {
      // This is the confusion the number exists to answer: the four labels are
      // a convention WITHIN a size, so an Extreme 6x6 really is easier than a
      // Medium 9x9. The labels are not wrong, they are just silent about it.
      for (final tier in TechniqueTier.values) {
        final small = globalChallenge(size: 6, stars: 1, tier: tier);
        final large = globalChallenge(size: 9, stars: 2, tier: tier);
        expect(small, lessThan(large),
            reason: 'at tier ${tier.level}, 6x6 scored $small and 9x9 scored '
                '$large');
      }
    });

    test('the hardest small board still ranks below the easiest big one', () {
      final smallHardest =
          globalChallenge(size: 6, stars: 1, tier: TechniqueTier.tier4);
      final largeEasiest =
          globalChallenge(size: 9, stars: 2, tier: TechniqueTier.tier2);
      expect(smallHardest, lessThan(largeEasiest),
          reason: 'a 6x6 Extreme ($smallHardest) must read as easier than a '
              '9x9 Medium ($largeEasiest) — that is the whole complaint this '
              'axis answers');
    });

    test('it always lands inside 1..10', () {
      for (final size in <int>[6, 8, 9, 10, 14]) {
        for (final stars in <int>[1, 2, 3]) {
          for (final tier in TechniqueTier.values) {
            final value = globalChallenge(size: size, stars: stars, tier: tier);
            expect(value, inInclusiveRange(1, 10));
          }
        }
      }
    });

    test('it is deterministic', () {
      expect(globalChallenge(size: 9, stars: 2, tier: TechniqueTier.tier2),
          globalChallenge(size: 9, stars: 2, tier: TechniqueTier.tier2));
    });

    test('every axis only ever increases the number', () {
      const tier = TechniqueTier.tier2;
      expect(globalChallenge(size: 8, stars: 1, tier: tier),
          greaterThan(globalChallenge(size: 6, stars: 1, tier: tier)));
      expect(globalChallenge(size: 6, stars: 2, tier: tier),
          greaterThan(globalChallenge(size: 6, stars: 1, tier: tier)));
      expect(
          globalChallenge(size: 6, stars: 1, tier: TechniqueTier.tier4),
          greaterThan(
              globalChallenge(size: 6, stars: 1, tier: TechniqueTier.tier1)));
    });
  });

  group('daily challenge is daily', () {
    test('finishing twice on the same day changes nothing', () async {
      final progress = InMemoryProgressRepository();
      const today = '2026-08-13';

      await progress.recordDaily(
          today,
          const DailyResult(seconds: 200, hintsUsed: 0, puzzleId: 'a'));
      // A replay, and a much better one. It must be ignored.
      await progress.recordDaily(
          today,
          const DailyResult(seconds: 10, hintsUsed: 5, puzzleId: 'a'));

      final stored = progress.dailyResult(today)!;
      expect(stored.seconds, 200,
          reason: 'the first finish of the day is the one that counts, or the '
              'daily becomes a time trial you can grind');
      expect(stored.hintsUsed, 0);
      expect(progress.dailyCompletions().length, 1);
    });

    test('a replay cannot inflate the streak', () async {
      final progress = InMemoryProgressRepository();
      final today = DateTime(2026, 8, 13);

      for (var i = 0; i < 4; i++) {
        await progress.recordDaily(
            isoDate(today),
            const DailyResult(seconds: 100, hintsUsed: 0, puzzleId: 'a'));
      }
      expect(currentStreak(progress.dailyCompletions(), today), 1);
    });

    test('consecutive days build a streak, a gap breaks it', () async {
      final progress = InMemoryProgressRepository();
      final today = DateTime(2026, 8, 13);
      for (final offset in <int>[0, 1, 2]) {
        await progress.recordDaily(
            isoDate(today.subtract(Duration(days: offset))),
            const DailyResult(seconds: 100, hintsUsed: 0, puzzleId: 'a'));
      }
      expect(currentStreak(progress.dailyCompletions(), today), 3);

      // A day older than the gap must not be counted.
      await progress.recordDaily(
          isoDate(today.subtract(const Duration(days: 5))),
          const DailyResult(seconds: 100, hintsUsed: 0, puzzleId: 'a'));
      expect(currentStreak(progress.dailyCompletions(), today), 3);
    });

    test('the streak survives a day not yet played', () async {
      // At breakfast the streak should not look broken just because today's
      // puzzle is still waiting.
      final progress = InMemoryProgressRepository();
      final today = DateTime(2026, 8, 13);
      await progress.recordDaily(
          isoDate(today.subtract(const Duration(days: 1))),
          const DailyResult(seconds: 100, hintsUsed: 0, puzzleId: 'a'));
      expect(currentStreak(progress.dailyCompletions(), today), 1);
    });
  });
}
