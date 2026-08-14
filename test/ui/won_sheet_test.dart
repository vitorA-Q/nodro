import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nodro/data/puzzle_bank.dart';
import 'package:nodro/data/puzzle_library.dart';
import 'package:nodro/engine/core/technique_tier.dart';
import 'package:nodro/engine/puzzles/star_battle/serializer.dart';
import 'package:nodro/l10n/app_localizations.dart';
import 'package:nodro/ui/game/game_session.dart';
import 'package:nodro/ui/screens/won_sheet.dart';
import 'package:nodro/ui/theme/difficulty.dart';
import 'package:nodro/ui/theme/nodro_theme.dart';

/// The completion sheet, and the one thing it must never say.
void main() {
  const serializer = StarBattleSerializer();

  LibraryPuzzle loadPuzzle() {
    final line = File('assets/bank/star_battle_6x6_1.txt')
        .readAsLinesSync()
        .firstWhere((line) => line.startsWith('2|'));
    return LibraryPuzzle(
      '6x6#0',
      PuzzleGroup(6, 1, Difficulty.medium),
      BankEntry(TechniqueTier.tier2,
          serializer.deserialize(line.substring(line.indexOf('|') + 1))),
      55,
    );
  }

  Future<void> showSheet(WidgetTester tester, GameSession session,
      {bool isDaily = false}) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildNodroTheme(Brightness.light),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showWonSheet(
                context: context,
                session: session,
                isNewBest: false,
                isDaily: isDaily,
                streak: 0,
                onNext: () {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('a normal win shows the time', (tester) async {
    final session = GameSession(puzzle: loadPuzzle())..elapsedSeconds = 209;
    await showSheet(tester, session);

    expect(find.text('3:29'), findsOneWidget);
  });

  testWidgets('practice NEVER reports a time', (tester) async {
    // Replaying a finished daily runs without a clock on purpose, so
    // elapsedSeconds stays at zero. Printing it read as "solved in 0 seconds",
    // an impossible result the player never achieved.
    final session = GameSession(puzzle: loadPuzzle(), isPractice: true);
    await showSheet(tester, session, isDaily: true);

    expect(find.text('0:00'), findsNothing,
        reason: 'a practice run has no time, and 0:00 claims an impossibly '
            'fast solve');
    expect(find.textContaining('Practice'), findsOneWidget,
        reason: 'it should say plainly that this run was not scored');
  });

  testWidgets('practice offers no share and no next puzzle', (tester) async {
    final session = GameSession(puzzle: loadPuzzle(), isPractice: true);
    await showSheet(tester, session, isDaily: true);

    expect(find.text('Share'), findsNothing,
        reason: 'sharing a practice run would report a result that was never '
            'earned');
    expect(find.text('Next puzzle'), findsNothing,
        reason: 'the daily is one per day; practice does not unlock another');
  });

  testWidgets('a finished daily offers share but not another puzzle',
      (tester) async {
    final session = GameSession(puzzle: loadPuzzle())..elapsedSeconds = 120;
    await showSheet(tester, session, isDaily: true);

    expect(find.text('Share'), findsOneWidget);
    expect(find.text('Next puzzle'), findsNothing);
  });

  testWidgets('a normal win offers the next puzzle', (tester) async {
    final session = GameSession(puzzle: loadPuzzle())..elapsedSeconds = 120;
    await showSheet(tester, session);

    expect(find.text('Next puzzle'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
  });
}
