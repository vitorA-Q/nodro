import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodro/data/puzzle_bank.dart';
import 'package:nodro/data/puzzle_library.dart';
import 'package:nodro/engine/core/technique_tier.dart';
import 'package:nodro/engine/puzzles/star_battle/exhaustive_solver.dart';
import 'package:nodro/engine/puzzles/star_battle/serializer.dart';
import 'package:nodro/l10n/app_localizations.dart';
import 'package:nodro/ui/game/game_session.dart';
import 'package:nodro/ui/screens/won_sheet.dart';
import 'package:nodro/ui/theme/difficulty.dart';

/// The shared result must be tempting to post and useless as a cheat sheet.
///
/// If a shared message let a reader reconstruct the answer, the daily challenge
/// would be destroyed for everyone in the thread — by the one feature meant to
/// spread it.
void main() {
  const serializer = StarBattleSerializer();
  const oracle = StarBattleExhaustiveSolver();

  late LibraryPuzzle puzzle;
  late String text;

  setUpAll(() async {
    final line = File('assets/bank/star_battle_6x6_1.txt')
        .readAsLinesSync()
        .firstWhere((line) => line.startsWith('2|'));
    puzzle = LibraryPuzzle(
      '6x6#0',
      PuzzleGroup(6, 1, Difficulty.medium),
      BankEntry(TechniqueTier.tier2,
          serializer.deserialize(line.substring(line.indexOf('|') + 1))),
      55,
    );

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final session = GameSession(puzzle: puzzle)
      ..elapsedSeconds = 209
      ..hintsUsed = 0;

    text = buildShareText(
      l10n: l10n,
      session: session,
      isDaily: false,
      streak: 0,
    );
  });

  test('it carries what a reader would want to see', () {
    expect(text, contains('Nodro'));
    expect(text, contains('#55'));
    expect(text, contains('6×6'));
    expect(text, contains('3:29'));
    expect(text, contains('Challenge'));
    expect(text, contains('nodro.app'));
  });

  test('it does NOT reveal the solution', () {
    final solution = oracle.findFirstSolution(puzzle.entry.puzzle)!;
    final size = puzzle.entry.puzzle.size;

    // 1. No cell coordinate appears anywhere.
    for (final index in solution.starIndices) {
      final row = index ~/ size + 1;
      final col = index % size + 1;
      expect(text, isNot(contains('r${row}c$col')),
          reason: 'a star position leaked into the share text');
    }

    // 2. The emoji block is a pace gauge, not a picture of the board: it must
    //    not have one row per board row, or its shape would be readable.
    final emojiLines = text
        .split('\n')
        .where((line) => line.contains('🟩') || line.contains('⬜'))
        .toList();
    expect(emojiLines.length, 1,
        reason: 'more than one emoji row starts to look like a grid; the bar '
            'must stay a single line');
    expect(emojiLines.single.runes.length, 10,
        reason: 'the bar is a fixed ten segments regardless of board size, so '
            'its length says nothing about the puzzle');

    // 3. The region layout, which IS the clue, never appears.
    expect(text, isNot(contains(serializer.serialize(puzzle.entry.puzzle))));
  });

  test('the pace bar reflects speed without exposing the board', () {
    Future<String> textForSeconds(int seconds) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      final session = GameSession(puzzle: puzzle)..elapsedSeconds = seconds;
      return buildShareText(
          l10n: l10n, session: session, isDaily: false, streak: 0);
    }

    Future<int> filledFor(int seconds) async =>
        '🟩'.allMatches(await textForSeconds(seconds)).length;

    expectLater(filledFor(30), completion(greaterThan(0)));
    expectLater(
        Future.wait(<Future<int>>[filledFor(30), filledFor(2000)]),
        completion(predicate<List<int>>((values) => values[0] > values[1],
            'a faster solve fills more of the bar')));
  });

  test('the daily variant adds the streak and drops the puzzle number', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final session = GameSession(puzzle: puzzle)..elapsedSeconds = 100;
    final daily = buildShareText(
        l10n: l10n, session: session, isDaily: true, streak: 4);

    expect(daily, contains('🔥 4'));
    expect(daily, isNot(contains('#55')),
        reason: 'the daily is the same board for everyone, so its number adds '
            'nothing and only invites confusion');
  });
}
